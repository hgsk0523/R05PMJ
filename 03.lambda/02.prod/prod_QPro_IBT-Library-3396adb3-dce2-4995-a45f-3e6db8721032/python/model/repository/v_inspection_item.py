from ..entity import VInspectionItem

class VInspectionItemRepository():

    @staticmethod
    def find_by_inspection_id(transaction, inspection_id: int) -> list[VInspectionItem] | None:
        """
        指定された点検IDに紐づく点検結果のレコードを取得する

        Returns:
            TInspectionItem: AI判定結果の対象レコード
        """
        return transaction.query(VInspectionItem)\
                .filter(
                    VInspectionItem.inspection_id == inspection_id,
                )\
                .order_by(VInspectionItem.inspection_item_id)\
                .all()