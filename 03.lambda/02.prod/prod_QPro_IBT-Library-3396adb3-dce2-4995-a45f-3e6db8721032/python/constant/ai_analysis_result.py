from enum import Enum, unique

@unique
class AIAnalysisResult(Enum):
    """
    AI判定結果を管理するクラス
    """

    def __init__(self, id: int, result: str):
        """
        コンストラクタ
        """
        self.id = id
        self.result = result

    @staticmethod
    def get_val(id: int) -> 'AIAnalysisResult':
        """
        ID値からValueを取得
        """
        for _, v in AIAnalysisResult.__members__.items():
            if v.id == id:
                return v

    OK = (0, 'OK')
    """
    解析結果: OK
    """

    NG = (1, 'NG')
    """
    解析結果: NG
    """

    FAILED = (-1, '解析失敗')
    """
    解析結果: 解析失敗
    """