from sqlalchemy.schema import Column
from sqlalchemy.types import BIGINT, String
from .mixincolumn import MixinColumn
from .base import Base

class MInspection(Base, MixinColumn):
    __tablename__ = "TBL_M_INSPECTION"

    # 点検名ID
    inspection_name_id = Column('inspection_name_id', BIGINT, primary_key = True, autoincrement = True)
    # 点検名
    inspection_name = Column('inspection_name', String(25), nullable = False)

    def to_dict(self) -> dict:
        """
        クラスの情報をKVS(dict型)に変換する
        """
        return {
            'inspectionId': self.inspection_name_id,
            'inspectionName': self.inspection_name,
        }