from enum import Enum, unique
from typing import Self

@unique
class Message(Enum):
    """
    ログ等に出力するメッセージを管理するクラス
    """

    def __init__(self, code: str, message: str):
        """
        コンストラクタ
        """
        self.code = code
        self.message = message

    @staticmethod
    def get_message(msg: Self, *args) -> str:
        """
        メッセージを取得する関数

        Arguments:
            msg: 対象のEnum型
            *args: 各メッセージに応じた引数 (可変長引数)
        """
        message = msg.message.format(*args)
        return f'{msg.code}: {message}'


    # ============================
    #  環境変数定義
    # ============================

    # ---- デバッグメッセージ ----
    
    DBG_PROCESS_START = ('D001', '処理を開始しました。{0}')
    """
    処理開始メッセージ (DEBUG用)

    Arguments:
        {0}: 処理名
    """

    DBG_PROCESS_FINISH = ('D002', '処理が完了しました。{0}')
    """
    処理完了メッセージ (DEBUG用)

    Arguments:
        {0}: 処理名
    """

    DBG_OUTPUT_PARAMETERS = ('D003', 'パラメーター詳細情報 ({0}= {1})')
    """
    パラメーター出力用メッセージ (DEBUG用)

    Arguments:
        {0}: 変数名
        {1}: 変数値
    """

    DBG_VALIDATION_MESSAGE = ('D004', '{0} (rule: {1}, definition: {2})')
    """
    バリデーションルール出力用メッセージ (DEBUG用)

    Arguments:
        {0}: バリデーションメッセージ
        {1}: バリデーションルール
        {2}: バリデーション定義
    """


    # ---- インフォメーションメッセージ ----

    INF_PROCESS_SUCCEEDED = ('I001', '処理が正常に完了しました。{0}')
    """
    処理完了時に出力するメッセージ

    Arguments:
        {0}: 処理名
    """


    # ---- 警告メッセージ ----

    WRN_UNMATCHED_AI_ANALYSIS_TARGET = ('W001', 'AI解析対象外の項目です。(点検項目名: {0})')
    """
    AI解析対象外の項目だった場合のメッセージ

    Arguments:
        {0}: 点検項目名
    """

    WRN_MISSING_TARGET_RECORD = ('W002', '対象レコードが見つかりませんでした。(検索条件: {0})')
    """
    処理対象のレコードが存在しなかった場合のメッセージ

    Arguments:
        {0}: 検索条件(dict型)
    """

    # ---- エラーメッセージ ----
    
    ERR_OCCURRED_UNEXPECTED_EXCEPTION = ('E001', '想定外のエラーが発生しました。')
    """
    想定外のエラーが発生時のメッセージ
    """

    ERR_NO_MATCHING_RECORD = ('E002', '対象レコードがありません。{0}')
    """
    処理対象レコードなしのメッセージ

    Arguments:
        {0}: 検索条件など
    """

    ERR_OCCURRED_DB_EXCEPTION = ('E003', 'データベースでエラーが発生しました。' )
    """
    DB関連のエラー発生時のメッセージ
    """

    ERR_OCCURRED_SQS_EXCEPTION = ('E004', 'SQSでエラーが発生しました。')
    """
    SQS関連のエラー発生時のメッセージ
    """

    ERR_OCCURRED_S3_EXCEPTION = ('E005', 'S3でエラーが発生しました。')
    """
    S3関連のエラー発生時のメッセージ
    """

    ERR_OCCURRED_TEXTRACT_EXCEPTION = ('E006', 'Textractでエラーが発生しました。')
    """
    Textract関連のエラー発生時のメッセージ
    """

    ERR_OCCURRED_API_EXCEPTION = ('E007', 'APIでエラーが発生しました。')
    """
    APIコール関連のエラー発生時のメッセージ
    """

    ERR_OCCURRED_VALIDATION_EXCEPTION = ('E008', 'バリデーション処理でエラーが発生しました。')
    """
    バリデーション関連のエラー発生時のメッセージ
    """

    ERR_OCCRRED_S3_OBJECT_OPERATION_EXCEPTION = ('E009', 'S3オブジェクトの操作に失敗しました。 (対象操作: {0}, 対象オブジェクト: {1})')
    """
    S3オブジェクトの操作失敗時のメッセージ
    """