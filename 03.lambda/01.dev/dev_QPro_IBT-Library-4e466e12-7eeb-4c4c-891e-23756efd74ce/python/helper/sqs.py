from .aws_client import create_client
from exception import SQSException
from typing import Self
from constant import Environment
import uuid

class SQS():
    """
    SQS操作用のクラス
    """

    # SQSクライアントを格納
    _sqs_client = None

    # インスタンス管理用変数 (Singleton)
    _instance: Self = None

    def __new__(cls) -> Self:
        """
        Singletonパターン用のコンストラクタ定義
        """
        if cls._instance is None:
            cls._instance = super().__new__(cls)

        return cls._instance
    
    def __init__(self):
        """
        クラスメンバの初期化処理(コンストラクタ)
        """
        self._sqs_client = self._get_sqs_client()

    def _get_sqs_client(self):
        """
        SQSのBotoクライアントを作成
        """
        if self._sqs_client is None:
            endpoint_url = Environment.get_str(Environment.SQS_ENDPOINT_URL)
            kwargs = { 'endpoint_url': endpoint_url }
            self._sqs_client = create_client('sqs', kwargs)

        return self._sqs_client

    def send_message(self, queue_url: str, message: str):
        """
        SQSにメッセージを送信する
        """
        try:
            # SQSクライアントの作成
            sqs = self._get_sqs_client()

            # メッセージの送信
            sqs.send_message(
                QueueUrl = queue_url,
                MessageBody = message,
                MessageGroupId = Environment.get_str(Environment.SQS_MESSAGE_GROUP_ID),
                MessageDeduplicationId = str(uuid.uuid4())
            )

        except Exception as err:
            raise SQSException(original = err)