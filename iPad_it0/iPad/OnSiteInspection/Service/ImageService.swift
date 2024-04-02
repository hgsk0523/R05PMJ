import Foundation

/// 写真サービス
class ImageService: NSObject {
    
    // MARK: - Property
    
    /// シングルトン
    private override init() {}
    public static let shared = ImageService()
    /// 撮影例画像
    private let PHOTOGRAPHY_EXAMPLE_IMAGE = "撮影例画像"
    
    // MARK: - Method

    /// データ保持期間が過ぎている写真を取得
    func deleteOldImageData() throws {
        do {
            // 削除基準日の取得
            guard let referenceDate = Calendar.current.date(byAdding: .day, value: SettingDatasource.shared.getSettingValuesInfo().dataRetentionPeriod, to: fixDate(date: Date())) else { return }
            // 端末の設定ファイルを取得する
            let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(FOLDER_NAME)
            // 写真フォルダ直下のフォルダを取得する
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
                    deleteLocalImage(hierarchy: "\(FOLDER_NAME)/\(urlDate)/")
                }
            }
        } catch {
            throw error
        }
    }
    
    /// 撮影例を削除
    func deletePhotographyExample() throws {
        do {
            // 端末の設定ファイルを取得する
            let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(self.PHOTOGRAPHY_EXAMPLE_IMAGE)
            // 撮影例フォルダ直下のフォルダを取得する
            let contentURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            // 何もなければreturnする
            if contentURLs.isEmpty { return }
            // 撮影例フォルダ直下のフォルダ分ループし、データを削除する
            contentURLs.forEach { url in
                // URLをString型に変更(エンコードもする)
                let urlTextArray:[String] = url.absoluteString.removingPercentEncoding!.components(separatedBy: "/")
                // 削除するフォルダを取り出す
                let photographyExample = urlTextArray[urlTextArray.endIndex - 2]
                // 該当フォルダを削除
                deleteLocalImage(hierarchy: "\(self.PHOTOGRAPHY_EXAMPLE_IMAGE)/\(photographyExample)/")
            }
        } catch {
            throw error
        }
    }
}
