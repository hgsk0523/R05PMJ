import re
from aws_lambda_powertools import Logger
from .aws_client import create_client
from exception import S3Exception
from typing import Self
from constant import Message

class S3():
    """
    S3操作を行うクラス
    """

    # S3クライアントを格納
    _s3_client = None

    # インスタンス管理用変数 (Singleton)
    _instance: Self = None

    # ロガークラス
    _logger: Logger = None

    def __new__(cls, logger: Logger) -> Self:
        """
        Singletonパターン用のコンストラクタ定義
        """
        if cls._instance is None:
            cls._instance = super().__new__(cls)

        return cls._instance
    
    def __init__(self, logger: Logger):
        """
        クラスメンバの初期化処理(コンストラクタ)
        """
        self._s3_client = self._get_s3_client()
        self._logger = logger

    def _get_s3_client(self):
        """
        S3のBotoクライアントを作成
        """
        if self._s3_client is None:
            self._s3_client = create_client('s3')

        return self._s3_client

    def copy_object(self, bucket: str, key: str, dest: str) -> str:
        """
        S3のオブジェクトをリネームする

        Returns:
            new_name: リネーム後の新しい名前
        """

        try:
            copy_source = {
                "Bucket": bucket,
                "Key": key
            }

            # S3クライアントの作成
            s3 = self._get_s3_client()
            # 対象ファイルのコピー(リネームコピー)
            s3.copy(copy_source, bucket, dest)

            return f'{bucket}/{dest}'
        
        except Exception as err:
            self._logger.error(Message.get_message(
                Message.ERR_OCCRRED_S3_OBJECT_OPERATION_EXCEPTION,
                '複製', f'Source= {bucket}/{key}, Destination= {bucket}/{dest}'
            ))
            raise S3Exception(original = err)
        
    def delete_object(self, bucket: str, key: str) -> None:
        """
        指定されたオブジェクトの削除
        """
        try:
            s3 = self._get_s3_client()

            # オブジェクトの削除
            s3.delete_object(Bucket = bucket, Key = key)

        except Exception as err:
            self._logger.error(Message.get_message(
                Message.ERR_OCCRRED_S3_OBJECT_OPERATION_EXCEPTION,
                '削除', f'{bucket}/{key}'
            ))
            raise S3Exception(original = err)

    def get_object(self, bucket: str, key: str):
        """
        指定されたオブジェクトの取得
        """
        try:
            s3 = self._get_s3_client()

            # オブジェクト取得
            res = s3.get_object(Bucket = bucket, Key = key)

            return res['Body']
        
        except Exception as err:
            self._logger.error(Message.get_message(
                Message.ERR_OCCRRED_S3_OBJECT_OPERATION_EXCEPTION,
                '取得', f'{bucket}/{key}'
            ))
            raise S3Exception(original = err)

    @staticmethod
    def split_path(s: str) -> dict:
        """
        S3の画像ファイルのPathから各種情報を取得する
        
        Returs:
            dict: Pathから取得した情報のKVS
        """

        splited: list[str] = re.split(r'[/_\.]', s)

        if len(splited) >= 6:
            return {
                'company_code': splited[0],
                'base_code': splited[1],
                'inspection_date': splited[2],
                'worksheet_code': splited[3],
                'taken_at': splited[4],
                'item_name': splited[5],
            }

        else:
            raise IndexError(f's3 path splited list index out of range. path: {s}')
        
    @staticmethod
    def split_bucket_path(image_path: str) -> tuple[str, str] | None:
        """
        画像のパスを bucket と path に分割する
        分割に失敗した場合は None を返す

        Returns:
            tuple(bucket, path)
            bucket: バケット名
            path: バケット内のPath
        """

        # 最初の '/' で文字列を分割
        split = image_path.partition('/')

        if len(split[1]) != 0:
            return (split[0], split[2])
        
        else:
            return None
    
