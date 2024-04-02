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
            try contentURLs.forEach { url in
                // URLをString型に変更(エンコードもする)
                let urlTextArray:[String] = url.absoluteString.removingPercentEncoding!.components(separatedBy: "/")
                // 点検日時だけ取り出す
                let urlDate = urlTextArray[urlTextArray.endIndex - 2]
                if let date = fixDateFromString(date: "\(urlDate)", format: DATE_S3_FORMAT_LOCAL) {
                    // 日付を比較する
                    if date < referenceDate {
                        // 該当フォルダを削除
                        deleteLocalImage(hierarchy: "\(FOLDER_NAME)/\(urlDate)/")
                    }
                } else {
                    // step3時に作成されたフォルダの階層下のオブジェクトを取得する
                    let urlDateStep3 = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                    // urlを/で分割した配列
                    var urlArray: [String] = url.absoluteString.removingPercentEncoding!.components(separatedBy: "/")
                    // step3で生成される写真フォルダ下のwscdが名前になっているフォルダ名を保存する変数
                    // 補足：urlを/で分割した時、配列の最後が""のものが入るため、wscdが後ろから2番目にくる
                    let wscd: String = urlArray[urlArray.endIndex - 2]
                    // 取得したオブジェクト分ループし、保存期間が過ぎたデータを削除する
                    urlDateStep3.forEach { urlStep3 in
                        // URLをString型に変更(エンコードもする)
                        let urlTextArray:[String] = urlStep3.absoluteString.removingPercentEncoding!.components(separatedBy: "/")
                        // ファイル名
                        let urlFileName = urlTextArray[urlTextArray.endIndex - 1]
                        // ファイル名の先頭8文字(日付)を抜き出す
                        let urlDate = urlFileName.prefix(8)
                        // 日付を比較する
                        if fixDate(date: fixDateFromString(date: "\(urlDate)", format: DATE_S3_FORMAT_LOCAL)!) < referenceDate {
                            // 該当写真を削除
                            deleteLocalImage(hierarchy: "\(FOLDER_NAME)/\(wscd)/\(urlFileName)/")
                        }
                    }
                    // Step3の機能で作成されたフォルダ下に何も含まれていない場合、そのフォルダを削除
                    if (try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)).isEmpty {
                        // 該当フォルダを削除
                        deleteLocalImage(hierarchy: "\(FOLDER_NAME)/\(wscd)/")
                    }
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
