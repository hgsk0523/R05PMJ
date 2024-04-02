using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace OutputInspectionResult.Data
{
    public class ApiResponseGetInspectionName
    {
        /// <summary>
        /// 処理結果コード
        /// </summary>
        [JsonPropertyName("resultCode")]
        public int ResultCode {  get; set; }

        /// <summary>
        /// 点検名情報のリスト
        /// </summary>
        [JsonPropertyName("inspectionNames")]
        public List<Inspection> InspectionNames { get; set; }
    }
}
