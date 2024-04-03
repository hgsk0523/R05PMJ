from enum import IntEnum, unique

@unique
class ShootType(IntEnum):
    """
    写真種別を管理するEnum
    """

    NAME_PLATE = 1
    """
    写真種別: 銘板
    """

    NUT = 2
    """
    写真種別: 固定ナット
    """

    MAGICTAPE = 3
    """
    写真種別: マジックテープ
    """

    INSTALLATION_STATUS = 4
    """
    写真種別: 取付状態
    """

    INSTALLATION_ENVIRONMENT = 5
    """
    写真種別: 設置環境
    """

    OTHER = 9
    """
    写真種別: その他
    """
