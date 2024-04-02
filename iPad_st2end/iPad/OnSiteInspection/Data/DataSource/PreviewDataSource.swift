import UIKit
import AVFoundation
import Combine

/// プレビューのサービスクラス
class PreviewDataSource: NSObject {
    /// シングルトン
    private override init() {}
    public static let shared = PreviewDataSource()
    
    /// プレビュー情報
    var previewInfo = PreviewInfo()
    /// カメラ情報
    var cameraInfo: CameraInfo! { get { return CameraService.shared.cameraInfo } }
    
    /// プレビュー情報の設定
    /// - Parameters:
    /// - photo : 撮影データ
    /// - date : 日付
    func setPreviewInfo(photo: AVCapturePhoto, date: Date) throws {
    
        // 撮影情報がない場合
        guard let imageData = photo.fileDataRepresentation() else {
            errorLog(message: "撮影情報取得失敗", error: ErrorCause.noObject)
            // エラーを返却
            throw ErrorID.ID0024
        }
        
        // 画像の向きを判定し、修正する向きを設定
        let imageOrientation: UIImage.Orientation = {
            switch getDeviceOrientation(){
            case .DOWN:
                return .right
            case .RIGHT:
                return self.cameraInfo.isUsedInnerCamera ? .down : .up
            case .LEFT:
                return self.cameraInfo.isUsedInnerCamera ? .up : .down
            case .UP:
                return .left
            }
        }()
        
        // UIImageを生成
        let image = UIImage(cgImage: UIImage(data: imageData)!.cgImage!,
                            scale: 1.0,
                            orientation: imageOrientation)
        
        self.previewInfo.setPreviewInfo(image: image, date: date)
    }
    
    /// プレビュー情報の取得
    /// - Returns: プレビュー情報
    func getPreviewInfo() -> PreviewInfo {
        return self.previewInfo
    }
    
    /// 解析種別の設定
    /// - Parameter type: 解析種別
    func setAnalysisType(type: String?) {
        self.previewInfo.setAnalysisType(type: type)
    }
    
    /// 点検項目名IDを設定
    /// - Parameter inspectionItemNameID: 点検項目名ID
    func setInspectionItemNameID(inspectionItemNameID: Int?) {
        self.previewInfo.setInspectionItemNameID(inspectionItemNameID: inspectionItemNameID)
    }
}
