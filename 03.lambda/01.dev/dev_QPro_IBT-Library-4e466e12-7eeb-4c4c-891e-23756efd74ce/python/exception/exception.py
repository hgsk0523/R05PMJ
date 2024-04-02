from constant.aws_service import AwsService

class MyBaseException(Exception):
    """
    システムの独自例外のベースとなるクラス
    独自例外をまとめてキャッチしたい場合に使用する
    """
    _type: AwsService

    def __init__(self, original: Exception, *args, **kwargs):
        super(MyBaseException, self).__init__(original, *args, **kwargs)
        self.original = original


class RDSException(MyBaseException):
    """
    RDS処理時に発生した例外を内包する例外クラス
    original に発生した例外情報を格納
    """
    _type = AwsService.RDS

class SQSException(MyBaseException):
    """
    SQS処理時に発生した例外を内包する例外クラス
    original に発生した例外情報を格納
    """
    _type = AwsService.SQS

class S3Exception(MyBaseException):
    """
    S3処理時に発生した例外を内包する例外クラス
    original に発生した例外情報を格納
    """
    _type = AwsService.S3

class TextractException(MyBaseException):
    """
    Textract処理時に発生した例外を内包する例外クラス
    original に発生した例外情報を格納
    """
    _type = AwsService.TEXTRACT

class APIException(MyBaseException):
    """
    API呼出処理時に発生した例外を内包する例外クラス
    original に発生した例外情報を格納
    """
    _type = None

class NotFoundEnvironmentVariableException(MyBaseException):
    """
    環境変数取得時に発生した例外を内包する例外クラス
    original に発生した例外情報を格納
    """
    _type = None