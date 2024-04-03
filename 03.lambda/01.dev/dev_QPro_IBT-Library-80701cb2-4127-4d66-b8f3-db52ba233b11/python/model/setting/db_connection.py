from sqlalchemy import create_engine, Engine, NullPool
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.exc import SQLAlchemyError
from contextlib import contextmanager
from helper import HTTP
from typing import Self
from urllib.parse import quote
from constant import Environment, DatabaseAccessPoint
from exception import RDSException
from .routing_session import RoutingSession

class DatabaseConnection(object):
    """
    DBのコネクションを作成するクラス
    """

    # インスタンス管理用変数 (Singleton)
    _instance: Self = None

    # セッション管理用変数
    _session: Session = None

    def __new__(cls) -> Self:
        """
        Singletonパターン用のコンストラクタ定義
        """
        if cls._instance is None:
            cls._instance = super().__new__(cls)

        return cls._instance

    @staticmethod
    def _get_db_info(env_secret_name: Environment) -> str:
        """
        DBの接続情報を取得するメソッド\n
        
        Returns:
            str: DB接続文字列
        """
        # Secrets Managerにアクセスする際に必要となる情報を取得
        secret_name = Environment.get_str(env_secret_name)
        session_token = Environment.get_str(Environment.AWS_SESSION_TOKEN)
        secret_port = Environment.get_str(Environment.PARAMETERS_SECRETS_EXTENSION_HTTP_PORT)

        # Secretの取得
        secrets = HTTP.get_secret(secret_name, session_token, secret_port)

        # 認証情報の取得
        user = secrets['username']
        pswd = quote(secrets['password'], safe="")
        host = secrets['host']
        port = secrets['port']
        database = secrets['database']
        program_name = Environment.get_str(Environment.AWS_LAMBDA_FUNCTION_NAME)

        return f'mysql+pymysql://{user}:{pswd}@{host}:{port}/{database}?charset=utf8mb4&program_name={program_name}'

    # DB Engine
    @classmethod
    def _get_engine(cls, access_point: DatabaseAccessPoint) -> Engine:
        """
        DB Engineを作成するメソッド\n

        Returns:
            Engine: DB Engine クラス (接続情報含む)
        """

        # 接続文字列を格納する定数
        connection_str = cls._get_db_info(access_point.env)
        # Connection Pool Size
        pool_size = Environment.get_int(Environment.DB_CONN_POOL_SIZE)
        # 高負荷時の追加Connection Pool Size
        max_overflow = Environment.get_int(Environment.DB_CONN_POOL_MAX_OVERFLOW_SIZE)
        # Pool内のConnection維持期間
        pool_recycle_sec = Environment.get_int(Environment.DB_CONN_POOL_RECYCLE_TIME_SEC)
        # Pool内からConnectionを取得時の最大待ち時間
        pool_timeout_sec = Environment.get_int(Environment.DB_CONN_POOL_TIMEOUT_SEC)
        # 実行クエリを出力フラグ
        is_echo = Environment.get_bool(Environment.IS_DEBUG)
        # クエリパラメータを出力しないフラグ
        is_hide_parameters = Environment.get_bool(Environment.IS_HIDE_DB_QUERY_PARAMETERS)

        # DBエンジンの設定情報
        conf: dict = {
            'url': connection_str,
            # 'poolclass': NullPool,   # ConnectionPoolを無効化する
            'pool_size': pool_size,
            'max_overflow': max_overflow,
            'pool_recycle': pool_recycle_sec,
            'pool_timeout': pool_timeout_sec,
            'echo': is_echo,
            'hide_parameters': is_hide_parameters,
            'logging_name': access_point.key,
        }

        # DB接続エンジンの作成
        return create_engine(**conf)

    @classmethod
    def _create_single_engine_session(cls) -> Session:
        """
        接続先が単一のSessionを作成
        """
        # コネクションの設定
        conf = {
            'bind': cls._get_engine(DatabaseAccessPoint.SINGLE_ACCESS_POINT),
            'autocommit': False,    # autoCommitを無効化
            'autoflush': False      # autoFlushを無効化
        }

        # セッションの作成
        sm = sessionmaker(**conf)
        return sm()

    @classmethod
    def _create_multi_engine_session(cls) -> Session:
        """
        接続先が複数のSessionを作成
        """
        # 複数エンジンの作成
        engines = {}
        # Writer Endpointの登録
        engines.setdefault('source', cls._get_engine(DatabaseAccessPoint.MULTI_ACCESS_POINT_WRITER))
        # Reader Endpointの登録
        engines.setdefault('replica', cls._get_engine(DatabaseAccessPoint.MULTI_ACCESS_POINT_READER))
        # クラス変数に登録
        RoutingSession.engines = engines

        # 複数セッションを扱う場合
        conf = {
            'autocommit': False,    # autoCommitを無効化
            'autoflush': False,      # autoFlushを無効化
            'class_': RoutingSession,
        }

        # セッションの作成
        sm = sessionmaker(**conf)
        return sm()

    @classmethod
    def _get_session(cls) -> Session:
        """
        セッションを作成する関数
        """
        if cls._session is None:
            cls._session = cls._create_single_engine_session()

        return cls._session

    @classmethod
    @contextmanager
    def begin(cls):
        """
        トランザクションありでSQLを実行
        """

        # セッションの取得
        session = cls._get_session()

        try:
            # session 開始
            session.begin()

            # 内部処理完了待ち
            yield session

            # session コミット
            session.commit()

        except SQLAlchemyError as err:
            # session ロールバック
            session.rollback()
            raise RDSException(original = err)

        except Exception as err:
            # session ロールバック
            session.rollback()
            raise err

        finally:
            # session クローズ
            session.close()