import AVFoundation

struct CameraInfo {
    /// デバイスからの入力と出力を管理するオブジェクトの作成
    var captureSession: AVCaptureSession = AVCaptureSession()
    /// メインカメラの管理オブジェクトの作成
    var mainCamera: AVCaptureDevice? = nil
    /// インカメの管理オブジェクトの作成
    var innerCamera: AVCaptureDevice? = nil
    /// 現在使用しているカメラデバイスの管理オブジェクトの作成
    var currentDevice: AVCaptureDevice? = nil
    /// キャプチャーの出力データを受け付けるオブジェクト
    var photoOutput: AVCapturePhotoOutput? = nil
    /// デバイス指定用オブジェクト
    var captureDeviceInput: AVCaptureDeviceInput? = nil
    /// プレビュー表示用のレイヤ
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer? = nil
    /// 初期設定済みかどうか
    var isInitialized: Bool = false
    /// インナーカメラを使用しているか
    var isUsedInnerCamera: Bool { get { self.currentDevice == self.innerCamera }}
    
    // カメラの設定
    mutating func setCameraPreviewLayer(devices: [AVCaptureDevice]) throws {
        do{
            // 解像度を設定
            self.captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
            // 外カメラと内カメラを設定
            for device in devices {
                if device.position == AVCaptureDevice.Position.back {
                    self.mainCamera = device
                } else if device.position == AVCaptureDevice.Position.front {
                    self.innerCamera = device
                }
            }
            // 起動時のカメラを設定
            self.currentDevice = self.mainCamera
            // 指定したデバイスを使用するために入力を初期化
            self.captureDeviceInput = try AVCaptureDeviceInput(device: self.currentDevice!)
            // 指定した入力をセッションに追加
            self.captureSession.addInput(self.captureDeviceInput!)
            // 出力データを受け取るオブジェクトの作成
            self.photoOutput = AVCapturePhotoOutput()
            // 出力ファイルのフォーマットを指定
            self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
            // 指定した入力をセッションに追加
            self.captureSession.addOutput(photoOutput!)
            // プレビューレイヤの初期化
            self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            // プレビューレイヤが、カメラのキャプチャーを縦横比を維持した状態で、表示するように設定
            self.cameraPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspect
            // プレビューレイヤの表示の向きを設定(90でホームボタンの位置下)
            self.cameraPreviewLayer!.connection?.videoRotationAngle = CGFloat(90)
            // 初期設定
            self.isInitialized = true
        } catch {
            throw error
        }
    }
    
    /// カメラの切り替え
    mutating func switchCamera() throws {
        do{
            // セッションのデバイス情報を削除
            self.captureSession.removeInput(self.captureDeviceInput!)
            // カメラを切り替え
            if (self.currentDevice == self.innerCamera) { self.currentDevice = self.mainCamera } else { self.currentDevice = self.innerCamera }
            // 指定したデバイスを使用するために入力を初期化
            self.captureDeviceInput = try AVCaptureDeviceInput(device: self.currentDevice!)
            // 指定した入力をセッションに追加
            self.captureSession.addInput(self.captureDeviceInput!)
        } catch {
            throw error
        }
    }
    
    /// カメラの向きを設定
    mutating func setCameraOrientation(rotation: CGFloat) {
        // カメラの向きを画面の向きにあわせて修正
        self.cameraPreviewLayer?.transform = CATransform3DMakeRotation( rotation / 180 * CGFloat.pi, 0, 0, 1)
    }
}
