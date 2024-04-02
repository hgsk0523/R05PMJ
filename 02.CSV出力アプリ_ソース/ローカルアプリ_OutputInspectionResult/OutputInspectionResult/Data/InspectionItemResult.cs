using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace OutputInspectionResult.Data
{
    public class InspectionItemResult
    {
        /// <summary>
        /// 点検項目名ID
        /// </summary>
        [JsonPropertyName("item_name_id")]
        public long ItemNameId { get; set; }

        /// <summary>
        /// 項目名
        /// </summary>
        [JsonPropertyName("item_name")]
        public string ItemName { get; set; }

        /// <summary>
        /// 解析種別
        /// </summary>
        [JsonPropertyName("analysis_type")]
        public int AnalysisType { get; set; }
    }
}
