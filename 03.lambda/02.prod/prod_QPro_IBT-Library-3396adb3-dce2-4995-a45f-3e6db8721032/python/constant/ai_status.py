from enum import IntEnum, unique

@unique
class AIStatus(IntEnum):
    """
    AI解析結果のStatusを管理するクラス
    """

    FAILED = 0
    """
    失敗のステータス
    """

    SUCCESS = 1
    """
    合格のステータス
    """

