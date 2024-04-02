using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using PCom;

namespace OutputInspectionResult.Classes
{
    public class ClsPrm : Prm
    {
        //点検名情報取得APIのURL
        public static readonly string GET_INSPECTION_NAME_API_URL;
        //点検結果情報取得APIのURL
        public static readonly string GET_INSPECTION_RESULT_API_URL;
        //APIキー
        public static readonly string API_KEY;

        //CSVファイルのデフォルトファイル名
        public static readonly string DEFAULT_FILENAME;
        //CSVファイルのエンコーディング
        public static readonly string FILE_ENCODING;
        //CSVファイルへの出力件数
        public static readonly int OUTPUT_COUNT;

        //HTTPリクエストのタイムアウト値
        public static readonly int HTTP_TIMEOUT;

        //点検日の範囲日数
        public static readonly int RANGE_DATE;

        //JSON読込みのバッファサイズ
        public static readonly int JSON_BUFFER_SIZE;
        //JSON読込みの分割件数
        public static readonly int JSON_SPLIT_COUNT;

        static ClsPrm()
        {
            Log.WriteLog("INIファイルよりアプリケーション固有の値を取得します。" + INI_NAME, null, Log.LOG_START, Log.LogLv.Info);

            try
            {
                string strdm = string.Empty;
                int intdef = 0;

                GET_INSPECTION_NAME_API_URL = IniReadStr(INI_NAME, "WebAPI接続情報", "点検名情報取得APIのURL", ref strdm);
                GET_INSPECTION_RESULT_API_URL = IniReadStr(INI_NAME, "WebAPI接続情報", "点検結果情報取得APIのURL", ref strdm);
                API_KEY = IniReadStr(INI_NAME, "WebAPI接続情報", "APIのキー", ref strdm);

                DEFAULT_FILENAME = IniReadStr(INI_NAME, "CSVファイル情報", "デフォルトファイル名", ref strdm);
                FILE_ENCODING = IniReadStr(INI_NAME, "CSVファイル情報", "エンコーディング", ref strdm);
                OUTPUT_COUNT = IniReadInt(INI_NAME, "CSVファイル情報", "出力件数", ref intdef);

                intdef = 10;
                HTTP_TIMEOUT = IniReadInt(INI_NAME, "HTTPリクエスト", "タイムアウト値", ref intdef);

                intdef = 30;
                RANGE_DATE = IniReadInt(INI_NAME, "点検日", "範囲日数", ref intdef);

                intdef = 10240;
                JSON_BUFFER_SIZE = IniReadInt(INI_NAME, "JSON読込み", "バッファサイズ", ref intdef);

                intdef = 100;
                JSON_SPLIT_COUNT = IniReadInt(INI_NAME, "JSON読込み", "分割基準件数", ref intdef);
            }
            catch (Exception ex){
                Log.WriteLog(ex.Message, null, Log.LOG_ERR, Log.LogLv.ERR);
            }
            finally
            {
                Log.WriteLog("", null, Log.LOG_END, Log.LogLv.Info);
            }
        }
    }
}
