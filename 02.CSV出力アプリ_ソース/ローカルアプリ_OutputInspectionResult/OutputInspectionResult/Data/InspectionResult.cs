using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace OutputInspectionResult.Data
{
    public class InspectionResult
    {
        /// <summary>
        /// 点検名
        /// </summary>
        [JsonPropertyName("inspection_name")]
        public string InspectionName { get; set; }

        /// <summary>
        /// 点検ID
        /// </summary>
        [JsonPropertyName("inspection_id")]
        public long InspectionId { get; set; }

        /// <summary>
        /// WSCD
        /// </summary>
        [JsonPropertyName("worksheet_code")]
        public string WorksheetCode { get; set; }

        /// <summary>
        /// 点検日
        /// </summary>
        [JsonPropertyName("inspection_date")]
        public string InspectionDate { get; set; }

        /// <summary>
        /// 点検項目名ID
        /// </summary>
        [JsonPropertyName("item_name_id")]
        public string ItemNameId { get; set; }

        /// <summary>
        /// 解析種別
        /// </summary>
        [JsonPropertyName("analysis_type")]
        public string AnalysisType { get; set; }

        /// <summary>
        /// 品番
        /// </summary>
        [JsonPropertyName("model")]
        public string Model { get; set; }

        /// <summary>
        /// 編集済品番
        /// </summary>
        [JsonPropertyName("edited_model")]
        public string EditedModel { get; set; }

        /// <summary>
        /// 製造番号
        /// </summary>
        [JsonPropertyName("serial_number")]
        public string SerialNumber { get; set; }

        /// <summary>
        /// 編集済製造番号
        /// </summary>
        [JsonPropertyName("edited_serial_number")]
        public string EditedSerialNumber { get; set; }

        /// <summary>
        /// AI判定結果
        /// </summary>
        [JsonPropertyName("ai_result")]
        public string AiResult { get; set; }

        /// <summary>
        /// NGコメント
        /// </summary>
        [JsonPropertyName("ng_comment")]
        public string NgComment { get; set; }

        /// <summary>
        /// S3画像パス
        /// </summary>
        [JsonPropertyName("s3_image_path")]
        public string S3ImagePath { get; set; }
    }
}
