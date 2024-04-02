import Foundation

/// カスタムURLスキーマサービス
class CustomURLSchemeService: NSObject {
    
    /// シングルトン
    private override init() {}
    public static let shared = CustomURLSchemeService()
    
    /// ログインパラメータをチェックする
    /// - Parameters:
    ///   - companyCD: 会社CD
    ///   - baseCD: 担当拠点CD
    ///   - repCD: 担当者CD
    func checkLoginParameters(companyCD: String, baseCD: String, repCD: String) throws {
        do {
            // 空値チェック
            if (companyCD.trimmingCharacters(in: .whitespaces).isEmpty || baseCD.trimmingCharacters(in: .whitespaces).isEmpty || repCD.trimmingCharacters(in: .whitespaces).isEmpty) {
                throw ErrorID.ID0003
            }
            // 3つのパラメータのどれかが最大桁数を超えていたらエラー
            if (companyCD.count > WORD_COUNT.COMPANY_CD.getWordCount() || baseCD.count > WORD_COUNT.BASE_CD.getWordCount() || repCD.count > WORD_COUNT.REP_CD.getWordCount()) {
                throw ErrorID.ID0003
            }
        } catch {
            throw error
        }
    }
    
    /// カスタムURLパラメータチェック
    /// - Parameter parametersInfo: パラメータ情報
    func checkParameters(companyCD: String, baseCD: String, repCD: String, wsheetNO: String, uukakuteiDate: String, katasiki: String, kkName: String, meisho: String, yoteiYMD: String) throws {
        // 空値チェック
        if (wsheetNO.trimmingCharacters(in: .whitespaces).isEmpty ||
            uukakuteiDate.trimmingCharacters(in: .whitespaces).isEmpty ||
            katasiki.trimmingCharacters(in: .whitespaces).isEmpty ||
            kkName.trimmingCharacters(in: .whitespaces).isEmpty ||
            meisho.trimmingCharacters(in: .whitespaces).isEmpty ||
            yoteiYMD.trimmingCharacters(in: .whitespaces).isEmpty) {
            throw ErrorID.ID0035
        }
        // 各パラメータの最大桁数を超えていたらエラー
        if (wsheetNO.count != WORD_COUNT.WSNO.getWordCount() ||
            uukakuteiDate.count != WORD_COUNT.RECEIPT_CONFIRMATION_DATE.getWordCount() ||
            katasiki.count > WORD_COUNT.MODEL.getWordCount() ||
            kkName.count > WORD_COUNT.CUSTOMER_NAME.getWordCount() ||
            meisho.count > WORD_COUNT.INSPECTION_NAME.getWordCount() ||
            yoteiYMD.count != WORD_COUNT.SCHEDULED_VISIT_DATE.getWordCount()
        ) {
            throw ErrorID.ID0035
        }
        // 各パラメータの入力チェック
        if (companyCD.range(of: "^[0-9]+$", options: .regularExpression) == nil ||
            baseCD.range(of: "^[0-9a-zA-Z]+$", options: .regularExpression) == nil ||
            repCD.range(of: "^[0-9a-zA-Z]+$", options: .regularExpression) == nil ||
            wsheetNO.range(of: "^[0-9]+$", options: .regularExpression) == nil ||
            uukakuteiDate.range(of: "^[0-9]+$", options: .regularExpression) == nil ||
            yoteiYMD.range(of: "^[0-9]+$", options: .regularExpression) == nil) {
           throw ErrorID.ID0035
        }
        
        // 全角確認
        for char in kkName {
            // 半角があればエラーを返す
            if String(char).lengthOfBytes(using: .shiftJIS) == 1 {
                throw ErrorID.ID0035
            }
        }
        
        // 全角確認
        for char in meisho {
            // 半角があればエラーを返す
            if String(char).lengthOfBytes(using: .shiftJIS) == 1 {
                throw ErrorID.ID0035
            }
        }
        
        // 品番確認
        // 一文字目が「-」だったらエラー
        if katasiki.first == "-" {
            throw ErrorID.ID0035
        }
        // shift-jis変換してバイト数が一致するかどうかをみる
        if katasiki.lengthOfBytes(using: .shiftJIS) != katasiki.count {
            // 全角が入っていればエラー
            throw ErrorID.ID0035
        }

        // 日付のフォーマット確認
        let dataFormatter = DateFormatter()
        dataFormatter.dateFormat = DATE_S3_FORMAT_LOCAL
        if ( dataFormatter.date(from: uukakuteiDate) == nil ||
             dataFormatter.date(from: yoteiYMD) == nil) {
            throw ErrorID.ID0035
        }
    }
}
