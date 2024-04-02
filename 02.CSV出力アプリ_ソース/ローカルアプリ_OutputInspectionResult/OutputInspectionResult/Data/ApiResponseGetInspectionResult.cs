using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace OutputInspectionResult.Data
{
    public class ApiResponseGetInspectionResult
    {
        /// <summary>
        /// 処理結果コード
        /// </summary>
        [JsonPropertyName("resultCode")]
        public int ResultCode {  get; set; }

        /// <summary>
        /// 点検項目名のURL
        /// </summary>
        [JsonPropertyName("inspectionItemResultsUrl")]
        public Uri InspectionItemResultsUrl { get; set; }

        /// <summary>
        /// 点検結果情報のURL
        /// </summary>
        [JsonPropertyName("inspectionResultsUrl")]
        public Uri InspectionResultsUrl { get; set; }
    }
}
