from sqlalchemy.schema import Column, Index
from sqlalchemy.types import BIGINT, String
from .mixincolumn import MixinColumn
from .base import Base

class MLabel(Base, MixinColumn):
    __tablename__ = "TBL_M_LABEL"

    __table_args__ = (
        (Index('idx_m_label_01', 'item_name_id')),
    )

    # ラベルID
    label_id = Column('label_id', BIGINT, primary_key = True, autoincrement = True)
    # 項目名
    item_name_id = Column('item_name_id', BIGINT, nullable = False)
    # ラベル
    label = Column('label', String(30), nullable = False)

    def to_dict(self) -> dict:
        """
        クラスの情報をKVS(dict型)に変換する
        """
        return {
            'labelId': self.label_id,
            'itemNameId': self.item_name_id,
            'label': self.label,
        }