using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Net;
using System.Text.Json;
using OutputInspectionResult.Data;
using OutputInspectionResult.Classes;
using PCom;
using System.Text.RegularExpressions;
using System.IO.Compression;

namespace OutputInspectionResult
{
    public partial class frmOutputInspectionResult : Form
    {
        #region ============ Win32API ===================

        #endregion

        #region ============ 構造体 =====================

        #endregion

        #region ============ 定数 =======================
        /// <summary>
        /// メッセージダイアログのタイトル
        /// </summary>
        private const string MESSAGE_DIALOG_TITLE = "メッセージ";

        /// <summary>
        /// エラーダイアログのタイトル
        /// </summary>
        private const string ERROR_DIALOG_TITLE = "エラー";
        #endregion

        #region ============ メンバ変数 =================
        string oldInputWscd = string.Empty;
        #endregion

        #region ============ プロパティ =================

        #endregion

        #region ============ コンストラクタ =============
        /// <summary>
        /// コンストラクタ
        /// </summary>
        public frmOutputInspectionResult()
        {
            InitializeComponent();

            //点検日に初期値を設定する
            DateTime today = DateTime.Today;
            dtpStartDate.Value = today.AddMonths(-1);
            dtpEndDate.Value = today;
        }
        #endregion

        #region ============ Publicメソッド =============

        #endregion

        #region ============ Protectedメソッド ==========

        #endregion

        #region ============ Privateメソッド ============

        #region 点検日の入力チェックを行う
        /// <summary>
        /// 点検日の入力チェックを行う
        /// </summary>
        /// <param name="startDate">点検日の開始日</param>
        /// <param name="endDate">点検日の終了日</param>
        /// <returns>true:有効である、fale:無効である</returns>
        private static bool ValidateDate(DateTime startDate, DateTime endDate)
        {
            if (startDate <= endDate)
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        #endregion

        #region 点検日の範囲日数チェックを行う
        /// <summary>
        /// 点検日の範囲日数チェックを行う
        /// </summary>
        /// <param name="startDate">点検日の開始日</param>
        /// <param name="endDate">点検日の終了日</param>
        /// <returns>true:有効である、fale:無効である</returns>
        private static bool ValidateRangeDate(DateTime startDate, DateTime endDate)
        {
            TimeSpan ts = endDate - startDate;
            if (ts.Days >= ClsPrm.RANGE_DATE)
            {
                return false;
            }
            else
            {
                return true;
            }
        }
        #endregion

        #region 点検結果情報を取得する
        /// <summary>
        /// 点検結果情報を取得する
        /// </summary>
        /// <param name="inspectionNameId">点検名ID</param>
        /// <param name="wscd">WSCD</param>
        /// <param name="startDate">点検日の開始日</param>
        /// <param name="endDate">点検日の終了日</param>
        /// <param name="tmpFilePath">一時ファイルパス（ZIP）</param>
        /// <returns>resultCode：処理結果コード、resultCount：JSON件数、inspectionResults：点検結果JSON</returns>
        private static async Task<(int resultCode, int resultCount, string inspectionItemResultsJson)> GetInspectionResult(string inspectionNameId, string wscd, DateTime startDate, DateTime endDate, string tmpFilePath)
        {
            int resultCode = 0;
            int resultCount = 0;
            string inspectionItemResultsJson = "";

            try
            {
                Log.WriteLog("点検結果情報取得処理開始", string.Empty, Log.LOG_START, Log.LogLv.Info);

                int outputCount = 0;
                if (0 < ClsPrm.OUTPUT_COUNT)
                {
                    outputCount = ClsPrm.OUTPUT_COUNT;
                }

                //クエリパラメータ
                Dictionary<string, string> _params = new Dictionary<string, string>()
                {
                    { "inspectionNameId", inspectionNameId },
                    { "wscd", wscd },
                    { "startDate", startDate.ToShortDateString() },
                    { "endDate", endDate.ToShortDateString() },
                    { "outputCount", outputCount.ToString() }
                };
                Log.WriteLog("クエリパラメータ(" + "inspectionNameId：" + _params["inspectionNameId"] + ", wscd：" + _params["wscd"] + ", startDate：" + _params["startDate"] + ", endDate：" + _params["endDate"] + ", outputCount：" + _params["outputCount"] + ")", string.Empty, Log.LOG_CHECK, Log.LogLv.Info);

                //点検結果情報取得APIのURL
                string webapiUrl = ClsPrm.GET_INSPECTION_RESULT_API_URL + $"?{await new FormUrlEncodedContent(_params).ReadAsStringAsync()}";
                Log.WriteLog("点検結果情報取得APIのURL：" + webapiUrl, string.Empty, Log.LOG_CHECK, Log.LogLv.Info);

                //点検結果情報取得APIへリクエスト送信
                HttpClient client = new HttpClient
                {
                    Timeout = TimeSpan.FromMinutes(ClsPrm.HTTP_TIMEOUT)
                };
                HttpRequestMessage request = new HttpRequestMessage(
                    HttpMethod.Get,
                    webapiUrl
                );
                request.Headers.Add("x-api-key", ClsPrm.API_KEY);
                ApiResponseGetInspectionResult result;
                using (var response = await client.SendAsync(request))
                {
                    var jsonData = await response.Content.ReadAsStringAsync();
                    result = JsonSerializer.Deserialize<ApiResponseGetInspectionResult>(jsonData);
                    resultCode = result.ResultCode;
                }

                string resultLog = "点検結果情報取得処理結果：";
                switch (resultCode)
                {
                    case (20000):
                        resultLog += Properties.Resources.M_003;

                        //S3に格納したファイルから点検項目名を取得する
                        using (var inspectionItemResultsTask = client.GetStringAsync(result.InspectionItemResultsUrl))
                        {
                            inspectionItemResultsJson = await inspectionItemResultsTask;
                        }

                        //S3に格納したファイルから点検結果情報を取得する
                        using (var inspectionResultsTask = await client.SendAsync(new HttpRequestMessage(HttpMethod.Get, result.InspectionResultsUrl), HttpCompletionOption.ResponseHeadersRead))
                        {
                            if (inspectionResultsTask.StatusCode == HttpStatusCode.OK)
                            {
                                if (inspectionResultsTask.Headers.TryGetValues("x-amz-meta-count", out IEnumerable<string> count))
                                {
                                    if (int.TryParse(count.FirstOrDefault(), out resultCount))
                                    {
                                        resultLog += $" JSON件数：{resultCount}";
                                        using (var stream = await inspectionResultsTask.Content.ReadAsStreamAsync())
                                        {
                                            using (var fileStream = new FileStream(tmpFilePath, FileMode.Create, FileAccess.Write, FileShare.None))
                                            {
                                                stream.CopyTo(fileStream);
                                            }
                                        }
                                    }
                                    else
                                    {
                                        resultLog += " x-amz-meta-countの値が変換できませんでした。";
                                    }
                                }
                                else
                                {
                                    resultLog += " ヘッダーにx-amz-meta-countが含まれていません。";
                                }
                            }
                        }
                        break;
                    case (40000):
                        resultLog += Properties.Resources.E_003;
                        break;
                    case (40001):
                        resultLog += Properties.Resources.E_004;
                        break;
                    case (40002):
                        resultLog += Properties.Resources.E_009;
                        break;
                    case (50000):
                        resultLog += Properties.Resources.E_005;
                        break;
                    case (50002):
                        resultLog += Properties.Resources.E_008;
                        break;
                    case (50004):
                        resultLog += Properties.Resources.E_006;
                        break;
                }

                Log.WriteLog(resultLog, string.Empty, Log.LOG_CHECK, Log.LogLv.Info);
            }
            catch (Exception ex)
            {
                Log.WriteLog(ex.Message + "\r\n" + ex.StackTrace, string.Empty, Log.LOG_ERR, Log.LogLv.ERR);
                throw;
            }
            finally
            {
                Log.WriteLog("点検結果情報取得処理終了", string.Empty, Log.LOG_END, Log.LogLv.Info);
            }
            return (resultCode, resultCount, inspectionItemResultsJson);
        }
        #endregion

        #region CSVファイルを出力する
        /// <summary>
        /// CSVファイルを出力する
        /// </summary>
        /// <param name="inspectionItemResultsJson">点検項目名JSON</param>
        /// <param name="path">保存ファイルパス</param>
        /// <param name="tmpFilePath">一時ファイルパス（ZIP）</param>
        /// <param name="resultCount">JSON件数</param>
        private static void OutputCsv(string inspectionItemResultsJson, string path, string tmpFilePath, int jsonCount)
        {
            try
            {
                Log.WriteLog("CSVファイルを出力", string.Empty, Log.LOG_START, Log.LogLv.Info);

                List<InspectionItemResult> inspectionItemResults = JsonSerializer.Deserialize<List<InspectionItemResult>>(inspectionItemResultsJson);
                if (inspectionItemResults.Count == 0)
                {
                    Log.WriteLog("点検項目名が存在しません。", string.Empty, Log.LOG_CHECK, Log.LogLv.Info);
                    return;
                }

                //ファイル名に日付を付与する
                string nowDateTime = DateTime.Now.ToString("yyyyMMddHHmmss");
                string fileName = nowDateTime + "_" + Path.GetFileName(path);
                string filePath = Path.Combine(Path.GetDirectoryName(path), fileName);

                using (StreamWriter sw = new StreamWriter(filePath, true, Encoding.GetEncoding(ClsPrm.FILE_ENCODING)))
                {
                    //CSVファイルを出力する（ヘッダー）
                    Dictionary<long, int> dicItemNameId = OutputCsvHeader(inspectionItemResults, sw);

                    using (var archive = ZipFile.OpenRead(tmpFilePath))
                    {
                        ZipArchiveEntry ae = archive.GetEntry("inspection_results.json");
                        if (ae == null)
                        {
                            Log.WriteLog("ZIPファイルにinspection_results.jsonが存在しません。", string.Empty, Log.LOG_CHECK, Log.LogLv.Info);
                            return;
                        }

                        List<InspectionResult> items = null;

                        using (StreamReader sr = new StreamReader(ae.Open(), Encoding.UTF8))
                        {
                            int bufferSize = ClsPrm.JSON_BUFFER_SIZE;
                            char[] buffer = new char[bufferSize];
                            string tmpJson = "";
                            int result;
                            while ((result = sr.Read(buffer, 0, bufferSize)) != 0)
                            {
                                tmpJson += new string(buffer, 0, result);
                                string[] strings = tmpJson.Split('}');
                                if ((strings.Length - 1) >= ClsPrm.JSON_SPLIT_COUNT)
                                {
                                    jsonCount -= (strings.Length - 1);

                                    string json = JsonRegenerate(ref tmpJson);
                                    bool flgLast = false;
                                    if (jsonCount <= 0)
                                    {
                                        flgLast = true;
                                    }
                                    OutputCsvBody(json, sw, dicItemNameId, ref items, flgLast);
                                }
                            }

                            if (!string.IsNullOrEmpty(tmpJson))
                            {
                                string json = JsonRegenerate(ref tmpJson);
                                OutputCsvBody(json, sw, dicItemNameId, ref items, true);
                            }

                            MessageBox.Show(Properties.Resources.M_001, MESSAGE_DIALOG_TITLE, MessageBoxButtons.OK, MessageBoxIcon.Information);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Log.WriteLog(ex.Message + "\r\n" + ex.StackTrace, string.Empty, Log.LOG_ERR, Log.LogLv.ERR);
                throw;
            }
            finally
            {
                Log.WriteLog("CSVファイルを出力", string.Empty, Log.LOG_END, Log.LogLv.Info);
            }
        }
        #endregion

        #region JSON再生成
        /// <summary>
        /// JSON再生成
        /// </summary>
        /// <param name="tmpJson"></param>
        /// <returns></returns>
        private static string JsonRegenerate(ref string tmpJson)
        {
            string json = "";
            try
            {
                //Log.WriteLog("JSON再生成", string.Empty, Log.LOG_START, Log.LogLv.Info);

                int firstPos = tmpJson.IndexOf("[");
                int endPos = tmpJson.LastIndexOf("}") + 1;
                if (firstPos == -1)
                {
                    json += "[";
                }
                json += tmpJson.Substring(0, endPos).TrimStart(',', ' ') + "]";

                int lastPos = tmpJson.IndexOf("]");
                if (lastPos == -1)
                {
                    tmpJson = tmpJson.Substring(endPos).TrimStart(',', ' ');
                }
                else
                {
                    tmpJson = "";
                }
            }
            catch (Exception ex)
            {
                Log.WriteLog(ex.Message + "\r\n" + ex.StackTrace, string.Empty, Log.LOG_ERR, Log.LogLv.ERR);
                throw;
            }
            finally
            {
                //Log.WriteLog("JSON再生成", string.Empty, Log.LOG_END, Log.LogLv.Info);
            }
            return json;
        }
        #endregion

        #region CSVファイルを出力する（ヘッダー）
        /// <summary>
        /// CSVファイルを出力する（ヘッダー）
        /// </summary>
        /// <param name="inspectionItemResults">点検項目名リスト</param>
        /// <param name="sw">StreamWriter</param>
        private static Dictionary<long, int> OutputCsvHeader(List<InspectionItemResult> inspectionItemResults, StreamWriter sw)
        {
            Dictionary<long, int> dicItemNameId = new Dictionary<long, int>();
            try
            {
                //Log.WriteLog("CSVファイルを出力（ヘッダー）", string.Empty, Log.LOG_START, Log.LogLv.Info);

                //ヘッダーを出力
                string itemNameText = Properties.Resources.CSV_Header;
                foreach (InspectionItemResult inspectionItemResult in inspectionItemResults)
                {
                    switch (inspectionItemResult.AnalysisType)
                    {
                        //OCR
                        case 1:
                            itemNameText += string.Format(Properties.Resources.CSV_Header_OCR, inspectionItemResult.ItemName);
                            dicItemNameId.Add(inspectionItemResult.ItemNameId, inspectionItemResult.AnalysisType);
                            break;

                        //AI
                        case 2:
                            itemNameText += string.Format(Properties.Resources.CSV_Header_AI, inspectionItemResult.ItemName);
                            dicItemNameId.Add(inspectionItemResult.ItemNameId, inspectionItemResult.AnalysisType);
                            break;
                    }
                }

                sw.WriteLine(itemNameText);
            }
            catch (Exception ex)
            {
                Log.WriteLog(ex.Message + "\r\n" + ex.StackTrace, string.Empty, Log.LOG_ERR, Log.LogLv.ERR);
                throw;
            }
            finally
            {
                //Log.WriteLog("CSVファイルを出力（ヘッダー）", string.Empty, Log.LOG_END, Log.LogLv.Info);
            }
            return dicItemNameId;
        }
        #endregion

        #region CSVファイルを出力する（本体）
        /// <summary>
        /// 点検結果情報JSON
        /// </summary>
        /// <param name="json">点検結果JSON</param>
        /// <param name="sw">StreamWriter</param>
        /// <param name="dicItemNameId">点検項目名</param>
        /// <param name="items">点検結果</param>
        /// <param name="flgLast">最終フラグ</param>
        private static void OutputCsvBody(string json, StreamWriter sw, Dictionary<long, int> dicItemNameId, ref List<InspectionResult> items, bool flgLast)
        {
            try
            {
                //Log.WriteLog("CSVファイルを出力（本体）", string.Empty, Log.LOG_START, Log.LogLv.Info);

                List<InspectionResult> inspectionResults = JsonSerializer.Deserialize<List<InspectionResult>>(json);

                if (items != null)
                {
                    inspectionResults.InsertRange(0, items);
                }

                //点検結果出力情報を出力
                var insResults = inspectionResults.AsEnumerable()
                                            .Select(row => new { row.InspectionName, row.WorksheetCode, row.InspectionDate, row.InspectionId })
                                            .Distinct();
                var last = insResults.Last();

                string inspectionResultText = "";
                foreach (var ins in insResults)
                {
                    if (flgLast == false)
                    {
                        if (ins.InspectionName == last.InspectionName && ins.WorksheetCode == last.WorksheetCode && ins.InspectionDate == last.InspectionDate && ins.InspectionId == last.InspectionId)
                        {
                            items = inspectionResults.AsEnumerable()
                                                    .Where(row => row.InspectionName == ins.InspectionName &&
                                                                row.WorksheetCode == ins.WorksheetCode &&
                                                                row.InspectionDate == ins.InspectionDate &&
                                                                row.InspectionId == ins.InspectionId)
                                                    .ToList();
                            return;
                        }
                    }

                    inspectionResultText = $"{ins.InspectionName},{ins.WorksheetCode},{ins.InspectionDate}";

                    foreach (var itemName in dicItemNameId)
                    {
                        var item = inspectionResults.AsEnumerable()
                                        .Where(row => row.InspectionId == ins.InspectionId && row.ItemNameId == itemName.Key.ToString())
                                        .FirstOrDefault();

                        switch (itemName.Value)
                        {
                            //OCR
                            case 1:
                                if (item != null)
                                {
                                    inspectionResultText += $",{item.Model},{item.EditedModel},{item.SerialNumber},{item.EditedSerialNumber},{item.S3ImagePath}";
                                }
                                else
                                {
                                    inspectionResultText += ",,,,,";
                                }
                                break;

                            //AI
                            case 2:
                                if (item != null)
                                {
                                    inspectionResultText += $",{item.AiResult},{item.NgComment},{item.S3ImagePath}";
                                }
                                else
                                {
                                    inspectionResultText += ",,,";
                                }
                                break;
                        }
                    }

                    sw.WriteLine(inspectionResultText);
                }
            }
            catch (Exception ex)
            {
                Log.WriteLog(ex.Message + "\r\n" + ex.StackTrace, string.Empty, Log.LOG_ERR, Log.LogLv.ERR);
                throw;
            }
            finally
            {
                //Log.WriteLog("CSVファイルを出力（本体）", string.Empty, Log.LOG_END, Log.LogLv.Info);
            }
        }
        #endregion

        #region 点検名情報を取得する
        /// <summary>
        /// 点検名情報を取得する
        /// </summary>
        /// <returns>resultCode：処理結果コード、inspectionNames：点検名情報リスト</returns>
        private static async Task<(int resultCode, List<Inspection> inspectionNames)> GetInspectionName()
        {
            List<Inspection> inspectionNames = new List<Inspection>();
            int resultCode = 0;

            try
            {
                Log.WriteLog("点検名情報取得開始", string.Empty, Log.LOG_START, Log.LogLv.Info);

                //点検名情報取得APIのURL
                string webapiUrl = ClsPrm.GET_INSPECTION_NAME_API_URL;
                Log.WriteLog("点検名情報取得APIのURL：" + webapiUrl, string.Empty, Log.LOG_CHECK, Log.LogLv.Info);

                //点検結果情報取得APIへリクエスト送信
                HttpClient client = new HttpClient();
                HttpRequestMessage request = new HttpRequestMessage(
                    HttpMethod.Get,
                    webapiUrl
                );
                request.Headers.Add("x-api-key", ClsPrm.API_KEY);
                var response = await client.SendAsync(request);
                var jsonData = await response.Content.ReadAsStringAsync();
                ApiResponseGetInspectionName result = JsonSerializer.Deserialize<ApiResponseGetInspectionName>(jsonData);
                inspectionNames = result.InspectionNames;
                resultCode = result.ResultCode;

                string resultLog = "点検名情報取得処理結果：";
                switch (resultCode)
                {
                    case (20000):
                        resultLog += Properties.Resources.M_003;
                        break;
                    case (50000):
                        resultLog += Properties.Resources.E_005;
                        break;
                    case (50004):
                        resultLog += Properties.Resources.E_006;
                        break;
                }

                Log.WriteLog(resultLog, string.Empty, Log.LOG_CHECK, Log.LogLv.Info);
            }
            catch (Exception ex)
            {
                Log.WriteLog(ex.Message + "\r\n" + ex.StackTrace, string.Empty, Log.LOG_ERR, Log.LogLv.ERR);
                throw;
            }
            finally
            {
                Log.WriteLog("点検名情報取得処理終了", string.Empty, Log.LOG_END, Log.LogLv.Info);
            }
            return (resultCode, inspectionNames);
        }
        #endregion

        #endregion

        #region ============ イベント ===================

        #region フォームロード
        /// <summary>
        /// フォームロード
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private async void frmOutputInspectionResult_Load(object sender, EventArgs e)
        {
            try
            {
                Log.WriteLog("フォームロード", string.Empty, Log.LOG_START, Log.LogLv.Info);
                this.Enabled = false;
                this.Cursor = Cursors.WaitCursor;

                var result = await GetInspectionName();

                if (result.resultCode == 20000)
                {
                    if (0 < result.inspectionNames.Count)
                    {
                        DataTable dt = new DataTable();
                        DataRow dr;
                        dt.Columns.Add("id");
                        dt.Columns.Add("name");

                        foreach (var ins in result.inspectionNames)
                        {
                            dr = dt.NewRow();
                            dr["id"] = ins.InspectionNameId;
                            dr["name"] = ins.InspectionName;
                            dt.Rows.Add(dr);
                        }

                        cmbInspectionName.DataSource = dt;
                        cmbInspectionName.DisplayMember = "name";
                        cmbInspectionName.ValueMember = "id";
                    }
                    else
                    {
                        MessageBox.Show(Properties.Resources.M_005, MESSAGE_DIALOG_TITLE, MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                }
                else
                {
                    MessageBox.Show(Properties.Resources.E_001, ERROR_DIALOG_TITLE, MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
            catch (Exception ex)
            {
                Log.WriteLog(ex.Message + "\r\n" + ex.StackTrace, string.Empty, Log.LOG_ERR, Log.LogLv.ERR);
                MessageBox.Show(Properties.Resources.E_001, ERROR_DIALOG_TITLE, MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                this.Enabled = true;
                this.Cursor = Cursors.Default;
                Log.WriteLog("フォームロード", string.Empty, Log.LOG_END, Log.LogLv.Info);
            }
        }
        #endregion

        #region btnOutput_Click - 出力ボタン押下
        /// <summary>
        /// 出力ボタン押下
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private async void btnOutput_Click(object sender, EventArgs e)
        {
            string tmpFilePath = "";
            try
            {
                Log.WriteLog("出力ボタン押下", string.Empty, Log.LOG_START, Log.LogLv.Info);

                btnOutput.Enabled = false;

                //画面の入力値を取得する
                string wscd = txtWscd.Text;
                DateTime startDate = dtpStartDate.Value;
                DateTime endDate = dtpEndDate.Value;

                //点検名の選択チェックを行う
                if (cmbInspectionName.SelectedIndex == -1)
                {
                    MessageBox.Show(Properties.Resources.E_007, ERROR_DIALOG_TITLE, MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
                string inspectionNameId = (string)cmbInspectionName.SelectedValue;

                //点検日の入力チェックを行う
                if (!ValidateDate(startDate, endDate))
                {
                    MessageBox.Show(Properties.Resources.E_002, ERROR_DIALOG_TITLE, MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                //点検日の範囲日数チェックを行う
                if (!ValidateRangeDate(startDate, endDate))
                {
                    MessageBox.Show(string.Format(Properties.Resources.E_010, ClsPrm.RANGE_DATE), ERROR_DIALOG_TITLE, MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                //点検結果情報出力先CSVファイルを選択
                SaveFileDialog saveFileDialog = new SaveFileDialog();
                saveFileDialog.FileName = ClsPrm.DEFAULT_FILENAME;
                saveFileDialog.Filter = "CSVファイル(*.csv)|*.csv";
                saveFileDialog.OverwritePrompt = false;

                if (saveFileDialog.ShowDialog() == DialogResult.OK)
                {
                    this.Cursor = Cursors.WaitCursor;

                    //点検結果情報を取得する
                    tmpFilePath = Path.GetTempFileName();
                    var result = await GetInspectionResult(inspectionNameId, wscd, startDate, endDate, tmpFilePath);

                    if (result.resultCode == 20000)
                    {
                        if (0 < result.resultCount)
                        {
                            OutputCsv(result.inspectionItemResultsJson, saveFileDialog.FileName, tmpFilePath, result.resultCount);
                        }
                        else
                        {
                            MessageBox.Show(Properties.Resources.M_004, MESSAGE_DIALOG_TITLE, MessageBoxButtons.OK, MessageBoxIcon.Information);
                        }
                    }
                    else
                    {
                        MessageBox.Show(Properties.Resources.E_001, ERROR_DIALOG_TITLE, MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
                else
                {
                    MessageBox.Show(Properties.Resources.M_002, MESSAGE_DIALOG_TITLE, MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
            }
            catch (Exception ex)
            {
                Log.WriteLog(ex.Message + "\r\n" + ex.StackTrace, string.Empty, Log.LOG_ERR, Log.LogLv.ERR);
                MessageBox.Show(Properties.Resources.E_001, ERROR_DIALOG_TITLE, MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                if (!string.IsNullOrEmpty(tmpFilePath))
                {
                    if (File.Exists(tmpFilePath))
                    {
                        File.Delete(tmpFilePath);
                    }
                }

                this.Cursor = Cursors.Default;
                btnOutput.Enabled = true;
                Log.WriteLog("出力ボタン押下", string.Empty, Log.LOG_END, Log.LogLv.Info);
            }
        }
        #endregion

        #region txtWscd_TextChanged - WSCDテキストボックス入力変更
        /// <summary>
        /// WSCDテキストボックス入力変更
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void txtWscd_TextChanged(object sender, EventArgs e)
        {
            try
            {
                //Log.WriteLog("WSCDテキストボックス入力変更", string.Empty, Log.LOG_START, Log.LogLv.Info);

                string wscd = txtWscd.Text;
                if (!string.IsNullOrEmpty(wscd))
                {
                    Regex reg = new Regex("[^0-9]");
                    if (reg.IsMatch(wscd))
                    {
                        txtWscd.Text = oldInputWscd;
                    }
                }

                oldInputWscd = txtWscd.Text;
            }
            catch (Exception ex)
            {
                Log.WriteLog(ex.Message + "\r\n" + ex.StackTrace, string.Empty, Log.LOG_ERR, Log.LogLv.ERR);
                MessageBox.Show(Properties.Resources.E_001, ERROR_DIALOG_TITLE, MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                //Log.WriteLog("WSCDテキストボックス入力変更", string.Empty, Log.LOG_END, Log.LogLv.Info);
            }
        }
        #endregion

        #endregion
    }
}
