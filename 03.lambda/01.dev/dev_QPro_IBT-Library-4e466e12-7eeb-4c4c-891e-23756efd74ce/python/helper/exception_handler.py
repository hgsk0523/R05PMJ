from aws_lambda_powertools import Logger
from sqlalchemy.exc import SQLAlchemyError
from constant import Message
from exception import (
    S3Exception,
    SQSException,
    TextractException,
    APIException,
)
from functools import wraps

def trigger_exception_handler(logger: Logger):
    """
    トリガー起動のLambda関数共通の例外処理
    """

    def _decorator(func):

        @wraps(func)
        def wrapper(*args, **kwargs):
            
            try:
                # 処理開始ログ
                logger.debug(Message.get_message(Message.DBG_PROCESS_START, func.__name__))

                return func(*args, **kwargs)

            except SQLAlchemyError:
                # Database処理例外
                logger.exception(Message.get_message(Message.ERR_OCCURRED_DB_EXCEPTION))
                raise

            except SQSException:
                # SQS処理例外
                logger.exception(Message.get_message(Message.ERR_OCCURRED_SQS_EXCEPTION))
                raise

            except S3Exception:
                # S3処理例外
                logger.exception(Message.get_message(Message.ERR_OCCURRED_S3_EXCEPTION))
                raise

            except TextractException:
                # Textract処理例外
                logger.exception(Message.get_message(Message.ERR_OCCURRED_TEXTRACT_EXCEPTION))
                raise

            except APIException:
                # Textract処理例外
                logger.exception(Message.get_message(Message.ERR_OCCURRED_API_EXCEPTION))
                raise

            except Exception:
                # 予期せぬ例外
                logger.exception(Message.get_message(Message.ERR_OCCURRED_UNEXPECTED_EXCEPTION))
                raise

            finally:
                # 処理終了ログ
                logger.debug(Message.get_message(Message.DBG_PROCESS_FINISH, func.__name__))

        return wrapper
    
    return _decorator