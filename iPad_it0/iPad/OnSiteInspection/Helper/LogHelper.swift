import Foundation
import XCGLogger

// MARK: - Method

let appDelegate = UIApplication.shared.delegate as! AppDelegate
var log: XCGLogger = initLog()
/// フォルダ名
let LOG_FOLDER_NAME: String = "Logs"
/// 保持期間
let LOG_RETENTION_PERIOD: Int = 7

/// ログ初期化
func initLog() -> XCGLogger {
    let log = XCGLogger(identifier: "OnSiteInspectionLogger", includeDefaultDestinations: false)
    
    // 保持期間を過ぎたログファイルの削除
    deleteLogFile()

    // 日付取得
    let date = Date().toJst(format: DATE_S3_FORMAT_LOCAL)
    // ログファイル保存階層
    let history = "\(LOG_FOLDER_NAME)/\(date)"
    // 保存先にフォルダがなければ作成
    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask ).first {
        let folderName = dir.appendingPathComponent( history , isDirectory: true)
        try? FileManager.default.createDirectory( at: folderName, withIntermediateDirectories: true, attributes: nil)
    }

    let logPath: URL = appDelegate.documentsDirectory.appendingPathComponent("\(history)/ExecutionLog.txt")
    let autoRotatingFileDestination = AutoRotatingFileDestination(
            writeToFile: logPath, identifier: "advancedLogger.fileDestination", shouldAppend: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], maxFileSize:(10 * 1024 * 1024), maxTimeInterval: (24 * 60 * 60) ,targetMaxLogFiles: 7)
    // 出力ログレベル
    autoRotatingFileDestination.outputLevel = .info
    // ログID(OnSiteInspectionLogger)表示
    autoRotatingFileDestination.showLogIdentifier = false
    // メソッド名表示
    autoRotatingFileDestination.showFunctionName = false
    // スレッド名表示
    autoRotatingFileDestination.showThreadName = false
    // レベル表示
    autoRotatingFileDestination.showLevel = false
    // ファイル名
    autoRotatingFileDestination.showFileName = false
    // 行番号
    autoRotatingFileDestination.showLineNumber = false
    // 日付
    autoRotatingFileDestination.showDate = true

    // 設定の追加
    log.add(destination: autoRotatingFileDestination)
    // 基本的なアプリ情報を起動時にログファイルに追加
    log.logAppDetails()

    return log
}

/// 通常ログ出力用
func infoLog(screen: String, logMessage: String) {
    log.info("\(screen)：\(logMessage)")
}

/// エラーログ出力用
func errorLog(message: String, error: Error?) {
    if let errorContent = error {
        log.error("\r\n=========================== Error Occurrd ===========================\r\n\(message)\r\n\(errorContent)\r\n=========================== Error Occurrd ===========================")
    } else {
        // 予期せぬエラーの発生
        log.error("\r\n=========================== Error Occurrd ===========================\r\n\(message)\r\n" +
                  "unexpected error.\r\n=========================== Error Occurrd ===========================")
    }
}

/// ログファイルの削除
func deleteLogFile() {
    do {
        // 削除基準日の取得
        guard let referenceDate = Calendar.current.date(byAdding: .day, value: -LOG_RETENTION_PERIOD, to: fixDate(date: Date())) else { return }
        // 端末のログファイルを取得する
        let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(LOG_FOLDER_NAME)
        // ログフォルダ直下のフォルダを取得する
        let contentURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        // 何もなければreturnする
        if contentURLs.isEmpty { return }
        // 写真フォルダ直下のフォルダ分ループし、保持期間がすぎたデータを削除する
        contentURLs.forEach { url in
            // URLをString型に変更(エンコードもする)
            let urlTextArray:[String] = url.absoluteString.removingPercentEncoding!.components(separatedBy: "/")
            // 点検日時だけ取り出す
            let urlDate = urlTextArray[urlTextArray.endIndex - 2]
            if fixDate(date: fixDateFromString(date: "\(urlDate)", format: DATE_S3_FORMAT_LOCAL)!) < referenceDate {
                // 該当フォルダを削除
                deleteLocalImage(hierarchy: "\(LOG_FOLDER_NAME)/\(urlDate)/")
            }
        }
    } catch {
        return
    }
}
