from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.batch import (
    SqsFifoPartialProcessor,
    process_partial_response,
)
from aws_lambda_powertools.utilities.batch.types import PartialItemFailureResponse
from aws_lambda_powertools.utilities.data_classes.sqs_event import SQSRecord
from aws_lambda_powertools.utilities.typing import LambdaContext
from constant import (
    AIStatus,
    AIAnalysisResult,
    Progress,
    Message,
    Environment,
)
from helper import (
    HTTP,
    JsonConverter,
    S3,
    trigger_exception_handler,
)
from model import (
    DatabaseConnection,
    TInspectionItemRepository,
    MInspectionItemRepository,
    MLabelRepository,
    MInspectionItem,
)
from exception import RDSException
import textwrap
from exception import APIException

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

processor = SqsFifoPartialProcessor()  
"""
SQS FIFOキューのPartialProcessor
"""

# -----------------------------
#  関数定義
# -----------------------------
def missing_record(msg: str) -> None:
    """
    該当のレコードが見つからなかった場合の処理
    """
    logger.warning(Message.get_message(
        Message.WRN_MISSING_TARGET_RECORD,
        textwrap.dedent(msg).strip()
    ))

def get_label(transaction, item_name_id: int) -> list[str]:
    """
    AI判定結果のラベルを取得する
    """
    label_list = MLabelRepository.find_label_by_item_name_id(transaction, item_name_id)

    if label_list is None:
        # 該当のマスターレコードなし
        logger.error(Message.get_message(
            Message.ERR_NO_MATCHING_RECORD,
            f' (テーブル名: ラベルマスタ, 項目名ID: {item_name_id})'
        ))
        raise RDSException(original = None)
    
    return label_list

def get_ai_result(values: list, label_list: list[str]) -> AIAnalysisResult:
    """
    AI判定結果を各要素に分割し、OK / NG / 解析失敗 を判断する関数
    """
    if len(values) < 3:
        logger.warning(f'value値がIF仕様と異なります。{values}')
        return AIAnalysisResult.NG

    # 先頭の要素を取り出してリストから削除する
    result = int(values.pop(0))

    if result != 0:
        return AIAnalysisResult.get_val(result)

    # Value値ごとの処理
    for value in values:

        # ラベルと検出数を分離
        elms = value.split('=')

        if len(elms) < 2:
            # 要素数が2未満の場合は処理しない
            continue

        if (elms[0] in label_list) and int(elms[1]) > 0:
            # 対象の検出数が1以上の場合
            return AIAnalysisResult.OK
        
    # 対象のラベルが無かった場合    
    return AIAnalysisResult.NG

def check_result(resp: dict, label_list: list[str]) -> AIAnalysisResult:
    """
    AIの合否結果を判定する
    """
    # 判定結果の取得
    values = resp.get('value').split(',')
    status = resp.get('status')

    if status == AIStatus.SUCCESS:
        # 合格の場合
        return get_ai_result(values, label_list)

    else:
        # 失敗の場合
        return AIAnalysisResult.FAILED

def call_ai_api(file: dict, url: str, master_image: str, auth_token: str) -> dict:
    """
    外部AIサーバーの解析APIを呼出す

    Returns:
        dict: OCRの結果をdict型で返却
    """
    data = {
        'masterImageName': master_image,
        'authentication': auth_token
    }
    try:

        response = HTTP.send_form_post(url, data, file, {})
        logger.debug(HTTP.to_dict(response))

        return JsonConverter.json_loads(response.text)

    except APIException as err:
         # エラー時は解析失敗として扱う
        logger.warning(err)
        return {"value" : "-1,", "status": 0}

def execute_ai_analysis(file: dict, m_inspection_item: MInspectionItem, label_list: list[str]) -> AIAnalysisResult:
    """
    AI判定処理の実行
    """
    # AI呼出
    response_body = call_ai_api(file, m_inspection_item.api_url, m_inspection_item.master_image, m_inspection_item.auth_token)
    # 判定結果の解析
    return check_result(response_body, label_list)

def get_image_path(path: str) -> str:
    """
    S3のオブジェクトキーからファイル名を取得
    """
    array = path.split('/')

    if len(array) > 0:
        return array[-1]
    
    return path

def get_s3_object(bucket: str, key: str) -> dict:
    """
    対象のS3オブジェクトを取得する

    Args:
        bucket: 対象のS3バケット名
        key:    バケット内のオブジェクトパス

    Returns:
        dict:  {'パラメータ名': (ファイル名, バイナリデータ)}
    """
    s3_obj_bin = s3_client.get_object(bucket, key).read()
    image_name = get_image_path(key)
    return {'testImage': (image_name, s3_obj_bin)}

def main(inspection_item_id: str, bucket: str, original_image_path: str, trimming_image_path: str):
    """
    SQSのレコードに対するメイン処理を実行
    """
    # S3オブジェクトを取得
    file = get_s3_object(bucket, trimming_image_path)

    # DB接続
    with conn.begin() as tx:
        # 点検項目のレコード取得
        item = TInspectionItemRepository.find_by_id_with_update_lock(tx, inspection_item_id)

        if item is None or item.progress not in [Progress.REQUEST_RECEIVED, Progress.ANALYSIS_FINISHED]:
            # 対象レコードなしの処理
            missing_record(f'テーブル名: 点検項目, 点検項目ID: {inspection_item_id}, 進捗状況: {Progress.REQUEST_RECEIVED}')
            return
        
        # 点検項目名マスタのレコード取得
        master = MInspectionItemRepository.find_by_id(tx, item.item_name_id)
        
        if master is None:
            # 対象レコードなしの処理
            missing_record(f'テーブル名: 点検項目名マスタ, 点検項目名ID: {item.item_name_id}')
            return

        # AI判定のLabelを取得
        label_list = get_label(tx, item.item_name_id)

        # AI判定結果の取得
        analysis = execute_ai_analysis(file, master, label_list)

        # 判定結果に応じてリネームする文字列を変更
        if analysis == AIAnalysisResult.OK:
            replace_target_str = 'AI判定結果_NGコメント'
        else:
            replace_target_str = 'AI判定結果'

        # S3上のファイル名を修正
        dest_file_path = original_image_path.replace(replace_target_str, analysis.result)
        # 新しいファイル名でオブジェクトをコピー
        new_image_path = s3_client.copy_object(bucket, original_image_path, dest_file_path)

        # RDS更新
        item.image_path = new_image_path
        item.ai_result = analysis.result
        item.ng_comment = None
        item.progress = Progress.ANALYSIS_FINISHED

@tracer.capture_method
@trigger_exception_handler(logger)
def record_handler(record: SQSRecord):
    """
    SQSのレコード毎に処理を実行
    """
    payload = record.json_body
    logger.debug(payload)

    args = {
        "inspection_item_id": payload.get('inspectionItemId'),
        "bucket": payload.get('bucketName'),
        "original_image_path": payload.get('originalImagePath'),
        "trimming_image_path": payload.get('trimmingImagePath'),
    }

    # Body部のデータに対する処理
    main(**args)

@logger.inject_lambda_context(log_event = Environment.get_bool(Environment.IS_DEBUG))
@tracer.capture_lambda_handler
def lambda_handler(event, context: LambdaContext) -> PartialItemFailureResponse:
    """
    Lambda起動時に呼ばれる処理
    """
    return process_partial_response(
        event = event, 
        record_handler = record_handler, 
        processor = processor, 
        context = context
    )
