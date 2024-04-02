from enum import Enum, unique

@unique
class ResultCode(Enum):
    """
    Response Statusを管理するクラス
    """

    def __init__(self, response_status: int, result_code: int, message: str):
        """
        コンストラクタ
        """
        self.response_status = response_status
        self.result_code = result_code
        self.message = message

    SUCCESS_20000 = (200, 20000, '正常終了')
    """
    正常終了の結果コード

    Returns:
        .response_code: 200
        .result_code: 20000
        .message: '正常終了'
    """

    SUCCESS_20001 = (200, 20001, '処理対象レコードなし')
    """
    処理対象レコードなしの結果コード

    Returns:
        .response_code: 200
        .result_code: 20001
        .message: '処理対象レコードなし'
    """

    BAD_REQUEST_40000 = (400, 40000, '必須項目が含まれていません')
    """
    必須項目不足の結果コード

    Returns:
        .response_code: 400
        .result_code: 40000
        .message: '必須項目が含まれていません'
    """

    BAD_REQUEST_40001 = (400, 40001, 'パラメータの型に誤りがあります')
    """
    パラメータ型の不備の結果コード

    Returns:
        .response_code: 400
        .result_code: 40001
        .message: 'パラメータの型に誤りがあります'
    """

    BAD_REQUEST_40002 = (400, 40002, 'パラメータの値に誤りがあります')
    """
    パラメータ型の不備の結果コード

    Returns:
        .response_code: 400
        .result_code: 40002
        .message: 'パラメータの値に誤りがあります'
    """

    INTERNAL_ERROR_50000 = (500, 50000, 'DB接続エラーが発生しました')
    """
    DB接続エラーの結果コード

    Returns:
        .response_code: 500
        .result_code: 50000
        .message: 'DB接続エラーが発生しました'
    """

    INTERNAL_ERROR_50001 = (500, 50001, 'SQS接続エラーが発生しました')
    """
    SQS接続エラーの結果コード

    Returns:
        .response_code: 500
        .result_code: 50001
        .message: 'SQS接続エラーが発生しました'
    """

    INTERNAL_ERROR_50002 = (500, 50002, 'S3接続でエラーが発生しました')
    """
    S3接続エラーの結果コード

    Returns:
        .response_code: 500
        .result_code: 50002
        .message: 'S3接続でエラーが発生しました'
    """

    INTERNAL_ERROR_50003 = (500, 50003, '外部API接続でエラーが発生しました')
    """
    外部API接続エラーの結果コード

    Returns:
        .response_code: 500
        .result_code: 50003
        .message: '外部API接続でエラーが発生しました'
    """

    INTERNAL_ERROR_50004 = (500, 50004, '予期せぬエラーが発生しました')
    """
    予期せぬエラーの結果コード

    Returns:
        .response_code: 500
        .result_code: 50004
        .message: '予期せぬエラーが発生しました'
    """