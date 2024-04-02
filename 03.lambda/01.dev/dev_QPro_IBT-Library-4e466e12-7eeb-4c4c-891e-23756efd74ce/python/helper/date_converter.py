from datetime import datetime, date, time, timezone

class DateConverter():

    # -----------------------------------
    #  日付フォーマット定数
    # -----------------------------------
    _FORMAT_YYYYMMDD_HYPHEN: str = '%Y-%m-%d'
    """
    YYYY-MM-DD 形式
    """
    _FORMAT_YYYYMMDD_SLASH: str = '%Y/%m/%d'
    """
    YYYY/MM/DD 形式
    """
    _FORMAT_YYYYMMDD_HHMMSSFFF_HYPHEN: str  = '%Y-%m-%d %H:%M:%S.%f'
    """
    YYYY-MM-DD hh:mm:ss.SSSSSS 形式
    """
    _FORMAT_YYYYMMDD_HHMMSSFFF_SLASH: str  = '%Y/%m/%d %H:%M:%S.%f'
    """
    YYYY/MM/DD hh:mm:ss.SSSSSS 形式
    """
    _FORMAT_YYYYMMDDTHHMMSSFFF_HYPHEN: str = '%Y-%m-%dT%H:%M:%S.%f'
    """
    YYYY-MM-DDThh:mm:ss.SSSSSS 形式
    """
    _FORMAT_YYYYMMDDTHHMMSSFFF_SLASH: str = '%Y/%m/%dT%H:%M:%S.%f'
    """
    YYYY/MM/DDThh:mm:ss.SSSSSS 形式
    """

    @staticmethod
    def _str_2_datetime(date_str: str, format: str) -> datetime:
        """
        文字列型を日時型に変換する関数

        Args:
            date_str: 日時の文字列
            format: 日時文字列のフォーマット

        Returns:
            datetime: 日時文字列を日時型に変換した値
        """
        return datetime.strptime(date_str, format).replace(tzinfo = timezone.utc)
    
    @classmethod
    def _str_2_date(cls, date_str: str, format: str) -> date:
        """
        文字列型を日時型に変換する関数

        Args:
            date_str: 日時の文字列
            format: 日時文字列のフォーマット

        Returns:
            datetime: 日時文字列を日時型に変換した値
        """
        return cls._str_2_datetime(date_str, format).date()
    
    @classmethod
    def str_2_date_hyphen(cls, date_str: str) -> date:
        """
        YYYY-MM-DD 形式の文字列型を日付型に変換する

        Returns:
            date: YYYY-MM-DD の日付型
        """
        return cls._str_2_date(date_str, cls._FORMAT_YYYYMMDD_HYPHEN)

    @classmethod
    def str_2_date_slash(cls, date_str: str) -> date:
        """
        YYYY/MM/DD 形式の文字列型を日付型に変換する

        Returns:
            date: YYYY/MM/DD の日付型
        """
        return cls._str_2_date(date_str, cls._FORMAT_YYYYMMDD_HYPHEN)

    @classmethod
    def str_2_datetime_hyphen(cls, datetime_str: str) -> datetime:
        """
        YYYY-MM-DD hh:mm:ss.SSS 形式の文字列型を日時型に変換する

        Returns:
            date: YYYY-MM-DD hh:mm:ss.SSS の日付型
        """
        return cls._str_2_datetime(datetime_str, cls._FORMAT_YYYYMMDD_HHMMSSFFF_HYPHEN)

    @classmethod
    def str_2_datetime_slash(cls, datetime_str: str) -> datetime:
        """
        YYYY/MM/DD hh:mm:ss.SSS 形式の文字列型を日時型に変換する

        Returns:
            date: YYYY/MM/DD hh:mm:ss.SSS の日時型
        """
        return cls._str_2_datetime(datetime_str, cls._FORMAT_YYYYMMDD_HHMMSSFFF_SLASH)

    @staticmethod
    def isoformat_2_datetime(isoformat_str: str) -> datetime:
        """
        ISO形式 (YYYY-MM-DDThh:mm:ss.SSSZ) の文字列型を日時型に変換する

        Returns:
            date: YYYY-MM-DDThh:mm:ss.SSSZ の日時型
        """
        return datetime.fromisoformat(isoformat_str)

    @staticmethod
    def date_2_isoformat(dt: datetime) -> str:
        """
        日時型を文字列型(ISOフォーマット)に変換する関数

        Returns:
            str: YYYY-MM-DD'T'hh:mm:ss.SSS 形式の文字列
        """
        return dt.isoformat(sep='T', timespec='milliseconds')