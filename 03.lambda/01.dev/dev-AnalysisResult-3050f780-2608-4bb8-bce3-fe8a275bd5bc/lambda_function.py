from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.event_handler import APIGatewayRestResolver
from aws_lambda_powertools.event_handler.api_gateway import Response
from aws_lambda_powertools.logging import correlation_paths
from aws_lambda_powertools.utilities.typing import LambdaContext
from constant import (
    ResultCode,
    Environment,
)
from helper import (
    api_exception_handler,
    create_json_response,
    request_validation,
    DateConverter,
    S3,
)
from model import (
    DatabaseConnection,
    TInspectionItemRepository,
    TInspectionItem,
)

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

IF3014 = {
    '$schema': 'http://json-schema.org/draft-07/schema#',
    'title': 'validate_api-IF3014',
    'description': 'for IF3014 json validate',
    'type': 'object',
    'additionalProperties': False,
    'required': [
        'lastUpdatedAt',
        'inspectionId',
    ],
    'properties' :{
        'lastUpdatedAt': {
            'type': 'string',
            'format': 'date-time'
        },
        'inspectionId': {
            'type': 'string',
            'pattern': '^[0-9]{1,18}$',
        },
    }
}
"""
IF3014 のバリデーション定義
"""

# -----------------------------
#  関数定義
# -----------------------------
def get_item_record(entity_list: list[TInspectionItem], inspection_id: int) -> list[dict]:
    """
    受け取ったリストをもとに辞書型オブジェクトの配列を取得する

    Returns:
        list[dict]: 辞書型オブジェクトの配列(配列サイズは取得したレコード件数と同じ)
    """
    ret_list = []    

    for entity in entity_list:

        # 画像パスの取得
        img_path = entity.image_path

        if img_path:
            # バケット名とパスを分解
            _, img_path = S3.split_bucket_path(img_path)

        ret_list.append({
            'inspectionId': inspection_id,
            'inspectionItemId': entity.inspection_item_id,
            'result': entity.ai_result,
            'model': entity.model,
            'serialNumber': entity.serial_number,
            'progress': entity.progress,
            's3ImagePath': img_path,
            'version': entity.version,
        })

    return ret_list

@api_exception_handler(logger)
def main() -> Response:
    """
    APIのメイン処理
    """
    # Request Query Parameterの取得
    query = app.current_event.query_string_parameters

    # 入力チェック
    res = request_validation(query, IF3014, logger)

    if res is not None:
        return res

    # 一時変数の定義
    inspection_id = int(query.get('inspectionId'))
    updated_at = DateConverter.isoformat_2_datetime(query.get('lastUpdatedAt'))

    # DB接続の作成
    with conn.begin() as tx:

        # 該当レコードの取得
        entities = TInspectionItemRepository.find_by_inspection_id_and_updated_at(tx, inspection_id, updated_at)

        # レスポンスの生成
        response = get_item_record(entities, inspection_id)

    return create_json_response(ResultCode.SUCCESS_20000, {"analysisResultItems": response})

@app.get("/analysis-result")
def api_if_3014() -> Response:
    """
    AI解析結果取得のリクエストを受信した際の処理 (Controller)
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