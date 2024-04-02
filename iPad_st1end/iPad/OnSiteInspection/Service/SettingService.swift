import Foundation
import UIKit

/// 設定ファイルサービス
class SettingService: NSObject {
    /// シングルトン
    private override init() {}
    public static let shared = SettingService()
    
    /// 撮影例画像を初期化
    private func initExampleImage()  {
        // 設定ファイルを取得
        let settings = try? SettingDatasource.shared.getAllSettings()
        // 既存の撮影例、撮影例マスタを削除する
        try? RealmService.shared.deleteExampleImageData()
        try? ImageService.shared.deletePhotographyExample()
        // 画像サンプルの分だけ処理
        settings?.forEach { setting in
            setting.photoSample.forEach { photoSampleData in
                // 画像情報の分だけ処理
                photoSampleData.photoInfo?.forEach { photoInfoData in
                    // 撮影例マスタを作成する
                    let exampleImageData = self.createExampleImageData(photoData: photoInfoData, photoSampleData: photoSampleData, setting: setting)
                    // 新しい撮影例マスタを保存する
                    try? RealmService.shared.saveExampleImageData(exampleImageData: exampleImageData)
                    // サーバーから撮影例画像を取得し、端末に保存
                    // 撮影例画像をS3から取得
                    ApiService.shared.getS3ImageData(bucketName: S3_BUCKET_NAME, s3Path: "\(photoInfoData.s3Path)\(photoInfoData.fileName)") { image in
                        /// 取得した画像を端末に保存
                        try? self.saveExampleImageToDevice(image: image, fileName: photoInfoData.fileName, filePath: photoInfoData.s3Path)
                        
                    } failureHandler: { error in
                        errorLog(message: "撮影例取得失敗", error: error)
                    }
                }
            }
        }
    }
    
    /// 撮影例を端末に保存
    func saveExampleImageToDevice(image: UIImage?, fileName: String, filePath: String) throws {
        // 撮影画像を端末に保存
        // 階層
        let hierarchy = "\(FOLDER_NAME_EXSAMPLE_IMAGE)\(filePath)"
        // 保存先にフォルダがなければ作成
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask ).first {
            let folderName = dir.appendingPathComponent( hierarchy , isDirectory: true)
            do {
                try FileManager.default.createDirectory( at: folderName, withIntermediateDirectories: true, attributes: nil)
            } catch {
                // 保存失敗
                throw error
            }
        }
        do {
            // ファイル名
            let localPath = "\(hierarchy)\(fileName)"
            // パス名
            let path = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(localPath)
            // 撮影例画像をデータ型に変換
            guard let imageData = image?.jpegData(compressionQuality: 1) else {
                throw ErrorID.ID9999
            }
            // ローカルに画像を保存
            try imageData.write(to: path)
        } catch {
            throw error
        }
    }
    
    // 端末の設定ファイルを取得する
    func getSettingInfoFromDevice(localPath: String) -> Data? {
        do {
            // 端末の設定ファイルを取得する
            let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(localPath)
            return try Data(contentsOf: url)
        }  catch {
            return nil
        }
    }
    
    /// realmに保存する撮影例画像データを作成する
    /// - Returns: 撮影例データ
    func createExampleImageData(photoData: PhotoInfo, photoSampleData: PhotoSample, setting: Settings) -> TBL_M_SAMPLE_PHOTO {
        /// 撮影例データを作成
        let exampleImageData = TBL_M_SAMPLE_PHOTO()
        /// ファイル名
        exampleImageData.filename_name = photoData.fileName
        /// 点検名ID
        exampleImageData.inspection_name_id = setting.inspectionNameId
        /// 点検項目名ID
        exampleImageData.item_name_id = photoSampleData.inspectionItemNameId
        /// 説明文
        exampleImageData.explanation = photoData.explanation
        /// ローカルパス
        exampleImageData.local_image_path = photoData.s3Path
        /// S3パス
        exampleImageData.s3_image_path = photoData.s3Path
        /// 作成日時
        exampleImageData.mak_dt = Date()
        /// 更新日時
        exampleImageData.ren_dt = Date()
        
        return exampleImageData
    }
    
    /// 設定ファイルの設定
    /// - Parameters:
    ///   - localJsonPath: JSONファイルを保存するパス
    ///   - currentSettingJson: 現在端末に保存されている設定ファイル
    ///   - newSettingJson: サーバーから取得した設定ファイル
    func setSettingFile(localJsonPath: URL, currentSettingJson: Data?, newSettingJson: Data) throws {
        do {
            // サーバーから読み込んだ設定ファイルを構造体に変換
            let newSettingInfo = try JSONDecoder().decode(SettingValues.self, from: newSettingJson)
            // 現在端末にJSONファイルがあるかどうかを判別
            if let currentSettingJson = currentSettingJson {
                // 現在端末にJSONファイルがあるとき
                // バージョンの比較をする（端末内のファイルのバージョンが正常に取得できない場合はサーバーの設定値ファイルを優先する）
                let dic = try JSONSerialization.jsonObject(with: currentSettingJson, options: []) as? [String: Any]
                if (dic?["version"] as? Int ?? 0) >= newSettingInfo.version {
                    // 現在の設定ファイルを構造体に変換
                    let currentSettingInfo = try JSONDecoder().decode(SettingValues.self, from: currentSettingJson)
                    // 端末の設定ファイル情報をinfoに保存
                    SettingDatasource.shared.saveSettingInfo(settingInfo: currentSettingInfo)
                    return
                }
            }
            // 現在端末にJSON更新
            // サーバーの設定ファイル情報をinfoに保存
            SettingDatasource.shared.saveSettingInfo(settingInfo: newSettingInfo)
            // サーバーの設定ファイル情報をローカルの設定情報に保存
            try newSettingJson.write(to: localJsonPath)
            // 撮影例画像設定
            self.initExampleImage()
        } catch {
            errorLog(message: "設定ファイル取得失敗", error: error)
            throw error
        }
    }
    
    /// 点検項目情報の登録
    func saveInspectionInfo(parametersInfo: ParametersInfo,
                            successHandler: @escaping (GetInspectionItemApiResponse) -> Void,
                            failureHandler: @escaping (ErrorCause?) -> Void) {
        // bodyの作成
        let body = GetInspectionItemApiRequestBody(worksheetCode: parametersInfo.WSHEETNO,
                                                   receiptConfirmationDate: Int(parametersInfo.UUKAKUTEIDATE) ?? 0,
                                                   inspectionName: parametersInfo.MEISHO,
                                                   inspectionDate: Int(parametersInfo.YOTEIYMD) ?? 0,
                                                   companyCode: parametersInfo.KAISHACD)
        ApiService.shared.getInspectionItemApiRequest(body: body) { response in
            do {
                // Realmに点検データ、点検項目を保存
                try RealmService.shared.saveInspectionData(response: response, parametersInfo: parametersInfo)
                
                guard let inspectionData = response.schedule else {
                    throw ErrorID.ID9999
                }
                
                let data = try RealmService.shared.getInspectionData(inspectionID: inspectionData.id)
                // 点検データinfoに情報を設定
                InspectionViewDataSource.shared.setInspectionViewInfo(inspectionID: data.inspection_id,
                                                                      inspectionName: parametersInfo.MEISHO,
                                                                      inspectionNameID: data.inspection_name_id,
                                                                      inspectionDate: data.inspection_date,
                                                                      wscd: data.worksheet_code,
                                                                      model: data.model,
                                                                      customerName: data.client_name,
                                                                      comment: try SettingDatasource.shared.getSettings(inspectionNameId: data.inspection_name_id).comment,
                                                                      status: data.status,
                                                                      companyCD: data.company_code,
                                                                      baseCD: data.base_code)
                successHandler(response)
            } catch {
                failureHandler((error as? ErrorCause))
            }
        } failureHandler: { error in
            failureHandler(error)
        }
    }
}
