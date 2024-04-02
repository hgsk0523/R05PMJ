import boto3
from constant import Environment
from botocore.config import Config

def _get_config() -> Config:
    """
    リトライ処理をカスタマイズしたConfigを作成する
    """

    # 接続タイムアウト値
    connect_timeout = Environment.get_int(Environment.BOTO_CONN_TIMEOUT_SEC)
    # 最大リトライ回数
    max_attempts = Environment.get_int(Environment.BOTO_MAX_RETRY_COUNT)

    return Config(
        connect_timeout = connect_timeout,
        retries = {
            'max_attempts': max_attempts,
            'mode': 'standard'
        }
    )

def create_client(service_name: str, kwargs: dict = None):
    """
    リトライ処理をカスタマイズしたBoto3のクライアントを返却する
    """
    if kwargs is None:
        return boto3.client(service_name, config = _get_config())
    
    return boto3.client(service_name, config = _get_config(), **kwargs)