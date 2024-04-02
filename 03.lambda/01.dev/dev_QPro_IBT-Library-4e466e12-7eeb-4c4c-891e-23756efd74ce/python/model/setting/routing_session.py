from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session
from sqlalchemy.sql import Update, Delete
from typing import Self

class RoutingSession(Session):
    """
    複数のDBへの接続エンジンを管理するクラス
    更新系、参照系に合わせて使用する接続エンジンを切り替える
    """

    engines = {}
    """
    接続エンジンを管理するクラス変数
    """

    _name = None
    """
    現在の接続先エンジン名
    """

    _is_updated = False
    """
    更新処理フラグ
    """

    @classmethod
    def get_engine(cls, name) -> Engine:
        """
        指定されたエンジンを取得する
        """
        return cls.engines[name]

    def is_flushing(self) -> bool:
        """
        更新処理の有無を判定する関数
        """
        return self._is_updated

    def get_bind(self, mapper = None, clause = None) -> Engine:
        """
        Sessionの同名関数をオーバーライドする関数
        接続エンジンの切り替えを行う
        """
        if self._name is not None:
            # 接続先を明示的に指定された場合
            return self.get_engine(self._name)
        
        elif self._flushing or isinstance(clause, (Update, Delete)):
            # 更新系SQLの場合
            self._is_updated = True
            return self.get_engine('source')
        
        else:
            # その他の場合
            return self.get_engine('replica')

    def set_bind(self, name: str) -> Self:
        """
        接続先エンジンを指定する関数
        """
        session = RoutingSession()
        vars(session).update(vars(self))
        session._name = name
        return session