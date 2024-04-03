from requests import Response, Session
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from .json_converter import JsonConverter
from exception import APIException
from constant import Environment
from time import sleep

class HTTP():
    """
    HTTP Requestを操作するクラス
    """
    
    @staticmethod
    def _timeout_conf() -> tuple[float, float]:
        """
        HTTPリクエストのタイムアウト設定

        Returns:
            tuple: ( ConnectTimeout, ReadTimeout )
            ConnectTimeout: 環境変数 HTTP_CONN_TIMEOUT で設定 (未設定は3秒)
            ReadTimeout: 環境変数 HTTP_READ_TIMEOUT で設定 (未設定は10秒)
        """
        conn_timeout = Environment.get_float(Environment.HTTP_CONN_TIMEOUT_SEC)
        read_timeout = Environment.get_float(Environment.HTTP_READ_TIMEOUT_SEC)

        return (conn_timeout, read_timeout)
    
    @staticmethod
    def _retry_conf() -> Retry:
        """
        HTTPリクエストのリトライ設定

        Returns:
            Retry: リトライ設定
                total: 環境変数 HTTP_MAX_RETRY_COUNT で設定 (未設定は3回)
                backoff_factor: リトライ実行までの待機時間を設定 [秒]
                status_forcelist: リトライを行うレスポンスステータス値
        """
        return Retry(
                total = Environment.get_int(Environment.HTTP_MAX_RETRY_COUNT),
                backoff_factor = 1,
                status_forcelist = [429, 500, 502, 503, 504]
            )

    @staticmethod
    def create_header() -> dict:
        """
        Request Headerを作成する関数
        """
        return {
            'content-type': 'application/json'
        }

    @classmethod
    def _get_session(cls) -> Session:
        """
        HTTP Request用のセッションを作成する
        """
        session = Session()

        # リトライ設定の対象となるプロトコルを指定
        session.mount('http://', HTTPAdapter(max_retries = cls._retry_conf()))
        session.mount('https://', HTTPAdapter(max_retries = cls._retry_conf()))

        return session

    @classmethod
    def send_post(cls, url: str, body: dict, header: dict) -> Response:
        """
        HTTPのPOSTリクエストを送信する

        Returns:
            Response: APIからのレスポンス情報
        """
        session = cls._get_session()
        
        try:
            return session.post(url = url, data = body, headers = header, timeout = cls._timeout_conf())

        except Exception as err:
            raise APIException(original = err)
            
    @classmethod
    def send_form_post(cls, url: str, body: dict, file: dict, header: dict) -> Response:
        """
        HTTPのPOSTリクエストを送信する

        Returns:
            Response: APIからのレスポンス情報
        """
        session = cls._get_session()
        
        try:
            return session.post(url = url, data = body, headers = header, files = file, timeout = cls._timeout_conf())

        except Exception as err:
            raise APIException(original = err)

    @classmethod
    def send_get(cls, url: str, param: dict, header: dict) -> Response:
        """
        HTTPのGETリクエストを送信する

        Returns:
            Response: APIからのレスポンス情報
        """
        session = cls._get_session()

        try:
            return session.get(url = url, params = param, headers = header, timeout = cls._timeout_conf())
        
        except Exception as err:
            raise APIException(original = err)
    
    @staticmethod
    def to_dict(res: Response) -> dict:
        return {
            'statusCode': res.status_code,
            'header': res.headers,
            'body': res.text
        }

    @classmethod
    def get_secret(cls, secret_id: str, session_token: str, port: str = '2773') -> dict:
        """
        Lambda拡張機能のSecrets Managerアクセスを呼び出す
        AWS Parameters and Secrets Lambda Extension のレイヤーが設定されている場合のみ使用可能

        Returns:
            dict: SecretManagerから返却された情報
        """
        # レスポンスの定義
        header = {"X-Aws-Parameters-Secrets-Token": session_token}
        # クエリパラメータ
        param = {"secretId": secret_id}
        # エンドポイントの定義
        url = f"http://localhost:{port}/secretsmanager/get"
        # リトライ回数の定義
        retry = Environment.get_int(Environment.HTTP_MAX_RETRY_COUNT)

        # Secrets Managerにアクセス
        return cls.get_secret_value(url, param, header, retry)

    @classmethod
    def get_secret_value(cls, url: str, param: dict, header: dict, retry: int) -> dict:
        """
        Secrets Managerの値を取得する関数
        400エラー (not ready to serve traffic, please wait.)の場合は、リトライする
        """
        # 情報の取得
        res = cls.send_get(url, param, header)

        # 200:OK のとき
        if res.status_code == 200:
            secret = JsonConverter.json_loads(res.text)["SecretString"]
            return JsonConverter.json_loads(secret)
        
        # 400:BadRequest かつ retryがゼロより大きいとき
        elif res.status_code == 400 and retry > 0:
            # 1秒待って再帰処理を開始
            sleep(1.0)
            return cls.get_secret_value(url, param, header, retry - 1)

        # その他のとき
        else:
            raise APIException(original = HTTP.to_dict(res))