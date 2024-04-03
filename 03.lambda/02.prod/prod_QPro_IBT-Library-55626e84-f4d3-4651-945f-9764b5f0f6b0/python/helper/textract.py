from .aws_client import create_client
from constant import Environment
from exception import TextractException
from typing import Self

class Textract():
    """
    Textract操作用のクラス
    """

    _textract_client = None
    """
    Textractのクライアント
    """

    _instance: Self = None
    """
    インスタンス管理用変数 (Singleton)
    """

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
        self._textract_client = self._create_textract_client()

    def _create_textract_client(self):
        """
        TextractのBotoクライアントを作成
        """
        if self._textract_client is None:
            region_name = Environment.get_str(Environment.TEXTRACT_REGION)
            kwargs = { 'region_name': region_name }
            self._textract_client = create_client('textract', kwargs)

        return self._textract_client

    def detect_text_s3_object(self, bucket:str, key:str) -> dict:
        """
        TextractのOCR処理を呼出す

        Returns:
            dict: OCRの結果をdict型で返却
        """
        try:
            # Textractクライアントの作成
            client_textract = self._create_textract_client()

            # Textract呼出し
            return client_textract.detect_document_text(
                Document = {
                    'S3Object': {
                        'Bucket': bucket,
                        'Name': key
                    }
                }
            )
        
        except Exception as err:
            raise TextractException(original = err)
        
    def detect_text_byte(self, byte: bytes) -> dict:
        """
        TextractのOCR処理を呼出す

        Returns:
            dict: OCRの結果をdict型で返却
        """
        try:
            # Textractクライアントの作成
            client_textract = self._create_textract_client()

            # Textract呼出し
            return client_textract.detect_document_text(
                Document = {
                    'Bytes': byte
                }
            )
        
        except Exception as err:
            raise TextractException(original = err)