import UIKit
import AVFoundation

// MARK: - CameraViewModelProtocol
/// 撮影画面のViewModelのプロトコル
protocol CameraViewModelProtocol {
    //MARK: - ゲッター
    /// カメラ表示レイヤーの取得
    func getCameraLayer() throws -> AVCaptureVideoPreviewLayer?
    /// 撮影例説明画面の取得
    func getDescriptionOfShooting() -> UIView?
    /// 点検項目に応じたフレームを取得
    func getInspectionItemFrame(isVertical: Bool) -> CGRect?
    /// インナーカメラ使用状態の取得
    func getUsedInnerCameraState() -> Bool
    /// 点検情報を取得
    func getInspectionViewInfo() -> InspectionViewInfo
    
    //MARK: - セッター
    /// カメラの向きを設定
    func setCameraOrientation()
    /// プレビュー情報の設定
    func setPreviewInfo(photo: AVCapturePhoto, date: Date) throws
    /// 初期設定
    func setDescriptionOfShootingInfo() throws
    
    //MARK: - その他
    /// セッションの開始
    func sessionStart() throws
    /// セッションの停止
    func sessionStop()
    /// 使用カメラ変更
    func switchCamera() throws
    /// 撮影
    func shoot(avCapturePhotoCaptureDelegate: AVCapturePhotoCaptureDelegate)
    // 撮影例画像の保存
    func saveExplanationImage() throws
    /// カメラの権限確認
    func checkCameraPermission() -> Bool
}

// MARK: - CameraViewModel
/// 撮影画面のViewModel
final class CameraViewModel {
    /// カメラプレビュー表示用レイヤー
    private var avCaptureVideoPreviewLayer: AVCaptureVideoPreviewLayer?
    /// 撮影例説明画面用UIVIew
    private var descriptionOfShootingView: UIView?
    
    /// ローカル画像に保存されている撮影例画像の存在チェック
    private func checkExplanationImage() throws -> [TBL_M_SAMPLE_PHOTO] {
        do {
            // 返却用リスト
            var response: [TBL_M_SAMPLE_PHOTO] = []
            // nilチェック
            guard let inspectionNameID = InspectionViewDataSource.shared.getInspectionViewInfo().inspectionNameID else {
                throw ErrorID.ID9999
            }
            // Realmから該当の撮影例サンプルデータを取得
            let exampleImageData = try RealmService.shared.getExampleImageData(inspectionNameID: inspectionNameID,
                                                                               inspectionItemNameID: PreviewDataSource.shared.getPreviewInfo().inspectionItemNameID)
            
            // 撮影例テーブル分リストに追加
            exampleImageData?.forEach { exampleData in
                // ローカル画像の存在確認
                guard let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(FOLDER_NAME_EXSAMPLE_IMAGE)\(exampleData.local_image_path)\(exampleData.filename_name)") else {
                    // 存在しない画像のファイルパスを追加
                    response.append(exampleData)
                    return
                }

                guard let _ = try? UIImage(data: Data(contentsOf: url)) else {
                    // 存在しない画像のファイルパスを追加
                    response.append(exampleData)
                    return
                }
            }
            
            // 存在しない項目のパスリストを返却
            return response
        } catch {
            throw error
        }
    }
}

// MARK: - CameraViewModel

extension CameraViewModel:CameraViewModelProtocol {
    // MARK: - ゲッター
    /// カメラ表示レイヤーの取得
    /// - Returns: カメラ表示レイヤー
    func getCameraLayer() throws -> AVCaptureVideoPreviewLayer? {
        do{
            // カメラ情報の設定
            try CameraService.shared.setCameraInfo()
            // 表示画面の設定
            self.avCaptureVideoPreviewLayer = CameraService.shared.getCameraPreviewLayer()
            
            return self.avCaptureVideoPreviewLayer
                
        } catch {
            // エラー返却
            throw error
        }
    }
    
    /// 撮影例説明画面の取得
    /// - Returns: 撮影例説明画面
    func getDescriptionOfShooting() -> UIView? {
        self.descriptionOfShootingView = DescriptionOfShootingService.shared.createDescriptionOfShootingView()
        return self.descriptionOfShootingView
    }
    
    /// 点検項目に応じたフレームを取得
    /// - Returns: [縦横判定用文字列 : フレーム設定値]
    func getInspectionItemFrame(isVertical: Bool) -> CGRect? {
        // プレビュー情報の取得
        let previewInfo = PreviewDataSource.shared.getPreviewInfo()
        // 該当する設定ファイルを取得し、フレームを返す
        let guideFrameData: Coordinate? = SettingDatasource.shared.getGuideFrameCoodinateInfo(inspectionNameId: InspectionViewDataSource.shared.getInspectionViewInfo().inspectionNameID, inspectionItemNameId: previewInfo.inspectionItemNameID, isVertical: isVertical)
        // ガイド枠情報がnilならnilを返す
        guard let guideFrameData = guideFrameData else { return nil }
        return CGRectMake(CGFloat(guideFrameData.x), CGFloat(guideFrameData.y), CGFloat(guideFrameData.width), CGFloat(guideFrameData.height))
    }
    
    /// インナーカメラ使用状態の取得
    func getUsedInnerCameraState() -> Bool {
        return CameraService.shared.cameraInfo.isUsedInnerCamera
    }
    
    /// 点検情報を取得
    func getInspectionViewInfo() -> InspectionViewInfo {
        return InspectionViewDataSource.shared.getInspectionViewInfo()
    }
    
    // MARK: - セッター
    /// カメラの向きを設定
    func setCameraOrientation() {
        CameraService.shared.setCameraOrientation()
    }
    
    /// プレビュー情報の設定
    ///　- Parameters
    ///　- photo: 撮影データ
    ///　- data: 撮影日時
    func setPreviewInfo(photo: AVCapturePhoto, date: Date) throws {
        do {
            try PreviewDataSource.shared.setPreviewInfo(photo: photo, date:date)
        } catch {
            // エラー返却
            throw error
        }
    }
    
    /// 初期設定
    func setDescriptionOfShootingInfo() throws {
        do {
            // 撮影例情報保存用
            var info: [ExplanationInfo] = []
            // Realmから該当の撮影例サンプルデータを取得
            let exampleImageData = try RealmService.shared.getExampleImageData(inspectionNameID: InspectionViewDataSource.shared.getInspectionViewInfo().inspectionNameID,
                                                                               inspectionItemNameID: PreviewDataSource.shared.getPreviewInfo().inspectionItemNameID)
            
            // 撮影例テーブル分リストに追加
            try exampleImageData?.forEach { exampleData in
                var uiImage: UIImage? = nil
                // 画像をローカルから取得
                let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(FOLDER_NAME_EXSAMPLE_IMAGE)\(exampleData.local_image_path)\(exampleData.filename_name)")

                if let data = try? Data(contentsOf: url) {
                    uiImage = UIImage(data: data)
                }
                
                if uiImage != nil {
                    // 撮影例説明情報を追加
                    info.append(ExplanationInfo(image: uiImage!, explanation: exampleData.explanation))
                } else {
                    info.append(ExplanationInfo(image: UIImage(named: "noImage")!, explanation: exampleData.explanation))
                }
            }
            if let title = InspectionViewDataSource.shared.getInspectionViewInfo().inspectionItemName {
                DescriptionOfShootingService.shared.setDescriptionOfShootingInfo(title: title , explanationInfo: info)
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - その他
    /// セッションの開始
    func sessionStart() throws {
        do {
            try CameraService.shared.sessionStart()
        } catch {
            // エラー返却
            throw error
        }
    }
    
    /// セッションの停止
    func sessionStop() {
        try? CameraService.shared.sessionStop()
    }
    
    /// 使用カメラ設定
    func switchCamera() throws {
        do {
            try CameraService.shared.switchCamera()
        } catch {
            // エラー返却
            throw error
        }
    }
    
    /// 撮影
    /// - Parameter avCapturePhotoCaptureDelegate: デリゲート
    func shoot(avCapturePhotoCaptureDelegate: AVCapturePhotoCaptureDelegate) {
        CameraService.shared.shoot(avCapturePhotoCaptureDelegate: avCapturePhotoCaptureDelegate)
    }
    
    /// 撮影例画像の保存
    func saveExplanationImage() throws {
        do {
            // 画像の存在確認
            let samplePhotoData = try self.checkExplanationImage()

            // 画像の取得
            samplePhotoData.forEach { photodata in
                var uiImage: UIImage? = nil
                var delayFlag = true
                // 撮影例画像をS3から取得
                ApiService.shared.getS3ImageData(bucketName: S3_BUCKET_NAME, s3Path: photodata.s3_image_path + photodata.filename_name) { image in
                    uiImage = image
                    delayFlag = false
                } failureHandler: { _ in
                    // エラーの場合待機せずに処理を抜ける
                    delayFlag = false
                }
                // 画像取得完了まで待機
                repeat {
                } while delayFlag == true
                
                try? SettingService.shared.saveExampleImageToDevice(image: uiImage, fileName: photodata.filename_name, filePath: photodata.local_image_path)
            }
        } catch {
            throw error
        }
    }
    
    /// カメラの権限確認
    func checkCameraPermission() -> Bool {
        return CameraService.shared.checkCameraPermission()
    }
}

