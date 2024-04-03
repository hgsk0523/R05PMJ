from sqlalchemy.schema import Column
from sqlalchemy.types import BIGINT, String
from sqlalchemy.dialects.mysql import TINYINT
from .mixincolumn import MixinColumn
from .base import Base

class MInspectionItem(Base, MixinColumn):
    __tablename__ = "TBL_M_INSPECTION_ITEM"

    # 点検項目名ID
    item_name_id = Column('item_name_id', BIGINT, primary_key = True, autoincrement = True)
    # 点検名ID
    inspection_name_id = Column('inspection_name_id', BIGINT, nullable = False)
    # 項目名
    item_name = Column('item_name', String(16), nullable = False)
    # 解析種別
    analysis_type = Column('analysis_type', TINYINT, nullable = False)
    # 画像解析URL
    api_url = Column('api_url', String(200))
    # マスター画像名
    master_image = Column('master_image', String(40))
    # 認証トークン
    auth_token = Column('auth_token', String(100))
    # 写真種別
    shoot_type = Column('shoot_type', TINYINT)


    def to_dict(self) -> dict:
        """
        クラスの情報をKVS(dict型)に変換する
        """
        return {
            'itemNameId': self.item_name_id,
            'inspectionNameId': self.inspection_name_id,
            'itemName': self.item_name,
            'analysisType': self.analysis_type,
            'apiUrl': self.api_url,
            'masterImage': self.master_image,
            'authToken': self.auth_token,
            'shootType': self.shoot_type
        }