from sqlalchemy import Column, BIGINT, text
from sqlalchemy.dialects.mysql import DATETIME
from sqlalchemy.ext.declarative import declared_attr

class MixinColumn(object):
    """
    テーブルに共通で持つ列定義を作成するMixInクラス
    """

    @declared_attr
    def created_at(cls):
        """
        作成日時列の定義
        """
        return Column(
            'mak_dt',
            DATETIME(fsp = 3), 
            server_default = text('CURRENT_TIMESTAMP(3)'),
            nullable = False
        )
    
    @declared_attr
    def updated_at(cls):
        """
        更新日時列の定義
        """
        return Column(
            'ren_dt',
            DATETIME(fsp = 3), 
            server_default = text('CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)'), 
            nullable = False
        )
    
    @declared_attr
    def version(cls):
        """
        バージョン番号列の定義
        ※楽観的排他制御用の列
        """
        return Column(
            'version',
            BIGINT, 
            nullable = False
        )
    
    # 楽観的排他制御の列を指定
    __mapper_args__ = {'version_id_col': version}