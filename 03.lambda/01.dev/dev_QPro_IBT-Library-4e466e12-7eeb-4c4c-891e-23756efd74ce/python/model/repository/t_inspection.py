from ..entity import (TInspection, MInspection)
from constant import InspectionStatus

class TInspectionRepository():
    """
    点検テーブルを操作するためのリポジトリクラス
    """

    @staticmethod
    def insert(transaction, entity:TInspection) -> TInspection:
        """
        レコードを作成する
        """
        # レコードインサート
        transaction.add(entity)
        # 仮反映(ロールバック可能)
        transaction.flush()
        # 仮反映したレコード値を返却
        return entity

    @staticmethod
    def find_by_id(transaction, inspection_id: int) -> TInspection | None:
        """
        指定されたPK値のレコードを取得する

        Returns:
            TInspection: 点検情報
        """
        return transaction.query(TInspection)\
                .filter(
                    TInspection.inspection_id == inspection_id
                )\
                .one_or_none()

    @staticmethod
    def find_by_unique_key(transaction, worksheet_code:str, receipt_confirmation_date: int) -> TInspection | None:
        """
        指定されたユニークキーのレコードを取得する

        Returns:
            TInspection: 点検情報
        """
        return transaction.query(TInspection)\
                .filter(
                    TInspection.worksheet_code == worksheet_code,
                    TInspection.receipt_confirmation_date == receipt_confirmation_date
                )\
                .one_or_none()

    @staticmethod
    def find_by_is_send(transaction, is_send: bool = False) -> list[tuple[TInspection, MInspection]] | None:
        """
        指定された連携フラグのレコードを取得する

        Returns:
            TInspection: 点検情報のリスト
        """
        status_list = [InspectionStatus.REINSPECTION, InspectionStatus.CONDITIONAL_COMPLETE, InspectionStatus.INSPECTION_COMPLETED]

        return transaction.query(TInspection, MInspection)\
                .filter(
                    TInspection.is_send == is_send,
                    TInspection.status.in_(status_list)
                )\
                .join(MInspection, TInspection.inspection_name_id == MInspection.inspection_name_id)\
                .order_by(TInspection.updated_at)\
                .all()

    @staticmethod
    def find_by_worksheet_code(transaction, worksheet_code: str) -> list[tuple[TInspection, MInspection]] | None:
        """
        指定されたワークシートコードのレコードを取得する

        Returns:
            TInspection: 点検情報のリスト
        """
        status_list = [InspectionStatus.REINSPECTION, InspectionStatus.CONDITIONAL_COMPLETE, InspectionStatus.INSPECTION_COMPLETED]

        return transaction.query(TInspection, MInspection)\
                .filter(
                    TInspection.worksheet_code == worksheet_code,
                    TInspection.status.in_(status_list)
                )\
                .join(MInspection, TInspection.inspection_name_id == MInspection.inspection_name_id)\
                .order_by(TInspection.updated_at)\
                .all()
