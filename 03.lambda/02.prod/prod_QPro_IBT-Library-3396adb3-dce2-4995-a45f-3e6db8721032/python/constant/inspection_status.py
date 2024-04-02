from enum import IntEnum, unique

@unique
class InspectionStatus(IntEnum):
    """
    点検状態を管理するEnum
    """

    PENDING_INSPECTION = 0
    """
    点検状態: 点検待ち
    """

    UNDER_INSPECTION = 1
    """
    点検状態: 点検中
    """

    REINSPECTION = 2
    """
    点検状態: 再点検
    """

    CONDITIONAL_COMPLETE = 3
    """
    点検状態: 終了※(条件付き完了)
    """

    INSPECTION_COMPLETED = 4
    """
    点検状態: 終了
    """
