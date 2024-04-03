from enum import Enum

class AwsService(Enum):
    """
    AWS Serviceの種別を管理するEnum
    """

    RDS = 1
    """
    RDSサービスの種別値
    """
    
    S3 = 2
    """
    S3サービスの種別値
    """

    SQS = 3
    """
    SQSサービスの種別値
    """
    
    TEXTRACT = 4
    """
    Textractサービスの種別値
    """