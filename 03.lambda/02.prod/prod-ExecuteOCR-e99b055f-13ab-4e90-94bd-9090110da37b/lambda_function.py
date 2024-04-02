from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.batch import SqsFifoPartialProcessor, process_partial_response
from aws_lambda_powertools.utilities.batch.types import PartialItemFailureResponse
from aws_lambda_powertools.utilities.data_classes.sqs_event import SQSRecord
from aws_lambda_powertools.utilities.typing import LambdaContext
from constant import (
    Progress,
    Message,
    Environment,
    AIAnalysisResult,
)
from helper import (
    S3,
    Textract,
    trigger_exception_handler,
)
from model import (
    DatabaseConnection,
    TInspectionItemRepository,
    MInspectionItemRepository,
)
import re, textwrap

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

textract_client = Textract()
"""
Textractの接続情報を管理するインスタンス
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

def ocr_result_analysis(ocr_result:dict) -> tuple[str, str]:
    """
    OCRの結果から品番と製造番号を取得する

    Returns:
        tuple(model:str, serial_number:str): タプル型で (品番、製造番号として返却)
    """
    model = "ReadError"
    serial_number = "ReadError"

    for item in ocr_result['Blocks']:

        if item['BlockType'] != 'LINE':
            continue
        
        val = item['Text']

        if not re.match('^[-* 0-9a-zA-Z]+$', val):
            # 英数字と"-* (半角スペース)"以外の文字を含む場合
            continue
        
        elif re.search('(/|V|Hz|kW|g|kg|MPa|WS No)', val):
            # 単位を含む値の場合
            continue

        elif re.match('HE-.{3,}', val):
            # HE- の後に3文字以上の文字列を含む場合
            model = val

        elif re.match('^\D+$', val):
            # 数字を含まない値の場合
            continue

        elif re.search('5[0-9a-zA-Z]{6,}', val):
            # "5"で始まる7文字以上の文字列を含む場合
            serial_number = re.search('5[0-9a-zA-Z]{6,}', val).group()

    return (model, serial_number)

def main(inspection_item_id: int, bucket: str, original_image_path: str, trimming_image_path: str):
    """
    SQSのレコードに対するメイン処理を実行
    """
    # S3オブジェクトを取得
    s3_obj_bin = s3_client.get_object(bucket, trimming_image_path).read()

    # OCR処理
    res = textract_client.detect_text_byte(s3_obj_bin)
    model, serial_number = ocr_result_analysis(res)

    # DB接続
    with conn.begin() as tx:
        # 点検項目のレコード取得
        item = TInspectionItemRepository.find_by_id_with_update_lock(tx, inspection_item_id)

        if item is None or item.progress not in [Progress.REQUEST_RECEIVED, Progress.ANALYSIS_FINISHED]:
            # 対象レコードなしの処理
            missing_record(f'テーブル名: 点検項目, 点検項目ID: {inspection_item_id}, 進捗状況: {Progress.REQUEST_RECEIVED}')
            return

        # S3ファイルを別名でコピー
        dest_file_path = original_image_path.replace('AI判定結果_NGコメント', f'{model}_{serial_number}')
        new_image_path = s3_client.copy_object(bucket, original_image_path, dest_file_path)

        # RDS更新
        item.ai_result = AIAnalysisResult.OK.result
        item.image_path = new_image_path
        item.model = model
        item.serial_number = serial_number
        item.edited_model = None
        item.edited_serial_number = None
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
