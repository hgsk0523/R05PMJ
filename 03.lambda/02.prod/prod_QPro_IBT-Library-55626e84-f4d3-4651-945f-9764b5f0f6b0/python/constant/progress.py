from enum import IntEnum, unique

@unique
class Progress(IntEnum):
    """
    AI解析の進捗状況を表すクラス
    """

    WAITING_IMAGE_SAVE = 0
    """
    進捗状況 0:イメージ保存待ち
    """
    
    IMAGE_SAVED_ONLY_LOCAL = 1
    """
    進捗状況 1:端末内画像保存完了
    ※Step.4ではサーバーサイドでは未使用
    """
    
    IMAGE_SAVED = 2
    """
    進捗状況 2:画像保存済
    """
    
    REQUEST_RECEIVED = 3
    """
    進捗状況 3:画像解析依頼受信済
    """
    
    ANALYZING = 4
    """
    進捗状況 4:画像解析中
    ※Step.4ではサーバーサイドでは未使用
    """
    
    ANALYSIS_FINISHED = 5
    """
    進捗状況 5:画像解析完了
    """