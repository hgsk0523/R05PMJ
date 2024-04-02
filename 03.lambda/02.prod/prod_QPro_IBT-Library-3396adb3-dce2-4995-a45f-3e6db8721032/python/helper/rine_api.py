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
from enum import IntEnum, unique
from .api_gateway import create_response
from .json_converter import JsonConverter
from .validation import validation

@unique
class ProcessResultCode(IntEnum):
    """
    処理結果を管理するEnum
    """
    SUCCESS = 1,
    """
    正常終了時の処理結果コード
    """

    ERROR = 9,
    """
    異常終了時の処理結果コード
    """

def create_rine_success_response(code: ResultCode, result_list: list[dict]) -> Response:
    """
    処理成功時のレスポンスボディを生成する関数
    """
    body = {
        'response': {
            'common_head': {
                'STATUS': ProcessResultCode.SUCCESS,
            },
            'gyomu_head': {
                'RECORDCOUNT': len(result_list)
            },
            'gyomu_body': {
                'RESULTS': result_list 
            }
        }
    }
    return create_response(code, JsonConverter.json_dump(body), content_types.APPLICATION_JSON)

def create_rine_error_response(code: ResultCode) -> Response:
    """
    処理失敗時のレスポンスボディを生成する関数
    """
    body = {
        'response': {
            'common_head': {
                'STATUS': ProcessResultCode.ERROR,
            },
            'error_body': {
                'CODE': code.result_code,
                'MESSAGE': code.message,
            }
        }
    }
    return create_response(code, JsonConverter.json_dump(body), content_types.APPLICATION_JSON)

def rine_request_validation(request_body: dict, schema: dict, logger: Logger) -> Response:
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
        return create_rine_error_response(ret)
    
    else:
        return None

def rine_api_exception_handler(logger: Logger) -> Response:
    """
    例外処理用Wrapper関数
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
                return create_rine_error_response(ResultCode.INTERNAL_ERROR_50000)

            except SQSException:
                # SQS処理例外
                logger.exception(Message.get_message(Message.ERR_OCCURRED_SQS_EXCEPTION))
                return create_rine_error_response(ResultCode.INTERNAL_ERROR_50001)

            except S3Exception:
                # S3処理例外
                logger.exception(Message.get_message(Message.ERR_OCCURRED_S3_EXCEPTION))
                return create_rine_error_response(ResultCode.INTERNAL_ERROR_50002)
            
            except APIException:
                # 外部API呼出処理例外
                logger.exception(Message.get_message(Message.ERR_OCCURRED_API_EXCEPTION))
                return create_rine_error_response(ResultCode.INTERNAL_ERROR_50003)

            except Exception:
                # 予期せぬ例外
                logger.exception(Message.get_message(Message.ERR_OCCURRED_UNEXPECTED_EXCEPTION))
                return create_rine_error_response(ResultCode.INTERNAL_ERROR_50004)
            
            finally:
                # 処理終了ログの出力
                logger.debug(Message.get_message(Message.DBG_PROCESS_FINISH, func.__name__))

        return wrapper
    
    return _decorator