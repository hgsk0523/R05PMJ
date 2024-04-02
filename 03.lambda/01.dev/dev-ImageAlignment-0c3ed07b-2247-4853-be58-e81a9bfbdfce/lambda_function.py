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
    create_rine_success_response,
    rine_request_validation,
    rine_api_exception_handler,
    S3,
    DateConverter,
)
from model import (
    DatabaseConnection,
    TInspectionRepository,
    VInspectionItemRepository,
    TInspection,
    MInspection,
)
import base64

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

app = APIGatewayRestResolver()
"""
API Gatewayのペイロードリゾルバーインスタンス
"""

s3_client = S3(logger)
"""
s3の接続情報を管理するインスタンス
"""

IF2010 = {
    '$schema': 'http://json-schema.org/draft-07/schema#',
    'title': 'validate_api-IF000302',
    'description': 'for IF000102 json validate',
    'type': 'object',
    'additionalProperties': False,
    'required': [
        'request',
    ],
    'properties' : {
        'request': {
            'required' : [
                'common_head',
            ],
            'properties' : {
                'common_head': {
                    'type': 'object',
                    'required': [
                        'STATUS'
                    ],
                    'properties' :{
                        "STATUS" : {
                            'type': 'number',
                            'minimum': 0,
                            'maximum': 1,
                        }
                    }
                },
                'gyomu_body': {
                    'type': 'object',
                    'required': [
                        'WSHEETNO'
                    ],
                    'properties' :{
                        "WSHEETNO" : {
                            'type': 'number',
                            'minimum': 0,
                            'maximum': 9999999999,
                        }
                    }
                }
            }
        }
    }
}
"""
IF2010 のバリデーション定義
"""

# -----------------------------
#  関数定義
# -----------------------------
def create_response_data(tx, inspection: TInspection, master: MInspection) -> dict:
    """
    画像連携APIのレスポンス用のデータを生成する関数
    """
    # 変数の初期化
    shoot_list = []
    seq_no = 0

    # 対象点検項目の取得
    items = VInspectionItemRepository.find_by_inspection_id(tx, inspection.inspection_id)

    for item in items:
        # KVSに変換
        d_item = item.to_dict()
        
        # 写真Noの設定
        seq_no += 1
        d_item['SHOOTNO'] = seq_no

        if item.image_path:
            # S3からファイル取得
            bucket, path = S3.split_bucket_path(item.image_path)
            d_item['IMG'] = base64.b64encode(s3_client.get_object(bucket, path).read()).decode()

        # 写真リストに追加
        shoot_list.append(d_item)

    # 点検情報KVSの作成
    return {
        'KAISHACD': inspection.company_code,
        'WSHEETNO': inspection.worksheet_code,
        'UUKAKUTEIDATE': inspection.receipt_confirmation_date,
        'EVIDENCENM': master.inspection_name,
        'EVIDENCEPT': inspection.evidence_id,
        'SENDCOUNT': inspection.send_count,
        'SHOOTCNT': len(shoot_list),
        'shoot_list': shoot_list
    }

def get_response_data_by_worksheet_code(tx, worksheet_code: str) -> list[dict]:
    """
    点検情報を取得し、レスポンス情報を取得する関数(WorkSheetCode指定の場合)
    """
    # 該当のWorkSheetCodeレコードを取得
    records = TInspectionRepository.find_by_worksheet_code(tx, worksheet_code)

    ret = []

    recordCount = 0

    for record in records:
        # tupleのアンパック
        inspection, master = record

        # レコード件数の取得
        recordCount += len(VInspectionItemRepository.find_by_inspection_id(tx, inspection.inspection_id))

        if recordCount > 20:
            break

        # データの作成
        ret.append(create_response_data(tx, inspection, master))

    return ret

def get_response_data_by_send_flag(tx) -> list[dict]:
    """
    点検情報を取得し、レスポンス情報を取得する関数(未送信データ全ての場合)
    """
    # 未送信のレコードを取得
    records = TInspectionRepository.find_by_is_send(tx)

    ret = []

    recordCount = 0

    for record in records:
        # tupleのアンパック
        inspection, master = record

        # レコード件数の取得
        recordCount += len(VInspectionItemRepository.find_by_inspection_id(tx, inspection.inspection_id))

        if recordCount > 20:
            break


        # データの作成
        ret.append(create_response_data(tx, inspection, master))

        # レコードの更新
        inspection.is_send = True
        if inspection.send_count < 9:
            inspection.send_count += 1

    return ret

@rine_api_exception_handler(logger)
def main() -> Response:
    """
    APIのメイン処理
    """
    # Requestボディの取得
    body = app.current_event.json_body

    # 入力チェック
    result_list = rine_request_validation(body, IF2010, logger)

    if result_list is not None:
        return result_list

    # 一時変数の定義
    result_list = []
    status = body.get('request').get('common_head').get('STATUS')
    if status != 0:
        worksheet_code = body.get('request').get('gyomu_body').get('WSHEETNO')
    else:
        worksheet_code = None

    # DB接続の作成
    with conn.begin() as tx:

        if worksheet_code is None:
            # 未送信データを一括で取得
            result_list = get_response_data_by_send_flag(tx)

        else:
            # WorkSheetCodeで取得
            result_list = get_response_data_by_worksheet_code(tx, worksheet_code)

    return create_rine_success_response(ResultCode.SUCCESS_20000, result_list)

@app.post("/image-alignment")
def api_if_2010() -> Response:
    """
    画像連携のリクエストを受信した際の処理 (Controller)
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