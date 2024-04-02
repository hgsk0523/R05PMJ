import UIKit
import AVFoundation
import Combine

/// カメラのサービスクラス
class CameraService: NSObject {
    /// シングルトン
    private override init() {}
    public static let shared = CameraService()
    
    /// カメラ情報
    var cameraInfo = CameraInfo()
    
    /// カメラ情報の設定
    func setCameraInfo() throws {
        do{
            // カメラの設定が終わっているかの確認
            if self.cameraInfo.isInitialized {
                return
            }
            // カメラデバイスのプロパティ設定
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                mediaType: AVMediaType.video,
                position: AVCaptureDevice.Position.unspecified)
            // カメラ情報の設定
            try self.cameraInfo.setCameraPreviewLayer(devices: deviceDiscoverySession.devices)
            
        } catch {
            errorLog(message: "カメラ情報の設定失敗", error: error)
            throw error
        }
    }
    
    /// カメラを切り替える
    func switchCamera() throws {
        do{
            // カメラの切り替え
            try self.cameraInfo.switchCamera()
        } catch {
            errorLog(message: "カメラの切り替え失敗", error: error)
            throw error
        }
    }

    /// カメラの向きを設定
    func setCameraOrientation() {
        // ロード時からいくら回転したかを取得
        let rotation: CGFloat = CGFloat(getDeviceOrientation().rawValue) * 90
        
        // カメラの向きを画面の向きにあわせて修正
        self.cameraInfo.setCameraOrientation(rotation: rotation)
    }
    
    /// セッションの開始
    func sessionStart() throws {
        // カメラの設定が終わっているかの確認
        if !self.cameraInfo.isInitialized {
            // エラーを返却
            throw ErrorID.ID9999
        }
        // バックグラウンドでセッション開始
        DispatchQueue.global(qos: .background).async {
            self.cameraInfo.captureSession.startRunning()
        }
        // 待機処理
        Thread.sleep(forTimeInterval: 0.3)
    }

    /// セッションの停止
    func sessionStop() throws {
        // カメラの設定が終わっているかの確認
        if !self.cameraInfo.isInitialized {
            // エラーを返却
            throw ErrorID.ID9999
        }
        self.cameraInfo.captureSession.stopRunning()
    }
    
    /// プレビューレイヤの取得
    /// - Returns: プレビューレイヤー
    func getCameraPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return self.cameraInfo.cameraPreviewLayer
    }
    
    /// 撮影
    /// - Parameter avCapturePhotoCaptureDelegate: デリゲート
    func shoot(avCapturePhotoCaptureDelegate: AVCapturePhotoCaptureDelegate) {
        let settings = AVCapturePhotoSettings()
        // フラッシュの設定
        settings.flashMode = .off
        // 撮影された画像をdelegateメソッドで処理
        self.cameraInfo.photoOutput?.capturePhoto(with: settings, delegate: avCapturePhotoCaptureDelegate)
    }
    
    /// カメラの権限のチェック
    /// - Returns: 権限の有無
    func checkCameraPermission() -> Bool {
        // カメラの使用許可の結果
        var result = false
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined: // ユーザーが許可の選択をまだしていない
            let semaphore = DispatchSemaphore(value: 0)
            
            // カメラの使用の許可を求めるダイアログを表示
            AVCaptureDevice.requestAccess(for: .video) { granted in
                // カメラの使用可否を取得
                result = granted
                semaphore.signal()
            }
            // ユーザーが権限の可否を選択するまで待機
            semaphore.wait()
            
            // アプリがカメラの使用を許可していない or デバイスにカメラが存在しない
        case .restricted:
            result = false
            // ユーザーが拒否をしている
        case .denied:
            result = false
            // ユーザーが許可をしている
        case .authorized:
            result = true
        @unknown default:
            result = false
        }
        return result
    }

}


