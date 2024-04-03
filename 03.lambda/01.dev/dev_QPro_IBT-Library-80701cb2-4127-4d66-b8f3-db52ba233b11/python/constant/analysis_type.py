from enum import IntEnum, unique

@unique
class AnalysisType(IntEnum):
    """
    点検項目の解析方法を管理するEnum
    """

    OCR = 1
    """
    解析種別: OCR
    """

    AI = 2
    """
    解析種別: 画像認識AI
    """

    OTHER = 3
    """
    解析種別: その他
    """