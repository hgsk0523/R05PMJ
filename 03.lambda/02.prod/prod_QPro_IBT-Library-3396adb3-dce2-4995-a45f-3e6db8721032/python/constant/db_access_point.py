from enum import Enum, unique
from .environment import Environment

@unique
class DatabaseAccessPoint(Enum):
    """
    DBの接続先を管理する定数クラス
    """

    def __init__(self, key: str, env: Environment):
        """
        コンストラクタ
        """
        self.key = key
        self.env = env

    SINGLE_ACCESS_POINT = ('single', Environment.SECRET_NAME_DB)
    """
    リードレプリカを使用しない場合のEndpoint用の接続定数
    """

    MULTI_ACCESS_POINT_WRITER = ('source', Environment.SECRET_NAME_SOURCE_DB)
    """
    RDSのWriter Endpoint用の接続定数
    """

    MULTI_ACCESS_POINT_READER = ('replica', Environment.SECRET_NAME_REPLICA_DB)
    """
    RDSのReader Endpoint用の接続定数
    """