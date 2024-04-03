from sqlalchemy.schema import Column, UniqueConstraint
from sqlalchemy.types import BIGINT, String
from sqlalchemy.dialects.mysql import TINYINT
from sqlalchemy.dialects.mysql import DATETIME
from .mixincolumn import MixinColumn
from .base import Base

class TInspectionItem(Base, MixinColumn):
    __tablename__ = "TBL_T_INSPECTION_ITEM"

    __table_args__ = (
        (UniqueConstraint('inspection_id', 'item_name_id', name = 'uni_idx_t_inspection_item_01')),
        (UniqueConstraint('inspection_id', 'item_name', name = 'uni_idx_t_inspection_item_02')),
    )

    # 点検項目ID
    inspection_item_id = Column('inspection_item_id', BIGINT, primary_key = True, autoincrement = True)
    # 点検ID
    inspection_id = Column('inspection_id', BIGINT, nullable = False)
    # 項目名ID
    item_name_id = Column('item_name_id', BIGINT)
    # 項目名
    item_name = Column('item_name', String(16))
    # 撮影日時
    taken_dt = Column('taken_dt', DATETIME)
    # 画像ファイルパス
    image_path = Column('s3_image_path', String(300))
    # 判定結果
    ai_result = Column('ai_result', String(4))
    # NGコメント
    ng_comment = Column('ng_comment', String(50))
    # 品番
    model = Column('model', String(20))
    # 製造番号
    serial_number = Column('serial_number', String(12))
    # 編集済み品番
    edited_model = Column('edited_model', String(20))
    # 編集済み製造番号
    edited_serial_number = Column('edited_serial_number', String(12))
    # 進捗状況
    progress = Column('progress', TINYINT, nullable = False)

    def to_dict(self) -> dict:
        """
        クラスの情報をKVS(dict型)に変換する
        """
        return {
            'inspectionItemId': self.inspection_item_id,
            'inspectionId': self.inspection_id,
            'inspectionItemNameId': self.item_name_id,
            'itemName': self.item_name,
            'takenDt': self.taken_dt,
            's3ImagePath': self.image_path,
            'aiResult': self.ai_result,
            'ngComment': self.ng_comment,
            'model': self.model,
            'editedModel': self.edited_model,
            'serialNumber': self.serial_number,
            'editedSerialNumber': self.edited_serial_number, 
            'progress': self.progress,
            'version': self.version,
        }