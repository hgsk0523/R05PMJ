from ..entity import MInspection

class MInspectionRepository():
    """
    点検項目の情報を管理するリポジトリ
    """

    @staticmethod
    def find_by_id(transaction, inspection_name_id: int) -> MInspection | None:
        """
        対象の点検名IDから点検マスタ情報を取得する関数

        Returns:
            MInspection: 点検マスタ情報
        """
        return transaction.query(MInspection)\
                    .filter(
                        MInspection.inspection_name_id == inspection_name_id,
                    )\
                    .one_or_none()
    
    @staticmethod
    def find_by_name(transaction, inspection_name: str) -> MInspection | None:
        """
        対象の点検名から点検マスタ情報を取得する関数

        Returns:
            MInspection: 点検マスタ情報
        """
        return transaction.query(MInspection)\
                    .filter(
                        MInspection.inspection_name == inspection_name,
                    )\
                    .one_or_none()