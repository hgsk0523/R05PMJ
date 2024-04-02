from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.event_handler import APIGatewayRestResolver
from aws_lambda_powertools.event_handler.api_gateway import Response
from aws_lambda_powertools.logging import correlation_paths
from aws_lambda_powertools.utilities.typing import LambdaContext
from constant import (
    Environment,
    InspectionStatus,
    Progress,
    ResultCode,
    Message,
)
from helper import (
    create_json_response,
    request_validation,
    api_exception_handler,
    S3,
)
from model import (
    DatabaseConnection,
    MInspectionRepository,
    MInspectionItemRepository,
    TInspectionRepository,
    TInspection,
    TInspectionItemRepository,
    TInspectionItem,
)
from exception import RDSException

# -----------------------------
#  グローバル変数
# -----------------------------
conn = DatabaseConnection()
"""
DBの接続情報を管理するインスタンス
"""

app = APIGatewayRestResolver()
"""
API Gatewayのペイロードリゾルバーインスタンス
"""

tracer = Tracer()
"""
X-RayのTracerインスタンス
"""

logger = Logger()
"""
Loggerインスタンス
"""

IF3010 = {
    '$schema': 'http://json-schema.org/draft-07/schema#',
    'title': 'validate_api-IF3010',
    'description': 'for IF3010 json validate',
    'type': 'object',
    'additionalProperties': False,
    'required': [
        'worksheetCode',
        'receiptConfirmationDate',
        'inspectionName',
        'inspectionDate',
        'companyCode'
    ],
    'properties' :{
        'worksheetCode': {
            'type': 'string',
            'minLength': 10,
            'maxLength': 10,
        },
        'receiptConfirmationDate': {
            'type': 'integer',
        },
        'inspectionName': {
            'type': 'string',
            'minLength': 1,
            'maxLength': 15,
        },
        'inspectionDate': {
            'type': 'integer',
        },
        'companyCode': {
            'type': 'string',
            'minLength': 1,
            'maxLength': 8,
        },
    }
}
"""
IF3010 のバリデーション定義
"""

# -----------------------------
#  関数定義
# -----------------------------
def create_inspection_item_record(tx, inspection_name_id: int, inspection_id: int) -> list[TInspectionItem]:
    """
    点検項目情報を新規作成する

    Returns:
        list[TInspectionItem]: 作成した点検項目レコード
    """
    # 点検項目マスタ情報を取得
    records = MInspectionItemRepository.find_by_inspection_name_id(tx, inspection_name_id)

    if records is None:
        # 該当のマスターレコードなし
        logger.error(Message.get_message(
            Message.ERR_NO_MATCHING_RECORD,
            f' (テーブル名: 点検項目マスタ, 点検名ID: {inspection_name_id})'
        ))
        raise RDSException(original = None)

    ret_list = []

    for record in records:
        item = TInspectionItemRepository.insert(tx, TInspectionItem(
                           inspection_id = inspection_id,
                           item_name_id = record.item_name_id,
                           item_name = record.item_name,
                           progress = Progress.WAITING_IMAGE_SAVE
                        ))

        ret_list.append(item)

    return ret_list

def create_inspection_record(tx, body: dict) -> tuple[TInspection, list[TInspectionItem]]:
    """
    点検情報と点検に紐付く点検項目情報をを新規作成する

    Returns:
        tuple[TInspection, list[TInspectionItem]]:
        TInspection -> 作成した点検情報
        list[TInspectionItem] -> 作成した点検項目情報
    """
    inspection_name = body.get('inspectionName')

    # 点検名の取得
    record = MInspectionRepository.find_by_name(tx, inspection_name)

    if record is None:
        # 該当のマスターレコードなし
        logger.error(Message.get_message(
            Message.ERR_NO_MATCHING_RECORD,
            f' (テーブル名: 点検マスタ, 点検名: {inspection_name})'
        ))
        raise RDSException(original = None)

    # 点検情報の作成
    inspection = TInspectionRepository.insert(tx, TInspection(
                        inspection_name_id = record.inspection_name_id,
                        worksheet_code = body.get('worksheetCode'),
                        receipt_confirmation_date = body.get('receiptConfirmationDate'),
                        inspection_date = body.get('inspectionDate'),
                        status = InspectionStatus.PENDING_INSPECTION,
                        company_code = body.get('companyCode'),
                        send_count = 0,
                        is_send = False
                    ))
    
    items = create_inspection_item_record(tx, record.inspection_name_id, inspection.inspection_id)

    return (inspection, items)

def get_inspection_item_record(tx, inspection_id: int) -> list[TInspectionItem]:
    """
    該当の点検IDに紐付く点検項目情報を取得する
    """
    return TInspectionItemRepository.find_by_inspection_id(tx, inspection_id)

def update_inspection(tx, inspection_id: int, body: dict):
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
    entity.company_code = body.get('companyCode')
    entity.inspection_date = body.get('inspectionDate')
    
@api_exception_handler(logger)
def main() -> Response:
    """
    APIのメイン処理
    """
    # Request Bodyの取得
    body = app.current_event.json_body

    # 入力チェック
    res = request_validation(body, IF3010, logger)

    if res is not None:
        # 入力値エラー検出時
        return res

    # 一時変数の定義
    worksheet_code = body.get('worksheetCode')
    receipt_confirmation_date = body.get('receiptConfirmationDate')
    
    # DB接続の作成
    with conn.begin() as tx:

        # 点検データの確認
        inspection = TInspectionRepository.find_by_unique_key(tx, worksheet_code, receipt_confirmation_date)

        if inspection is None:
            # データ作成
            inspection, items = create_inspection_record(tx, body)

        else:
            # 点検項目の取得
            items = get_inspection_item_record(tx, inspection.inspection_id)

        # entity → dictの変換
        items_dict = [item.to_dict() for item in items]

        # 画像パスの分離&エンコード
        for item_dict in items_dict:
            image_path = item_dict.get('s3ImagePath')
            obj  = S3.split_bucket_path(image_path) if image_path else (None, None)
            item_dict['s3ImagePath'] = obj[1]
        
        # 点検テーブルの更新処理
        update_inspection(tx, inspection.inspection_id, body)

        # レスポンスボディの作成
        response = {
            'schedule': {
                'id': inspection.inspection_id,
                'inspectionNameId': inspection.inspection_name_id,
                'status': inspection.status
            },
            'items': items_dict
        }

    return create_json_response(ResultCode.SUCCESS_20000, response)

@app.post('/get-inspection-item')
def api_if_3010() -> Response:
    """
    点検項目取得のリクエストを受信した際の処理 (Controller)
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