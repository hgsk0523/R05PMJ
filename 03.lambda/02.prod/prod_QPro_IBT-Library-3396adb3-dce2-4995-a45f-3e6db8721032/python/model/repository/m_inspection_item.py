from ..entity import MInspectionItem

class MInspectionItemRepository():
    """
    点検項目の情報を管理するリポジトリ
    """

    @staticmethod
    def find_by_id(transaction, item_name_id: int) -> MInspectionItem:
        """
        対象の点検項目名IDから点検項目の設定情報を取得する関数

        Returns:
            MInspectionItem: 点検項目情報
        """
        return transaction.query(MInspectionItem)\
                    .filter(MInspectionItem.item_name_id == item_name_id)\
                    .one_or_none()
    
    @staticmethod
    def find_by_inspection_name_id(transaction, inspection_name_id: int) -> list[MInspectionItem] | None:
        """
        対象の点検名IDから点検項目の設定情報を取得する関数

        Returns:
            list[MInspectionItem]: 点検項目情報リスト
        """
        return transaction.query(MInspectionItem)\
                    .filter(MInspectionItem.inspection_name_id == inspection_name_id)\
                    .all()
