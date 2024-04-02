import Foundation

// MARK: - Property

/// 文字数制限
enum WORD_COUNT {
    /// 会社CD
    case COMPANY_CD
    /// 担当拠点CD
    case BASE_CD
    /// 担当CD
    case REP_CD
    /// 品番
    case MODEL
    /// 製造番号
    case SERIAL_NUMBER
    /// 点検項目名
    case INSPECTION_ITEM_NAME
    /// NGコメント
    case NG_COMMENT
    /// WSNo
    case WSNO
    /// 受付確定日
    case RECEIPT_CONFIRMATION_DATE
    /// 顧客名
    case CUSTOMER_NAME
    /// 点検名
    case INSPECTION_NAME
    /// 訪問予定日
    case SCHEDULED_VISIT_DATE
    
    func getWordCount() -> Int {
        switch(self){
            // 会社CDの文字数
        case .COMPANY_CD:
            return 8
            // 担当拠点CDの文字数
        case .BASE_CD:
            return 8
            // 担当CDの文字数
        case .REP_CD:
            return 8
            // 品番の文字数
        case .MODEL:
            return 20
            // 製造番号の文字数
        case .SERIAL_NUMBER:
            return 12
            // 点検項目名の文字数
        case .INSPECTION_ITEM_NAME:
            return 16
            // NGコメントの文字数
        case .NG_COMMENT:
            return 50
            // WSNoの文字数
        case .WSNO:
            return 10
            // 受付確定日
        case .RECEIPT_CONFIRMATION_DATE:
            return 8
            // お客様名
        case .CUSTOMER_NAME:
            return 50
            // 点検名
        case .INSPECTION_NAME:
            return 15
            // 訪問予定日
        case .SCHEDULED_VISIT_DATE:
            return 8
        }
    }
}

/// 品番入力チェック
/// - Parameter model: 品番
func validationModel(model: String) throws {
    do {
        // 一文字目が「-」だったらエラー
        if model.first == "-" {
            throw ErrorID.ID0011
        }
        // shift-jis変換してバイト数が一致するかどうかをみる
        if model.lengthOfBytes(using: .shiftJIS) != model.count {
            // 全角が入っていればエラー
            throw ErrorID.ID0011
        }
        // s3ガイドライン入力チェック
        try validationS3Guidelines(text: model)
    } catch {
        errorLog(message: "品番に禁則文字使用", error: nil)
        throw error
    }
}

/// 製造番号の入力チェック
/// - Parameter serialNumber: 製造番号
func validationSerialNumber(serialNumber: String) throws {
    do {
        // shift-jis変換してバイト数が一致するかどうかをみる
        if serialNumber.lengthOfBytes(using: .shiftJIS) != serialNumber.count {
            // 全角が入っていればエラー
            throw ErrorID.ID0011
        }
        // s3ガイドライン入力チェック
        try validationS3Guidelines(text: serialNumber)
    } catch {
        errorLog(message: "製品番号に禁則文字使用", error: nil)
        throw error
    }
}

/// NGコメント入力チェック
/// - Parameter ngComment: NGコメント
func validationNGComment(ngComment: String) throws {
    do {
        // shift-jis変換して入力チェック
        try validationShiftJIS(text: ngComment)
        // s3ガイドライン入力チェック
        try validationS3Guidelines(text: ngComment)
    } catch {
        errorLog(message: "NGコメントに禁則文字使用", error: nil)
        throw error
    }
}

/// 点検項目名入力チェック
/// - Parameter itemName: 点検項目名
func validationInspectionItemName(itemName: String) throws {
    do {
        // shift-jis変換して入力チェック
        try validationShiftJIS(text: itemName)
        // s3ガイドライン入力チェック
        try validationS3Guidelines(text: itemName)
    } catch {
        errorLog(message: "点検項目名に禁則文字使用", error: nil)
        throw error
    }
}

/// shift-jis変換して入力を制限する
/// - Parameter text: 文字列
func validationShiftJIS(text: String) throws {
    // 文字列配列を１文字ずつshift-JISに変換し、入力を許可するかを決定
    for char in text {
        // 半角があればエラーを返す
        if String(char).lengthOfBytes(using: .shiftJIS) == 1 {
            throw ErrorID.ID0011
        }
        // 1文字をshift-JIS変換してバイト列に変換
        guard let shiftjisByteList = String(char).data(using: .shiftJIS) else {
            // shift-JIS変換できなければエラーを返す
            throw ErrorID.ID0011
        }
        // バイト列を結合して16進数に変換
        guard let hexNumber = Int(shiftjisByteList.map { String(format: "%02hhx", $0) }.joined(), radix: 16) else {
            // 16進数に変換できなければエラー
            throw ErrorID.ID0011
        }
        // shift-jis変換した時に【F040】～【F9FC】の範囲
        let forbiddenCharactersRange = 0xF040...0xF9FC
        // 禁止範囲に含まれていた場合エラー
        if forbiddenCharactersRange.contains(hexNumber) {
            throw ErrorID.ID0011
        }
    }
}

/// S3ガイドラインの特殊な処理を必要とする可能性がある文字」と「使用しない方がよい文字」に引っ掛かるかどうかを判定
/// - Warnig: 半角しかできない
/// - Parameter text: 文字列
func validationS3Guidelines(text: String) throws {
    // 1文字ごとに禁則文字かどうか判定
    for char in Array(text) {
        // １文字をASCIIの10進数に変換
        guard let asciiText = String(char).cString(using: .ascii) else {
            // ASCII変換できない時
            // ASCIIコード128~255の範囲にある文字が上の処理で変換できないので
            // その文字に当たるUnicodeの文字コード範囲にあるかどうかをみる
            // Unicodeにした時の文字の範囲
            let regex = "[\u{FF61}-\u{FF9F}\u{201C}\u{201D}\u{2018}\u{2019}]"
            // Unicodeにした時の文字の範囲に当てはまる文字であればエラー
            if (String(char).range(of: regex, options: .regularExpression) != nil) {
               throw ErrorID.ID0011
            }
            // ASCIIコードに変換できない、かつ禁則文字ではない文字はスキップ
            continue
        }
        // アスキーコード0~31の範囲の文字コード
        let forbiddenCharactersRange = 0...31
        // 入力制限されるかどうか判定
        if (forbiddenCharactersRange.contains(Int(asciiText[0])) ||
            Int(asciiText[0]) == 38 || // &
            Int(asciiText[0]) == 36 || // $
            Int(asciiText[0]) == 64 || // @
            Int(asciiText[0]) == 61 || // =
            Int(asciiText[0]) == 59 || // ;
            Int(asciiText[0]) == 47 || // /
            Int(asciiText[0]) == 58 || // :
            Int(asciiText[0]) == 43 || // +
            Int(asciiText[0]) == 32 || // space
            Int(asciiText[0]) == 44 || // ,
            Int(asciiText[0]) == 63 || // ?
            Int(asciiText[0]) == 92 || // \ (¥)
            Int(asciiText[0]) == 123 || // {
            Int(asciiText[0]) == 94 || // ^
            Int(asciiText[0]) == 125 || // }
            Int(asciiText[0]) == 37 || // %
            Int(asciiText[0]) == 96 || // `
            Int(asciiText[0]) == 93 || // ]
            Int(asciiText[0]) == 34 || // " (引用符)
            Int(asciiText[0]) == 39 || // ' (引用符)
            Int(asciiText[0]) == 62 || // >
            Int(asciiText[0]) == 91 || // [
            Int(asciiText[0]) == 126 || // ~
            Int(asciiText[0]) == 60 || // <
            Int(asciiText[0]) == 35 || // #
            Int(asciiText[0]) == 124 // |
        ) {
            // 禁則文字が含まれていた場合、ログイン失敗(パラメータ異常)
            throw ErrorID.ID0011
        }
    }
}
