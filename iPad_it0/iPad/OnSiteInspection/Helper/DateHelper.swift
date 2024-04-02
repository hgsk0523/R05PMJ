import Foundation
import RealmSwift

// MARK: - Property

/// 保存用日時フォーマット
let SAVE_DATE_FORMAT: String = "yyyyMMddHHmmssSSS"
/// 表示用日時フォーマット
let DRAW_DATE_FORMAT: String = "yyyy/MM/dd HH:mm:ss"
/// 日付型に変換するためのフォーマット
let TRANSFORM_DATE_FORMAT: String = "yyyy/MM/dd HH:mm:ss Z"
/// 日付フォーマット
let DATE_FORMAT: String = "yyyy/MM/dd"
/// 日付S3フォーマット
let DATE_S3_FORMAT: String = "yyyy-MM-dd"
/// 日付フォーマット(ローカル保存用)
let DATE_S3_FORMAT_LOCAL: String = "yyyyMMdd"
/// 時間フォーマット
let TIME_FORMAT: String = "HH:mm"
/// 時分秒を0にするフォーマット
let ZERO_TIME_FORMAT: String = "00:00:00"
/// 秒を0にするフォーマット
let ZERO_SECOND: String = ":00"
/// タイムゾーンが0の時
let ZERO_TIME_ZONE: String = "+0000"

// MARK: - Method

/// データ型の時分を全て0にする
func fixDate(date: Date) -> Date {
    // フォーマット指定
    let formatterDateTime = DateFormatter()
    formatterDateTime.dateFormat = TRANSFORM_DATE_FORMAT
    formatterDateTime.locale = Locale(identifier: "ja_JP")
    // タイムゾーン設定（端末設定によらず、どこの地域の時間帯なのかを指定する）
    formatterDateTime.timeZone = TimeZone(identifier: "Asia/Tokyo")
    
    return formatterDateTime.date(from: "\(date.toJst(format: DATE_FORMAT)) \(ZERO_TIME_FORMAT) \(ZERO_TIME_ZONE)") ?? Date()
}


/// 文字列を日付型に直す関数
/// - Parameter date: 文字列の日付
/// - Returns: 日付
func fixDateFromString(date: String, format: String) -> Date? {
    let formatterDateTime = DateFormatter()
    formatterDateTime.dateFormat = format
    formatterDateTime.locale = Locale(identifier: "ja_JP")
    // タイムゾーン設定（端末設定によらず、どこの地域の時間帯なのかを指定する）
    formatterDateTime.timeZone = TimeZone(identifier: "Asia/Tokyo")
    return formatterDateTime.date(from: date) ?? nil
}

/// String型できた日付に/を挿入し、フォーマットを設定
/// - Parameter date: 日付 例:20230618
func fixDateFormat(date: String) -> String {
    // 渡すデータ
    var result = date
    // /を先頭から4番目に挿入
    result.insert("/", at: result.index(result.startIndex, offsetBy: 4))
    // /を最後から2番目に挿入
    result.insert("/", at: result.index(result.endIndex, offsetBy: -2))
    
    return result
}
