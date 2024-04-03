from aws_lambda_powertools import Logger
from aws_lambda_powertools.event_handler import content_types
from aws_lambda_powertools.event_handler.api_gateway import Response
from constant import (
    ResultCode,
    Message,
)
from exception import (
    RDSException,
    S3Exception,
    SQSException,
    APIException,
)
from functools import wraps
from .json_converter import JsonConverter
from .validation import validation

def _create_response_header() -> dict:
    """
    共通のResponse Headerを作成する
    """
    return {
        'X-Content-Type-Options': 'nosniff',
        'Cache-Control': 'no-store',
        'Content-Security-Policy': "default-src 'self';",
        'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
    }

def create_response(result: ResultCode, body: str, content_type: content_types) -> Response:
    """
    レスポンス作成用処理
    """
    # レスポンスに含むパラメータの定義
    response_param = {
        'status_code': result.response_status,
        'content_type': f'{content_type};charset=UTF-8',
        'headers': _create_response_header(),
        'body': body
    } 

    return Response(**response_param)

def create_json_response(result: ResultCode, body: dict = None) -> Response:
    """
    API Gatewayのレスポンスを作成する関数
    レスポンスボディの resultCode は関数内処理で追加

    Arguments:
        result: 定数のResultCodeクラス
        body: resultCodeを除いたレスポンスボディ
        content_type: JSON形式以外は指定する

    Returns:
        Response: API Gateway用のレスポンス
    """

    if body is None:
        # body が None の場合は初期化
        body = {}
    
    # bodyに resultCode を追加
    body.setdefault('resultCode', result.result_code)

    return create_response(result, JsonConverter.json_dump(body), content_types.APPLICATION_JSON)

def request_validation(request_body: dict, schema: dict, logger: Logger) -> Response:
    """
    リクエストのパラメータチェックを行う

    Args:
        request_body:
        schema:
        logger:

    Returns:
        Response:
    """
    # 入力チェック
    ret = validation(request_body, schema, logger)
    
    if ret is not None:
        # 入力チェックエラー発生時
        return create_json_response(ret)
    
    else:
        return None

def api_exception_handler(logger: Logger) -> Response:
    """
    APIGatewayから呼ばれるLambdaの例外処理wrapper関数
    """

    def _decorator(func) -> Response:

        @wraps(func)
        def wrapper(*args, **kwargs) -> Response:
            
            try:
                # 処理開始ログの出力
                logger.debug(Message.get_message(Message.DBG_PROCESS_START, func.__name__))

                return func(*args, **kwargs)
            
            except RDSException:
                # Database処理例外
                logger.exception(Message.get_message(Message.ERR_OCCURRED_DB_EXCEPTION))
                return create_json_response(ResultCode.INTERNAL_ERROR_50000)

            except SQSException:
                # SQS処理例外
                logger.exception(Message.get_message(Message.ERR_OCCURRED_SQS_EXCEPTION))
                return create_json_response(ResultCode.INTERNAL_ERROR_50001)

            except S3Exception:
                # S3処理例外
                logger.exception(Message.get_message(Message.ERR_OCCURRED_S3_EXCEPTION))
                return create_json_response(ResultCode.INTERNAL_ERROR_50002)
            
            except APIException:
                # 外部API呼出処理例外
                logger.exception(Message.get_message(Message.ERR_OCCURRED_API_EXCEPTION))
                return create_json_response(ResultCode.INTERNAL_ERROR_50003)           

            except Exception:
                # 予期せぬ例外
                logger.exception(Message.get_message(Message.ERR_OCCURRED_UNEXPECTED_EXCEPTION))
                return create_json_response(ResultCode.INTERNAL_ERROR_50004)
            
            finally:
                # 処理終了ログの出力
                logger.debug(Message.get_message(Message.DBG_PROCESS_FINISH, func.__name__))


        return wrapper
    
    return _decorator