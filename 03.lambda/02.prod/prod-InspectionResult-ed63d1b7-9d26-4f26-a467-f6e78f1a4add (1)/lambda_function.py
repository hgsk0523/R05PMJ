from aws_lambda_powertools import (
    Logger, 
    Tracer,
)
from aws_lambda_powertools.event_handler import APIGatewayRestResolver
from aws_lambda_powertools.event_handler.api_gateway import Response
from aws_lambda_powertools.logging import correlation_paths
from aws_lambda_powertools.utilities.typing import LambdaContext
from constant import (
    AnalysisType,
    ResultCode,
    Environment,
    Message,
    Progress,
)
from helper import (
    create_json_response,
    request_validation,
    api_exception_handler,
    S3,
    DateConverter,
)
from model import (
    DatabaseConnection,
    TInspectionRepository,
    TInspectionItemRepository,
    TInspectionItem,
    MInspectionItem,
)
from exception import RDSException
import textwrap

# -----------------------------
#  グローバル変数
# -----------------------------
tracer = Tracer()
"""
X-RayのTracerインスタンス
"""

logger = Logger()
"""
Loggerインスタンス
"""

conn = DatabaseConnection()
"""
DBの接続情報を管理するインスタンス
"""

s3_client = S3(logger)
"""
s3の接続情報を管理するインスタンス
"""

app = APIGatewayRestResolver()
"""
API Gatewayのペイロードリゾルバーインスタンス
"""

IF3011 = {
    '$schema': 'http://json-schema.org/draft-07/schema#',
    'title': 'validate_api-IF3011',
    'description': 'for IF3011 json validate',
    'type': 'object',
    'additionalProperties': False,
    'required': [
        'inspectionId',
        'status',
        'evidenceId',
    ],
    'properties' :{
        'inspectionId': {
            'type': 'integer',
        },
        'status': {
            'type': 'integer',
        },
        'evidenceId': {
            'type': 'integer',
        },
        'inspectionResultItems': {
            'type': 'array',
            'minItems': 0,
            'items': {
                'type': 'object',
                'additionalProperties': False,
                'required': [
                    'inspectionItemName'
                ],
                'properties': {
                    'inspectionItemId': {
                        'type': 'integer',
                    },
                    'inspectionItemName': {
                        'type': 'string',
                        'minLength': 0,
                        'maxLength': 16,
                    },
                    'takenDt': {
                        'type': ['string', 'null'],
                        'format': 'date-time',
                    },
                    'editedModel': {
                        'type': 'string',
                        'minLength': 0,
                        'maxLength': 20,
                    },
                    'editedSerialNumber': {
                        'type': 'string',
                        'minLength': 0,
                        'maxLength': 12,
                    },
                    'ngComment': {
                        'type': 'string',
                        'minLength': 0,
                        'maxLength': 50,
                    },
                    's3ImagePath': {
                        'type': 'string',
                        'minLength': 0,
                        'maxLength': 300,
                    },
                }
            }
        },
        'deleteList': {
            'type': 'array',
            'minItems': 0,
            'items': {
                'type': 'object',
                'additionalProperties': False,
                'required': [
                    'inspectionItemId',
                ],
                'properties': {
                    'inspectionItemId': {
                        'type': 'integer',
                    },
                }
            }
        }
    }
}
"""
IF3011 のバリデーション定義
"""

# -----------------------------
#  関数定義
# -----------------------------
def missing_record(inspection_item_id: int):
    """
    レコードが存在しないエラーをログに出力
    """
    msg = f'テーブル名: 点検項目, 点検項目ID: {inspection_item_id}'
    logger.error(Message.get_message(
        Message.ERR_NO_MATCHING_RECORD,
        textwrap.dedent(msg).strip()
    ))
    raise RDSException(original = None)

def update_inspection(tx, inspection_id: int, status: int, evidence_id: int):
    """
    点検レコードを更新する関数
    """
    # レコードの取得
    entity = TInspectionRepository.find_by_id(tx, inspection_id)

    if entity is None:
        # レコードが存在しない場合
        logger.error(Message.get_message(
            Message.ERR_NO_MATCHING_RECORD,
            f' (テーブル名: 点検, 点検ID: {inspection_id})'
        ))
        raise RDSException(original = None)

    # 該当レコードの更新
    entity.status = status
    entity.evidence_id = evidence_id
    entity.is_send = False

def insert_inspection_item(tx, req_item: dict, inspection_id: int):
    """
    点検項目のレコードを新規追加する
    """
    # レコードの追加
    TInspectionItemRepository.insert(tx, 
        TInspectionItem(
            inspection_id = inspection_id,
            item_name = req_item.get('inspectionItemName'),
            taken_dt = req_item.get('takenDt'),
            image_path = req_item.get('s3ImagePath'),
            progress = Progress.ANALYSIS_FINISHED,
        ))

def update_ocr_result(req_item: dict, item: TInspectionItem, path: str) -> str | None:
    """
    点検項目: OCR のレコードを更新する
    """
    # 一時変数の定義
    edited_model = req_item.get('editedModel')
    edited_serial_number = req_item.get('editedSerialNumber')

    db_edited_model = item.edited_model
    db_edited_serial_number = item.edited_serial_number

    # リネーム後のファイルパス
    dest_file_path = None

    # DBの値とリクエストの値が変わらないとき
    if db_edited_model == edited_model and \
        db_edited_serial_number == edited_serial_number:
        # ファイルパスを更新
        item.image_path = req_item.get('s3ImagePath')
    
    # DBに編集済の値が存在して、リクエストにも編集済の値が存在するとき
    elif db_edited_model and db_edited_serial_number and\
        edited_model and edited_serial_number:
        # リネーム後のパスを作成
        dest_file_path = path.replace(f'_{db_edited_model}_', f'_{edited_model}_')\
            .replace(f'_{db_edited_serial_number}', f'_{edited_serial_number}')
        
        # 修正したOCR結果の登録
        item.edited_model = edited_model
        item.edited_serial_number = edited_serial_number

    # DBに編集済みの値がなく、編集済みの値とDBのOCR結果が一致しているとき
    elif item.model == edited_model and \
        item.serial_number == edited_serial_number:
        
        # 修正したOCR結果の登録
        item.edited_model = edited_model
        item.edited_serial_number = edited_serial_number

    # DBに編集済みの値がなく、編集済の値が存在するとき
    elif edited_model and edited_serial_number:
        # リネーム後のパスを作成
        dest_file_path = path.replace(f'_{item.model}_', f'_{edited_model}_')\
            .replace(f'_{item.serial_number}', f'_{edited_serial_number}')
        
        # 修正したOCR結果の登録
        item.edited_model = edited_model
        item.edited_serial_number = edited_serial_number

    # 編集済の値が存在しない時
    else:
        # ファイルパスを更新
        item.image_path = req_item.get('s3ImagePath')
        
    return dest_file_path

def update_ai_result(req_item: dict, item: TInspectionItem, path: str) -> str | None:
    """
    点検項目: AI のレコードを更新する
    """
    # 一時変数の定義
    req_ng_comment = req_item.get('ngComment')
    db_ng_comment = item.ng_comment

    # リネーム後のファイルパス
    dest_file_path = None

    # DBの値とリクエストの値が同じとき
    if req_ng_comment == db_ng_comment:
        # ファイルパスを更新
        item.image_path = req_item.get('s3ImagePath')

    # NGコメントが登録済で、リクエスト値と異なるとき
    elif req_ng_comment and db_ng_comment:
        # リネームパスの作成
        dest_file_path = path.replace(db_ng_comment, req_ng_comment)
        
        # NGコメントの更新
        item.ng_comment = req_ng_comment
    
    # DBにNGコメントが未登録で、リクエスト値にNGコメントが存在するとき
    elif req_ng_comment:
        # NGコメントが未登録の場合
        dest_file_path = path.replace('NGコメント', req_ng_comment)

        # NGコメントの更新
        item.ng_comment = req_ng_comment

    else:
        # ファイルパスを更新
        item.image_path = req_item.get('s3ImagePath')

    return dest_file_path

def rename_object(analysis_type: AnalysisType, req_item: dict, item: TInspectionItem) -> dict | None:
    """
    S3上のオブジェクトのリネームを行う
    """
    # 現在のS3ファイルのバケット名とパスを取得
    bucket, path = S3.split_bucket_path(item.image_path)

    # リネーム後のオブジェクトパスの作成
    if AnalysisType.OCR == analysis_type:
        # 解析種別：OCR の処理
        dest_file_path = update_ocr_result(req_item, item, path)

    elif AnalysisType.AI == analysis_type:
        # 解析種：AI の処理
        dest_file_path = update_ai_result(req_item, item, path)

    else:
        # 解析種別：その他 の処理
        dest_file_path = None

    if dest_file_path:
        # S3オブジェクトのリネーム
        new_image_path = s3_client.copy_object(bucket, path, dest_file_path)
        item.image_path = new_image_path
        return {'bucket': bucket, 'key': path}

    else:
        item.image_path = req_item.get('s3ImagePath')
        return None

def update_exsist_inspection_item(record: tuple[TInspectionItem, MInspectionItem], req_item: dict) -> dict | None:
    """
    既にある点検項目情報を更新する関数
    """
    # 削除対象画像
    delete_image = None
    
    # tupleのアンパック
    item, master = record

    # 一時変数の定義
    analysis_type = master.analysis_type if master else AnalysisType.OTHER

    if AnalysisType.OCR == analysis_type:
        # 解析種別：OCR の処理
        delete_image = rename_object(analysis_type, req_item, item)

    elif AnalysisType.AI == analysis_type:
        # 解析種：AI の処理
        delete_image = rename_object(analysis_type, req_item, item)

    else:
        # 解析種別：その他 の処理
        image_path = req_item.get('s3ImagePath')

        if image_path:
            item.image_path = image_path
            item.progress = Progress.ANALYSIS_FINISHED

    # レコードの更新
    item.taken_dt = req_item.get('takenDt')

    return delete_image

def update_inspection_item(tx, inspection_id: int, item_list: list) -> list[dict]:
    """
    点検項目レコードを更新する関数
    """
    # 返却値格納用一時変数
    delete_images = []

    # 更新処理
    for req_item in item_list:

        # 点検項目ID
        inspection_item_id = req_item.get('inspectionItemId')

        # 撮影日を日付型に変換
        taken_dt = req_item.get('takenDt')
        req_item['takenDt'] = DateConverter.isoformat_2_datetime(taken_dt) if taken_dt else None

        # レコードの新規追加
        if inspection_item_id is None:
            # 未登録の点検項目の場合は新規登録
            insert_inspection_item(tx, req_item, inspection_id)
            continue
        
        # 既存レコードの更新
        else:
            # 該当レコードの取得
            record = TInspectionItemRepository.find_by_id_outer_join_item_master(tx, inspection_item_id)

            if record is None:
                # 対象レコードがない場合
                missing_record(inspection_item_id)

            delete_image = update_exsist_inspection_item(record, req_item)

            if delete_image:
                # リネーム前の画像のパスを追加
                delete_images.append(delete_image)

    return delete_images

@api_exception_handler(logger)
def main() -> Response:
    """
    APIのメイン処理
    """
    # RequestBodyの取得
    body = app.current_event.json_body

    # 入力チェック
    res = request_validation(body, IF3011, logger)

    if res is not None:
        # 入力値エラー検出時
        return res
    
    # 一時変数の定義
    item_list = body.get('inspectionResultItems')
    delete_item_id_list = body.get('deleteList')
    inspection_id = body.get('inspectionId')
    status = body.get('status')
    evidence_id = body.get('evidenceId')

    # リネーム後の削除対象画像を保持するリスト
    delete_images = []

    # DB接続の作成
    with conn.begin() as tx:

        # 点検項目レコードの削除
        if len(delete_item_id_list) > 0:
            delete_ids = [elm.get('inspectionItemId') for elm in delete_item_id_list]
            TInspectionItemRepository.delete_by_id(tx, delete_ids)

        # 点検テーブルの更新処理
        update_inspection(tx, inspection_id, status, evidence_id)

        # 点検項目テーブルの更新処理
        delete_images += update_inspection_item(tx, inspection_id, item_list)

    # S3オブジェクトの削除
    for image in delete_images:
        s3_client.delete_object(**image)

    # 正常終了レスポンスの作成
    return create_json_response(ResultCode.SUCCESS_20000)

@app.post('/inspection-result')
def api_if3011() -> Response:
    """
    検査完了時のリクエストを受信した際の処理 (Controller)
    """
    return main()
  
@logger.inject_lambda_context(
        log_event = Environment.get_bool(Environment.IS_DEBUG),
        correlation_id_path = correlation_paths.API_GATEWAY_REST
    )
@tracer.capture_lambda_handler
def lambda_handler(event, context: LambdaContext) -> dict:
    """
    Lambda起動時に呼ばれる処理(EventHandler)
    """
    return app.resolve(
        event = event,
        context = context
    )