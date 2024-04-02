import UIKit

/// パラメータのデータ
struct ParametersInfo {
    /// 会社CD
    var KAISHACD: String!
    /// WSCD
    var WSHEETNO: String!
    /// 受付確定日
    var UUKAKUTEIDATE: String!
    /// 担当拠点CD
    var KYOTENCD: String!
    /// 担当者CD
    var STANTOUCD: String!
    /// 品番
    var KATASIKI: String!
    /// お客様名
    var KKNAME: String!
    /// 点検称
    var MEISHO: String!
    /// 訪問予定日
    var YOTEIYMD: String!
    /// 品番入力チェックフラグ
    var modelCheckFlag: Bool = false
    
    /// パラメータをセットする
    /// - Parameter url: URL
    mutating func setParametersInfo(url: URL) throws {
        do {
            guard let urlString = URL(string: url.absoluteString),
                  let kaishaCD = urlString.queryValue(for: "KAISHACD"),
                  let wsheetNO = urlString.queryValue(for: "WSHEETNO"),
                  let uukakuteiDate = urlString.queryValue(for: "UUKAKUTEIDATE"),
                  let kyotenCD = urlString.queryValue(for: "KYOTENCD"),
                  let stantouCD = urlString.queryValue(for: "STANTOUCD"),
                  let katasiki = urlString.queryValue(for: "KATASIKI"),
                  let kkName = urlString.queryValue(for: "KKNAME"),
                  let meisho = urlString.queryValue(for: "MEISHO"),
                  let yoteiYMD = urlString.queryValue(for: "YOTEIYMD") else {
                      throw ErrorID.ID0035
                  }
            // パラメータ値チェック
            try CustomURLSchemeService.shared.checkParameters(companyCD: kaishaCD, baseCD: kyotenCD, repCD: stantouCD, wsheetNO: wsheetNO, uukakuteiDate: uukakuteiDate, katasiki: katasiki, kkName: kkName, meisho: meisho, yoteiYMD: yoteiYMD)
            // 会社CD
            self.KAISHACD = kaishaCD
            // WSCD
            self.WSHEETNO = wsheetNO
            // 受付確定日
            self.UUKAKUTEIDATE = uukakuteiDate
            // 担当拠点CD
            self.KYOTENCD = kyotenCD
            // 担当者CD
            self.STANTOUCD = stantouCD
            // 品番
            self.KATASIKI = katasiki
            // お客様名
            self.KKNAME = kkName
            // 点検称
            self.MEISHO = meisho
            // 訪問予定日
            self.YOTEIYMD = yoteiYMD
        } catch {
            throw error
        }
    }
}
