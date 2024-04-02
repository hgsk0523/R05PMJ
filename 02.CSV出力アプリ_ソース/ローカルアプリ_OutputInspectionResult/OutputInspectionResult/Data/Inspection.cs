using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace OutputInspectionResult.Data
{
    public class Inspection
    {
        /// <summary>
        /// 点検名ID
        /// </summary>
        [JsonPropertyName("inspection_name_id")]
        public long InspectionNameId { get; set; }

        /// <summary>
        /// 点検名
        /// </summary>
        [JsonPropertyName("inspection_name")]
        public string InspectionName { get; set; }
    }
}
