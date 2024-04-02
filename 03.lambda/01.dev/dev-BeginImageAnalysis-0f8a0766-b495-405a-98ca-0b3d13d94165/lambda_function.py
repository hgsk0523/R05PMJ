from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.event_handler import APIGatewayRestResolver
from aws_lambda_powertools.event_handler.api_gateway import Response
from aws_lambda_powertools.logging import correlation_paths
from aws_lambda_powertools.utilities.typing import LambdaContext
from constant import (
    Environment,
    Message,
    Progress,
    ResultCode,
    AnalysisType,
)
from helper import (
    create_json_response,
    request_validation,
    api_exception_handler,
    SQS,
    JsonConverter,
)
from model import (
    DatabaseConnection,
    TInspectionItemRepository,
    MInspectionItemRepository,
)
import textwrap

# -----------------------------
#  グローバル変数
# -----------------------------
conn = DatabaseConnection()
"""
DBの接続情報を管理するインスタンス
"""

sqs_client = SQS()
"""
SQSの接続情報を管理するインスタンス
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

IF3013 = {
    '$schema': 'http://json-schema.org/draft-07/schema#',
    'title': 'validate_api-IF3013',
    'description': 'for IF3013 json validate',
    'type': 'object',
    'additionalProperties': False,
    'required': [
        'inspectionId',
        'inspectionItemId',
        'bucketName',
        'originalImagePath',
        'trimmingImagePath',
    ],
    'properties' :{
        'inspectionId': {
            'type': 'integer',
        },
        'inspectionItemId': {
            'type': 'integer',
        },
        'bucketName': {
            'type': 'string',
        },
        'originalImagePath': {
            'type': 'string',
            'minLength': 1,
            'maxLength': 300,
        },
        'trimmingImagePath': {
            'type': 'string',
            'minLength': 1,
            'maxLength': 300,
        },
    }
}
"""
IF3013 のバリデーション定義
"""

# -----------------------------
#  関数定義
# -----------------------------
def sqs_send_message(env: Environment, message: str):
    """
    SQS Queueにメッセージを登録
    """
    queue_url = Environment.get_str(env)
    sqs_client.send_message(queue_url, message)    

def missing_record(msg: str) -> Response:
    """
    該当のレコードが見つからなかった場合の処理
    """
    logger.warning(Message.get_message(
        Message.WRN_MISSING_TARGET_RECORD,
        textwrap.dedent(msg).strip()
    ))
    return create_json_response(ResultCode.SUCCESS_20001)

def missing_analysis_type(inspection_item_id: int, analysis_type: AnalysisType) -> Response:
    """
    該当の解析種別が見つからなかった場合の処理
    """
    logger.warning(
            Message.get_message(Message.WRN_UNMATCHED_AI_ANALYSIS_TARGET,
            f'点検項目ID: {inspection_item_id}, 解析種別: {analysis_type}')
        )
    return create_json_response(ResultCode.INTERNAL_ERROR_50004)

@api_exception_handler(logger)
def main() -> Response:
    """
    APIのメイン処理
    """
    # Request Bodyの取得
    body = app.current_event.json_body

    # 入力チェック
    res = request_validation(body, IF3013, logger)

    if res is not None:
        # 入力値エラー検出時
        return res

    # SQSメッセージの作成
    msg = JsonConverter.json_dump(body)

    # 一時変数の定義
    inspection_item_id = body.get('inspectionItemId')
    
    # DB接続の作成
    with conn.begin() as tx:

        # レコードの取得
        item = TInspectionItemRepository.find_by_id_with_update_lock(tx, inspection_item_id)

        if item is None:
            # 該当レコードが無い場合
            return missing_record(f'テーブル名: 点検項目, 点検項目ID: {inspection_item_id}')

        # 点検項目マスタのレコードを取得
        master = MInspectionItemRepository.find_by_id(tx, item.item_name_id)

        # 一時変数の定義
        analysis_type = master.analysis_type if master else AnalysisType.OTHER
        version = item.version + 1

        if AnalysisType.OCR == analysis_type:
            # OCR処理を呼出
            sqs_send_message(Environment.OCR_QUEUE_URL, msg)

        elif AnalysisType.AI == analysis_type:
            # AI判定処理を呼出
            sqs_send_message(Environment.AI_QUEUE_URL, msg)

        else:
            # 該当解析種別なしのエラー応答
            return missing_analysis_type(inspection_item_id, analysis_type) 

        # 撮影日時の初期化
        item.taken_dt = None
        # 進捗状況更新
        item.progress = Progress.REQUEST_RECEIVED

    # レスポンスの生成
    response = {
        'inspectionId': body.get('inspectionId'),
        'inspectionItemId': inspection_item_id,
        'progress': Progress.REQUEST_RECEIVED,
        'version': version,
    }

    return create_json_response(ResultCode.SUCCESS_20000, response)

@app.post('/begin-image-analysis')
def api_if_3013() -> Response:
    """
    解析依頼のリクエストを受信した際の処理 (Controller)
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