from datetime import datetime, date
import json

class JsonConverter():
    """
    JSONシリアル化処理を行うクラス
    """
    
    @staticmethod
    def _custom_json_serializer(obj):
        """
        JSONに変換する際のデータ型に応じた変換処理を定義する

        Returns:
            Any: 入力されたデータ型に応じた型を返却する(list or str)
        """
        if hasattr(obj, '__iter__'):
            # イテレーターを持つobjはリストに変換
            return list(obj)
        elif isinstance(obj, datetime):
            # 日時型は ISO 形式に変換
            return obj.isoformat(sep = 'T', timespec = 'milliseconds')
        elif isinstance(obj, date):
            # 
            return obj.isoformat()
        else:
            # それ以外は文字列に
            return str(obj)
    
    @classmethod
    def json_dump(cls, kvs: dict, indent: int = None) -> str:
        """
        辞書型(dict)をJSON文字列に変換する関数

        Returns:
            str: JSON文字列
        """

        # 変換設定
        conf = {
            'obj': kvs,
            'ensure_ascii': False,
            'indent': indent,
            'default': cls._custom_json_serializer,
            'sort_keys': True,
        }

        return json.dumps(**conf)

    @staticmethod
    def json_loads(json_txt: str) -> dict:
        """
        JSON文字列をDict型に変換する
        """
        return json.loads(json_txt)