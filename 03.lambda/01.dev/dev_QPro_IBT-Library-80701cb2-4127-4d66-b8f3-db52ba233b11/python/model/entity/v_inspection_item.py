from sqlalchemy.schema import Column
from sqlalchemy.types import BIGINT, String
from sqlalchemy.dialects.mysql import TINYINT
from .base import Base
from constant import (
    ShootType
)

class VInspectionItem(Base):
    __tablename__ = "VIW_V_INSPECTION_ITEM"

    # 点検項目ID
    inspection_item_id = Column('inspection_item_id', BIGINT, primary_key=True)
    # 点検ID
    inspection_id = Column('inspection_id', BIGINT)
    # 項目名
    item_name = Column('item_name', String(16))
    # 撮影日時
    taken_dt = Column('taken_dt', String(12))
    # 画像ファイルパス
    image_path = Column('s3_image_path', String(300))
    # 判定結果
    ai_result = Column('ai_result', TINYINT)
    # NGコメント
    ng_comment = Column('ng_comment', String(50))
    # 品番
    model = Column('model', String(20))
    # 製造番号
    serial_number = Column('serial_number', String(12))
    # 写真種別
    shoot_type = Column('shoot_type', TINYINT)


    def to_dict(self) -> dict:
        """
        クラスの情報をKVS(dict型)に変換する
        """
        return {
            'SHOOTNO': self.inspection_item_id,
            'SHOOTYPE': self.shoot_type,
            'SHOOTNM': self.item_name,
            'SHOOTDATE': int(self.taken_dt) if self.taken_dt else None,
            'JUDGEKB': self.ai_result,
            'IMG': None,
            'HININCOMMENT': self.ng_comment,
            'KATASIKI': self.model,
            'SEIZOUNO': self.serial_number,
        }