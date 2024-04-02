from enum import Enum, unique
from exception import NotFoundEnvironmentVariableException
from distutils.util import strtobool
from typing import Self
import os


@unique
class Environment(Enum):
    """
    環境変数管理用のクラス
    """

    def __init__(self, key: str, default):
        """
        コンストラクタ
        """
        self.key = key
        self.default = default

    @staticmethod
    def _get_val(env: Self):
        """
        環境変数から設定値を取得する関数
        """
        try:
            if env.default is None:
                return os.environ[env.key]
            
            else:
                return os.environ.get(env.key, env.default)
        
        except Exception as err:
            raise NotFoundEnvironmentVariableException(original = err)

    @staticmethod
    def get_bool(env: Self) -> bool:
        """
        環境変数の値をbool型で取得
        """
        return strtobool(Environment._get_val(env))
    
    @staticmethod
    def get_str(env: Self) -> str:
        """
        環境変数の値をstr型で取得
        """
        return str(Environment._get_val(env))
    
    @staticmethod
    def get_int(env: Self) -> int:
        """
        環境変数の値をint型で取得
        """
        return int(Environment._get_val(env))
    
    @staticmethod
    def get_float(env: Self) -> float:
        """
        環境変数の値をfloat型で取得
        """
        return float(Environment._get_val(env))


    # ============================
    #  環境変数定義
    # ============================

    # ---- 共通パラメーター ----

    IS_DEBUG = ('IS_DEBUG', 'false')
    """
    Debug用の詳細情報出力用の値 (Debug用のため初期値: 'false')
    """

    AWS_LAMBDA_FUNCTION_NAME = ('AWS_LAMBDA_FUNCTION_NAME', None)
    """
    現在実行中のLambda関数名 (AWSが定義)
    """

    AWS_SESSION_TOKEN = ('AWS_SESSION_TOKEN', None)
    """
    IAM ROLEに割り当てられているセッショントークン値 (AWSが定義)
    """


    # ---- SQS関連パラメーター ----

    SQS_MESSAGE_GROUP_ID = ('SQS_MESSAGE_GROUP_ID', None)
    """
    FIFO SQS QUEUE用のメッセージグループID
    """

    SQS_ENDPOINT_URL = ('SQS_ENDPOINT_URL', 'https://sqs.ap-northeast-1.amazonaws.com')
    """
    SQSのEndPointURL (初期値: )
    """

    OCR_QUEUE_URL = ('OCR_QUEUE_URL', None)
    """
    OCR用のSQS QUEUEのURL
    """

    AI_QUEUE_URL = ('AI_QUEUE_URL', None)
    """
    AI解析用のSQS QUEUEのURL
    """


    # ---- AI解析サーバ関連パラメーター ----

    TEXTRACT_REGION = ('TEXTRACT_REGION', None)
    """
    Textractを使用する際のリージョン
    """


    # ---- AI解析サーバ関連パラメーター ----

    AI_API_URL = ('AI_API_URL', None)
    """
    AI呼出APIのURL
    """

    AI_API_AUTHENTICATION = ('AI_API_AUTHENTICATION', None)
    """
    AI呼出APIの認証情報
    """

    AI_API_MASTER_IMAGE = ('AI_API_MASTER_IMAGE', None)
    """
    AI呼出時に指定するマスター画像の名前
    """


    # ---- Secrets Manager関連パラメーター ----

    SECRET_NAME_DB = ('SECRET_NAME_DB', None)
    """
    Secrets Managerで管理されているDB接続情報のID値
    """

    SECRET_NAME_SOURCE_DB = ('SECRET_NAME_SOURCE_DB', None)
    """
    Secrets Managerで管理されているSource DBへの接続情報のID値
    """

    SECRET_NAME_REPLICA_DB = ('SECRET_NAME_REPLICA_DB', None)
    """
    Secrets Managerで管理されているReplica DBへの接続情報のID値
    """

    PARAMETERS_SECRETS_EXTENSION_HTTP_PORT = ('PARAMETERS_SECRETS_EXTENSION_HTTP_PORT', '2773')
    """
    Secrets Manager接続時に使用するポート番号 (初期値: 2773)
    """


    # ---- HTTP Request関連パラメーター ----

    HTTP_CONN_TIMEOUT_SEC = ('HTTP_CONN_TIMEOUT_SEC', 3)
    """
    HTTP Connection Timeoutの値 (初期値: 3秒)
    """

    HTTP_READ_TIMEOUT_SEC = ('HTTP_READ_TIMEOUT_SEC', 10)
    """
    HTTP Response Timeoutの値 (初期値: 10秒)
    """

    HTTP_MAX_RETRY_COUNT = ('HTTP_MAX_RETRY_COUNT', 3)
    """
    HTTP Requestのリトライ回数 (初期値: 3回)
    """


    # ---- DB Connection Pool関連パラメーター ----

    DB_CONN_POOL_SIZE = ('DB_POOL_SIZE', 1)
    """
    DB Connection Poolのサイズ (初期値: 1)
    """
    
    DB_CONN_POOL_MAX_OVERFLOW_SIZE = ('DB_CONN_POOL_MAX_OVERFLOW_SIZE', 0)
    """
    DB Connection Poolが最大に達した場合に、追加で確保するPoolのサイズ (初期値: 0)
    """

    DB_CONN_POOL_RECYCLE_TIME_SEC = ('DB_POOL_RECYCLE_TIME_SEC', 60)
    """
    DB Connection Poolの接続リサイクル時間 (初期値: 60秒)
    """

    DB_CONN_POOL_TIMEOUT_SEC = ('DB_CONN_POOL_TIMEOUT_SEC', 10)
    """
    DB Connection Poolから接続取得時に待つ時間 (初期値: 10秒)
    """

    IS_HIDE_DB_QUERY_PARAMETERS = ('IS_HIDE_DB_QUERY_PARAMETERS', 'true')
    """
    SQLのQuery Parameterをログに出力しないための値 (初期値: true)
    """


    # ---- Boto3関連パラメーター ----

    BOTO_CONN_TIMEOUT_SEC = ('BOTO_CONN_TIMEOUT_SEC', 5)
    """
    Boto Clientの接続タイムアウト値 (初期値: 5秒)
    """

    BOTO_MAX_RETRY_COUNT = ('BOTO_MAX_RETRY_COUNT', 3)
    """
    Boto Clientの処理リトライ回数 (初期値: 3回)
    """