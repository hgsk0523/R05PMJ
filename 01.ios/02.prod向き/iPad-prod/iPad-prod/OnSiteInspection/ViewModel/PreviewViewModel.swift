import UIKit
import Foundation

// MARK: - PreviewViewModelProtocol
/// プレビュー画面のVIew Modelのプロトコル
protocol PreviewViewModelProtocol {
    /// 容量確認
    func checkCapacity() throws
    /// ローカルへの画像保存
    func saveImageToLocal(originalImage: UIImage, trimmingImage: UIImage) throws
    /// クラウドへの画像の保存
    func saveImageToRemote(success: @escaping() -> Void, failure: @escaping(Error?) -> Void)
    /// プレビュー情報の取得
    func getPreviewInfo() -> PreviewInfo
    /// 点検項目名の取得
    func getItemName() -> String
    /// お客様名の取得
    func getClientName() -> String
    /// wscdの取得
    func getWorkSheetCode() -> String
    /// 撮影日時の取得
    func getDate() -> String
    /// トリミング処理
    func trimming(image: UIImage, isVertical: Bool) throws -> UIImage
    /// 点検データを更新する
    func updateInspectionDataStatus() throws
}

// MARK: - PreviewViewModel
/// プレビュー画面のVIew Model
final class PreviewViewModel {
    
    // MARK: - Property
    /// オリジナル画像保存用ファイルパス
    private var originalFilePath: String?
    /// トリミング画像保存用ファイルパス
    private var trimmingFilePath: String?
    /// S3オリジナルファイルパス
    private var s3OriginalFilePath = ""
    /// S3トリミングファイルパス
    private var s3TrimmingFilePath = ""
    /// トリミングフォルダ名
    private let TRIMMING_FOLDE_NAME: String = "分割画像"
    /// 保存用名
    private let SAVE_IMAGE_NAME: String = "AI判定結果_NGコメント"
    /// 拡張子
    private let JPEG: String = ".jpg"
    /// 端末のキャパシティ（1GB）
    private let CAPACITY: Int = 200000000
    
    // MARK: - Method
    /// 画像保存パス作成
    private func createLocalDataFile() throws {
        do {
            // 点検データ取得
            let inspectionInfo = InspectionViewDataSource.shared.getInspectionViewInfo()
            // nilチェック
            guard let wscd = inspectionInfo.wscd, let itemName = inspectionInfo.inspectionItemName, let inspectionName = inspectionInfo.inspectionName else {
                throw ErrorID.ID9999
            }
            
            // 階層
            let hierarchy = "\(FOLDER_NAME)/\(Date().toJst(format: DATE_S3_FORMAT_LOCAL))/\(inspectionName)/\(wscd)/"
            // トリミング画像を入れるパス
            let trimingHierarchy = "\(hierarchy)\(TRIMMING_FOLDE_NAME)/"
            // 保存先にフォルダがなければ作成
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask ).first {
                let folderName = dir.appendingPathComponent( trimingHierarchy , isDirectory: true)
                do {
                    try FileManager.default.createDirectory( at: folderName, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    // 保存失敗
                    throw error
                }
            }
            
            // 解析種別によってファイルパスを設定
            switch PreviewDataSource.shared.getPreviewInfo().analysisType {
                // AI判定またはOCRを行う場合
            case INSPECTION_ITEM_TYPE.AI.rawValue, INSPECTION_ITEM_TYPE.OCR.rawValue:
                self.originalFilePath = "\(hierarchy)\(PreviewDataSource.shared.getPreviewInfo().date.toJst(format: SAVE_DATE_FORMAT))_\(itemName)_\(SAVE_IMAGE_NAME)\(JPEG)"
                self.trimmingFilePath = "\(hierarchy)\(TRIMMING_FOLDE_NAME)/\(PreviewDataSource.shared.getPreviewInfo().date.toJst(format: SAVE_DATE_FORMAT))_\(itemName)_\(SAVE_IMAGE_NAME)\(JPEG)"
                //その他
            default:
                self.originalFilePath = "\(hierarchy)\(PreviewDataSource.shared.getPreviewInfo().date.toJst(format: SAVE_DATE_FORMAT))_\(itemName)\(JPEG)"
                self.trimmingFilePath = "\(hierarchy)\(TRIMMING_FOLDE_NAME)/\(PreviewDataSource.shared.getPreviewInfo().date.toJst(format: SAVE_DATE_FORMAT))_\(itemName)\(JPEG)"
            }
        } catch {
            throw ErrorID.ID9999
        }
    }
    
    /// S3保存パス作成
    /// - Returns: パス
    private func createS3Path() throws {
        // 点検データ取得
        let inspectionInfo = InspectionViewDataSource.shared.getInspectionViewInfo()
        // nilチェック
        guard let wscd = inspectionInfo.wscd,
              let itemName = inspectionInfo.inspectionItemName,
              let companyCD = inspectionInfo.companyCD,
              let baseCD = inspectionInfo.baseCD,
              let inspectionName = InspectionViewDataSource.shared.getInspectionViewInfo().inspectionName
        else {
            throw ErrorID.ID9999
        }
        // 「分割画像」のエンコード
        let trimmingFolderName = TRIMMING_FOLDE_NAME
        // 日付取得
        let pathDate = Date().toJst(format: DATE_S3_FORMAT)
        // 解析種別によってファイルパスを設定
        switch PreviewDataSource.shared.getPreviewInfo().analysisType {
            // AI判定またはOCRを行う場合
        case INSPECTION_ITEM_TYPE.AI.rawValue, INSPECTION_ITEM_TYPE.OCR.rawValue:
            let fileName = "\(PreviewDataSource.shared.getPreviewInfo().date.toJst(format: SAVE_DATE_FORMAT))_\(itemName)_\(SAVE_IMAGE_NAME)"
            // オリジナルパスの保存
            self.s3OriginalFilePath = "\(inspectionName)/\(companyCD)/\(baseCD)/\(pathDate)/\(wscd)/\(fileName)\(JPEG)"
            // トリミングパスの保存
            self.s3TrimmingFilePath = "\(inspectionName)/\(companyCD)/\(baseCD)/\(pathDate)/\(wscd)/\(trimmingFolderName)/\(fileName)\(JPEG)"
            // 上記以外
        default:
            let fileName = "\(PreviewDataSource.shared.getPreviewInfo().date.toJst(format: SAVE_DATE_FORMAT))_\(itemName)"
            // オリジナルパスの保存
            self.s3OriginalFilePath = "\(inspectionName)/\(companyCD)/\(baseCD)/\(pathDate)/\(wscd)/\(fileName)\(JPEG)"
            // トリミングパスの保存
            self.s3TrimmingFilePath = "\(inspectionName)/\(companyCD)/\(baseCD)/\(pathDate)/\(wscd)/\(trimmingFolderName)/\(fileName)\(JPEG)"
        }
    }
    
    /// ローカルへ画像の保存
    ///  - Parameter image: 画像イメージ
    private func saveImageToLocalDirectory(originalImage: UIImage, trimmingImage: UIImage) throws {
        do {
            // オリジナルイメージデータ
            var originalImageData: Data?
            // トリミングイメージデータ
            let trimingImageData = trimmingImage.jpegData(compressionQuality: SAVE_IMAGE_QUALITY)
            // 撮影した画面の向きに合わせて画像データの作成
            if originalImage.size.width < originalImage.size.height {
                // 画像サイズを設定（720×1280）
                originalImageData = originalImage.resize(width: RESOLUTION_720, height: RESOLUTION_1280).jpegData(compressionQuality: SAVE_IMAGE_QUALITY)
            } else {
                // 画像サイズを設定（1280×720）
                originalImageData = originalImage.resize(width: RESOLUTION_1280, height: RESOLUTION_720).jpegData(compressionQuality: SAVE_IMAGE_QUALITY)
            }
            
            // 画像を保存
            guard let originalFilePaath = self.originalFilePath, let trimingFilePaath = self.trimmingFilePath else {
                errorLog(message: "ドキュメント情報取得失敗", error: nil)
                // エラーを返却
                throw ErrorID.ID9999
            }
            let originalPath = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(originalFilePaath)
            let trimingPath = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(trimingFilePaath)
            try originalImageData?.write(to: originalPath)
            try trimingImageData?.write(to: trimingPath)
        } catch {
            // 保存失敗
            throw error
        }
    }
    
    /// ローカルDBに点検項目情報を更新
    private func updateInspectionItemData(isS3Successed: Bool) throws {
        do {
            // 点検項目UUID取得
            guard let inspectionItemUUID = InspectionViewDataSource.shared.getInspectionViewInfo().inspectionItemUUID else {
                throw ErrorID.ID9999
            }
            // 対象の点検項目データを取得する
            let inspectionItemData = try RealmService.shared.getInspectionItemData(inspectionItemUUID: inspectionItemUUID)
            // 進捗判断
            var progress = isS3Successed ? INSPECTION_PROGRESS.IMAGE_SAVED_REMOTE.rawValue : INSPECTION_PROGRESS.IMAGE_SAVED_LOCAL.rawValue
            if isS3Successed {
                progress = (inspectionItemData.analysis_type == "ai" || inspectionItemData.analysis_type == "ocr") ? progress : INSPECTION_PROGRESS.ANALYSIS_COMPLETED.rawValue
            }
            // 点検項目IDに紐づく点検項目を更新
            try RealmService.shared.updateSaveImageProcess(inspectionItemUUID: inspectionItemUUID,
                                                           takenAt: PreviewDataSource.shared.getPreviewInfo().date.toJst(format: DRAW_DATE_FORMAT),
                                                           localOriginalImagePath: self.originalFilePath ?? "",
                                                           localTrimingImagePath: self.trimmingFilePath ?? "",
                                                           s3OriginalImagePath: self.s3OriginalFilePath,
                                                           s3TrimingImagePath: self.s3TrimmingFilePath,
                                                           progress: progress)
        } catch {
            throw error
        }
    }
    
    /// 点検項目に応じたトリミング座標を取得
    /// - Returns: [縦横判定用文字列 : フレーム設定値]
    private func getTrimmingPosition(isVertical: Bool) -> CGRect? {
        // プレビュー情報の取得
        let previewInfo = PreviewDataSource.shared.getPreviewInfo()
        // 該当する設定ファイルを取得し、トリミング座標を返す
        let trimmingPositionData: Coordinate? = SettingDatasource.shared.getTrimmingPositionCoodinateInfo(inspectionNameId: InspectionViewDataSource.shared.getInspectionViewInfo().inspectionNameID, inspectionItemNameId: previewInfo.inspectionItemNameID, isVertical: isVertical)
        // トリミング座標情報がnilならnilを返す
        guard let trimmingPosition = trimmingPositionData else { return nil }
        return CGRectMake(CGFloat(trimmingPosition.x), CGFloat(trimmingPosition.y), CGFloat(trimmingPosition.width), CGFloat(trimmingPosition.height))
    }
}

// MARK: - PreviewViewModelProtocol
extension PreviewViewModel: PreviewViewModelProtocol {
    
    /// 容量確認
    func checkCapacity() throws {
        let fileURL = URL(fileURLWithPath:"/")
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            // ストレージの保存容量を取得
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                // 1GB以下になったら警告を出す
                if capacity <= CAPACITY {
                    errorLog(message: "端末容量不足", error: nil)
                    // エラーを返却
                    throw ErrorID.ID9999
                }
            } else {
                errorLog(message: "端末容量不足", error: nil)
                // エラーを返却
                throw ErrorID.ID9999
            }
        } catch {
            throw error
        }
    }
    
    /// ローカルへの画像保存
    func saveImageToLocal(originalImage: UIImage, trimmingImage: UIImage) throws {
        do {
            // 保存先パスの作成
            try self.createLocalDataFile()
            // S3保存作パスの作成
            try self.createS3Path()
            // 画像を保存
            try self.saveImageToLocalDirectory(originalImage: originalImage, trimmingImage: trimmingImage)
            // ローカルDBの更新
            try self.updateInspectionItemData(isS3Successed: false)
        } catch {
            throw error
        }
    }
    
    /// クラウドへの画像保存
    func saveImageToRemote(success: @escaping() -> Void, failure: @escaping(Error?) -> Void) {
        
        // 画像保存用
        var originalImage: UIImage?
        var trimmingImage: UIImage?
        
        // ローカル上から送信画像を取得する
        if let fileName = self.originalFilePath {
            if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(fileName) {
                if let data = try? Data(contentsOf: url) {
                    originalImage = UIImage(data: data)
                }
            }
        }
        
        if let fileName = self.trimmingFilePath {
            if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(fileName) {
                if let data = try? Data(contentsOf: url) {
                    trimmingImage = UIImage(data: data)
                }
            }
        }
        
        // 画像の存在確認
        guard let originalImage = originalImage , let trimmingImage = trimmingImage else {
            failure(ErrorID.ID9999)
            return
        }
        
        // S3にオリジナル画像を保存
        ApiService.shared.saveS3ImageApi(path: self.s3OriginalFilePath, image: originalImage) {
            // S3にトリミング画像を保存
            ApiService.shared.saveS3ImageApi(path: self.s3TrimmingFilePath, image: trimmingImage) {
                do {
                    // ローカルDBの更新
                    try self.updateInspectionItemData(isS3Successed: true)
                    success()
                } catch {
                    failure(error)
                }
                
            } failureHandler: { error in
                failure(error)
            }
        } failureHandler: { error in
            failure(error)
        }
    }
    
    /// プレビュー情報の取得
    /// - Returns: プレビュー情報
    func getPreviewInfo() -> PreviewInfo {
        return PreviewDataSource.shared.getPreviewInfo()
    }
    
    /// 点検項目名の取得
    /// - Returns: 点検項目名
    func getItemName() -> String {
        return InspectionViewDataSource.shared.getInspectionViewInfo().inspectionItemName
    }
    
    /// お客様名の取得
    /// - Returns: お客様名
    func getClientName() -> String {
        return InspectionViewDataSource.shared.getInspectionViewInfo().customerName
    }
    
    /// wscdの取得
    /// - Returns: wscd
    func getWorkSheetCode() -> String {
        return InspectionViewDataSource.shared.getInspectionViewInfo().wscd
    }
    
    /// 撮影日時の取得
    ///- Returns: 撮影日時
    func getDate() -> String {
        return InspectionViewDataSource.shared.getInspectionViewInfo().inspectionDate
    }
    
    /// トリミング処理
    func trimming(image: UIImage, isVertical: Bool) throws -> UIImage {
     
        // 画像をリサイズ
        let resizeImage = isVertical ? image.resize(width: RESOLUTION_720, height: RESOLUTION_1280) : image.resize(width: RESOLUTION_1280, height: RESOLUTION_720)
        guard let trimmingArea = self.getTrimmingPosition(isVertical: isVertical) else {
            // トリミング情報がない場合はトリミングを行わず元の画像を返却
            return resizeImage
        }
        guard let imgRef = resizeImage.cgImage?.cropping(to: trimmingArea) else { throw ErrorID.ID0025 }
        let trimImage = UIImage(cgImage: imgRef, scale: resizeImage.scale, orientation: resizeImage.imageOrientation)
        return trimImage
    }
    
    /// 点検データを更新する
    func updateInspectionDataStatus() throws {
        // 点検infoの状態を更新
        if InspectionViewDataSource.shared.getInspectionViewInfo().status == INSPECTION_STATUS.WAITING.rawValue {
            // 撮影待ちになっていたらinfoの状態を点検中にする
            InspectionViewDataSource.shared.setStatus(status: INSPECTION_STATUS.UNDER_INSPECTION.rawValue)
            // RealmDBの状態を更新
            try RealmService.shared.updateInspectionDataStatus(inspectionID: InspectionViewDataSource.shared.getInspectionViewInfo().inspectionId, status: INSPECTION_STATUS.UNDER_INSPECTION.rawValue)
        }
    }
}
