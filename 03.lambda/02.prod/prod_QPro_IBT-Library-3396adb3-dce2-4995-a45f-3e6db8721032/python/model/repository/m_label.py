from ..entity import MLabel

class MLabelRepository():
    """
    AI判定結果の期待されるラベル情報を管理するリポジトリ
    """

    @staticmethod
    def find_by_item_name_id(transaction, item_name_id: int) -> list[MLabel] | None:
        """
        対象の項目名から判定ラベルの値を取得する関数

        Returns:
            Label: 項目名に対応するAIの物体検知ラベル情報
        """
        return transaction.query(MLabel)\
                    .filter(
                        MLabel.item_name_id == item_name_id,
                    )\
                    .all()

    @staticmethod
    def find_label_by_item_name_id(transaction, item_name_id: int) -> list[str] | None:
        """
        対象の項目名IDから判定ラベルの値を取得する関数

        Returns:
            list[str]: 項目名に対応するAIの物体検知ラベル名
        """
        entity_list = MLabelRepository.find_by_item_name_id(transaction, item_name_id)

        return [elm.label for elm in entity_list]