from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.validation import validate
from aws_lambda_powertools.utilities.validation.exceptions import SchemaValidationError
from constant import ResultCode, Message, ValidationPattern
import re

# ================================
#  バリデーション用の関数定義
# ================================
def _match(pattern: ValidationPattern, target):
    """
    正規表現マッチを実行する関数

    Args:
        pattern: 正規表現パターン
        target: 検索対象文字列

    Returns:
        Match: マッチしたオブジェクトを返却
    """
    return re.match(pattern.value, target)

def validation(target:dict, schema:dict, logger:Logger) -> ResultCode | None:
    """
    Validation実行時の例外処理

    Args:
        target: バリデーションの対象となる連想配列
        conf: バリデーションの設定

    Returns:
        error_code: 異常発生時はエラーコードを返却
    """
    try:
        # バリデーション実行
        validate(target, schema)

        # 無効な値なし
        return None

    except SchemaValidationError as e:
        # 無効な値が含まれていた場合の処理
        # ※validate()で例外がraiseされる
        logger.debug(Message.get_message(Message.DBG_VALIDATION_MESSAGE, e.validation_message, e.rule, e.definition))

        if _match(ValidationPattern.PATTERN_REQUIRED, e.rule):
            return ResultCode.BAD_REQUEST_40000

        elif _match(ValidationPattern.PATTERN_UNNECESSARY_PARAMETER, e.rule):
            return ResultCode.BAD_REQUEST_40001

        elif _match(ValidationPattern.PATTERN_INCORRECT_TYPE, e.rule):
            return ResultCode.BAD_REQUEST_40001
        
        elif _match(ValidationPattern.PATTERN_INCORRECT_PARAMETER_RANGE, e.rule):
            return ResultCode.BAD_REQUEST_40002
        
        elif _match(ValidationPattern.PATTERN_INCORRECT_PATTERN, e.rule):
            return ResultCode.BAD_REQUEST_40002

        else:
            logger.exception(Message.get_message(Message.ERR_OCCURRED_VALIDATION_EXCEPTION))
            raise

    except:
        logger.exception(Message.get_message(Message.ERR_OCCURRED_UNEXPECTED_EXCEPTION))
        raise


