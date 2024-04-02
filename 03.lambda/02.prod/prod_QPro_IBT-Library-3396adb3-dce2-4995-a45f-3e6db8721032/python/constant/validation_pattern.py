from enum import Enum, unique

@unique
class ValidationPattern(Enum):

    PATTERN_REQUIRED = 'required'
    """
    バリデーションルール: 必須項目
    """

    PATTERN_UNNECESSARY_PARAMETER = 'additionalProperties'
    """
    バリデーションルール: 不要なパラメータ
    """

    PATTERN_INCORRECT_TYPE = '(type|format)'
    """
    バリデーションルール: データ型/形式
    """

    PATTERN_INCORRECT_PATTERN = 'pattern'
    """
    バリデーションルール: パターン一致
    """

    PATTERN_INCORRECT_PARAMETER_RANGE = '(minLength|maxLengt|minimum|maximum)'
    """
    バリデーションルール: 値の許容範囲/制限
    """
