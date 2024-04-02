from sqlalchemy import and_
from ..entity import TInspectionItem, MInspectionItem
from constant import Progress
import datetime

class TInspectionItemRepository():

    @staticmethod
    def insert(transaction, entity:TInspectionItem) -> TInspectionItem:
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
    def find_by_id(transaction, inspection_item_id: int) -> TInspectionItem | None:
        """
        指定された点検項目IDの点検結果レコードを取得する

        Returns:
            TInspectionItem: 点検結果の対象レコード
        """
        return transaction.query(TInspectionItem)\
                .filter(
                    TInspectionItem.inspection_item_id == inspection_item_id,
                )\
                .one_or_none()

    @staticmethod
    def find_by_id_with_update_lock(transaction, inspection_item_id: int) -> TInspectionItem | None:
        """
        指定された点検項目IDの点検結果レコードを取得する(排他ロック付き)

        Returns:
            TInspectionItem: 点検結果の対象レコード
        """
        return transaction.query(TInspectionItem)\
                .filter(
                    TInspectionItem.inspection_item_id == inspection_item_id,
                )\
                .with_for_update()\
                .one_or_none()

    @staticmethod
    def find_by_id_outer_join_item_master(transaction, inspection_item_id: int) -> tuple[TInspectionItem, MInspectionItem] | None:
        """
        指定された点検項目IDの点検結果レコードを取得する

        Returns:
            TInspectionItem: 点検結果の対象レコード
        """
        return transaction.query(TInspectionItem, MInspectionItem)\
                .filter(
                    TInspectionItem.inspection_item_id == inspection_item_id,
                )\
                .outerjoin(MInspectionItem, TInspectionItem.item_name_id == MInspectionItem.item_name_id)\
                .one_or_none()

    @staticmethod
    def find_by_inspection_id(transaction, inspection_id: int) -> list[TInspectionItem] | None:
        """
        指定された点検IDに紐づく点検結果のレコードを取得する

        Returns:
            TInspectionItem: AI判定結果の対象レコード
        """
        return transaction.query(TInspectionItem)\
                .filter(
                    TInspectionItem.inspection_id == inspection_id,
                )\
                .all()
    
    @staticmethod
    def find_by_inspection_id_and_updated_at(transaction, inspection_id: int, updated_at: datetime) -> list[TInspectionItem] | None:
        """
        指定された点検IDに紐づく点検結果のレコードのうち更新日がupdated_at以上のものを取得する

        Returns:
            TInspectionItem: 点検項目の対象レコード
        """
        return transaction.query(TInspectionItem)\
                .filter(
                    TInspectionItem.inspection_id == inspection_id,
                    TInspectionItem.updated_at >= updated_at,

                )\
                .all()

    @staticmethod
    def find_by_id_and_progress(transaction, inspection_item_id: int, progress: Progress) -> tuple[TInspectionItem, MInspectionItem] | None:
        """
        指定された点検項目IDの点検結果レコードを取得する

        Returns:
            TInspectionItem: 点検結果の対象レコード
        """
        return transaction.query(TInspectionItem, MInspectionItem)\
                .filter(
                    TInspectionItem.inspection_item_id == inspection_item_id,
                    TInspectionItem.progress == progress,
                )\
                .join(MInspectionItem, TInspectionItem.item_name_id == MInspectionItem.item_name_id)\
                .one_or_none()
    
    @staticmethod
    def delete_by_id(transaction, id_list: list[int]):
        """
        指定された点検項目IDの点検結果レコードを削除する
        """

        transaction.query(TInspectionItem)\
            .filter(TInspectionItem.inspection_item_id.in_(id_list),)\
            .delete()
        
