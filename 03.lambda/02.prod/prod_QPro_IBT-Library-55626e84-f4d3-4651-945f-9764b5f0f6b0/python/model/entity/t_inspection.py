from sqlalchemy.schema import Column, UniqueConstraint
from sqlalchemy.types import BIGINT, String, INTEGER
from sqlalchemy.dialects.mysql import TINYINT, BOOLEAN
from .mixincolumn import MixinColumn
from .base import Base
from constant import (
    InspectionStatus,
)

class TInspection(Base, MixinColumn):
    __tablename__ = "TBL_T_INSPECTION"

    __table_args__ = (
        (UniqueConstraint('worksheet_code', 'receipt_confirmation_date', name = 'uni_idx_t_inspection_01')),
    )

    # 点検ID
    inspection_id = Column('inspection_id', BIGINT, primary_key=True, autoincrement=True)
    # 点検名ID
    inspection_name_id = Column('inspection_name_id', BIGINT, nullable = False)
    # ワークシートコード
    worksheet_code = Column('worksheet_code', String(10), nullable = False)
    # 受付確定日
    receipt_confirmation_date = Column('receipt_confirmation_date', INTEGER, nullable = False)
    # 点検日
    inspection_date = Column('inspection_date', String(8), nullable = False)
    # 点検状態
    status = Column('status', TINYINT, nullable = False)
    # エビデンスID
    evidence_id = Column('evidence_id', TINYINT, nullable = True)
    # 会社コード
    company_code = Column('company_code', String(8), nullable = False)
    # 送信回数
    send_count = Column('send_count', TINYINT, nullable = False)
    # 連携フラグ
    is_send = Column('is_send', BOOLEAN, nullable = False)

    def to_dict(self) -> dict:
        """
        クラスの情報をKVS(dict型)に変換する
        """
        return {
            'inspectionId': self.inspection_id,
            'inspectionNameId': self.inspection_name_id,
            'worksheetCode': self.worksheet_code,
            'receiptConfirmationDate': self.receipt_confirmation_date,
            'inspectionDate': self.inspection_date,
            'status': self.status,
            'evidenceId': self.evidence_id,
            'companyCode': self.company_code,
            'sendCount': self.send_count,
            'isSend': self.is_send,
        }