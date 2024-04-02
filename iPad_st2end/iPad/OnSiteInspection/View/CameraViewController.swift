import UIKit
import AVFoundation

/// 撮影画面のViewController
final class CameraViewController: UIViewController {
    
    // MARK: - Injection
    /// ViewModel
    var viewModel: CameraViewModelProtocol!
    
    // MARK: - Property
    /// カメラ画面表示用UI
    @IBOutlet weak var cameraView: UIView!
    /// アシスト図形表示用UI
    @IBOutlet weak var rectView: UIView!
    /// 撮影ボタン
    @IBOutlet weak var shootingButton: UIButton!
    /// 切り替えボタン
    @IBOutlet weak var switchButton: CustomButton!
    /// 撮影例表示ボタン
    @IBOutlet weak var showDescriptionOfShootinButton: CustomButton!
    /// 撮影例表示用UI
    private var descriptionOfShootingView: UIView?
    /// カメラ表示用レイヤー
    private var cameraLayer: AVCaptureVideoPreviewLayer?
    /// 画面名
    private let SCREEN_NAME: String = "撮影画面"
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            // 180度回転した際にカメラの向き変更が行われないため、専用に処理を記載する
            NotificationCenter.default.addObserver(self, selector: #selector(CameraViewController.onOrientationDidChange(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)
            // カメラの権限チェック
            self.checkCameraPermissions()
            // カメラ表示レイヤーの取得
            self.cameraLayer = try self.viewModel.getCameraLayer()
            // nilチェック
            if let layer = self.cameraLayer {
                // 表示するレイヤーを追加
                self.cameraView.layer.addSublayer(layer)
            }
        } catch {
            // エラー表示
            errorDialog(error: ErrorID.ID0019, vc: self, handler: { _ in
                // 前の画面に戻る
                self.navigationController?.popViewController(animated: true)
            })
        }
    }
    
    /// 画面が表示される時
    override func viewWillAppear(_ animated: Bool) {
        infoLog(screen: SCREEN_NAME, logMessage: "画面表示")
        do {
            // 画面の固定解除
            self.lockOrientation(UIInterfaceOrientationMask.all)
            // セッションの開始
            try self.viewModel.sessionStart()
            // ナビゲーションバーの設定
            NavigationBarController.shared.setNavigationBar(viewController: self, isUsedNavigationBar: false)
            // 撮影例ボタンの制御
            self.setActivationShowDescriptionOfShootinButton()
        } catch {
            // エラー表示
            errorDialog(error: ErrorID.ID0019, vc: self, handler: { _ in
                // 前の画面に戻る
                self.navigationController?.popViewController(animated: true)
            })
        }
    }
    
    /// 画面が非表示になった時
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.viewModel.sessionStop()
    }
    
    /// レイアウト終了直後の処理
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // カメラの向きを調整する
        self.viewModel.setCameraOrientation()
        // カスタムビューとレイヤーの表示場所を調整
        self.cameraLayer?.frame = self.cameraView.bounds
        // 撮影例表示画面の表示座標修正（撮影例表示中のみ）
        self.descriptionOfShootingView?.frame = self.view.bounds
        // 画面の向きに応じてガイド枠の位置を調整
        self.setRectView(orientation: getDeviceOrientation())
      }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // インジケータ停止
        self.dismissIndicator()
    }
    
    // MARK: - Action
    /// 撮影例表示ボタン押下時
    @IBAction func onTapShowDescriptionOfShootinButton(_ sender: Any) {
        infoLog(screen: SCREEN_NAME, logMessage: "撮影例ボタン押下")
        //　現在の画面の向きに固定
        switch getDeviceOrientation() {
        case .LEFT, .RIGHT:
            // 横向きに固定
            self.lockOrientation(UIInterfaceOrientationMask.landscape)
        case .DOWN, .UP:
            // 縦向きに固定
            self.lockOrientation(UIInterfaceOrientationMask.portrait)
        }
        // インジケータの表示
        self.showIndicator()
        do {
            
            // 撮影例画像の保存
            try? self.viewModel.saveExplanationImage(handler: {
                // ローカルの撮影例のデータを設定
                try? self.viewModel.setDescriptionOfShootingInfo()
                // ローカルにある撮影例を表示する
                if let descriptionOfShootingView = self.viewModel.getDescriptionOfShooting() {
                    self.descriptionOfShootingView = descriptionOfShootingView
                    self.descriptionOfShootingView!.frame = self.view.bounds
                    self.view.addSubview(self.descriptionOfShootingView!)
                    // インジケータの非表示
                    self.dismissIndicator()
                } else {
                    // インジケータの非表示
                    self.dismissIndicator()
                    // エラー表示
                    errorDialog(error: ErrorID.ID0023, vc: self, handler: nil)
                }
            })
            
        }
    }
    
    /// 切り替えボタン押下時
    @IBAction func onTapSwitchButton(_ sender: Any) {
        infoLog(screen: SCREEN_NAME, logMessage: "切り替えボタン押下")
        // 連続押下を禁止する
        self.switchButton.isEnabled = false
        // 1秒後に再度押下可能にする
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(1)){
            self.switchButton.isEnabled = true
        }
        do {
            // インナーカメラとアウトカメラを入れ替える
            try self.viewModel.switchCamera()
            // ガイド枠設定
            self.setRectView(orientation: getDeviceOrientation())
        } catch {
            // エラー表示
            errorDialog(error: ErrorID.ID0021, vc: self, handler: { _ in
                // 前の画面に戻る
                self.navigationController?.popViewController(animated: true)
            })
        }
    }
    
    ///撮影ボタン押下時
    @IBAction func onTapShootingButton(_ sender: Any) {
        infoLog(screen: SCREEN_NAME, logMessage: "撮影ボタン押下")
        // 連続押下を禁止する
        self.shootingButton.isEnabled = false
        // 1秒後に再度押下可能にする
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(1)){
            self.shootingButton.isEnabled = true
        }
        // 撮影する
        self.viewModel.shoot(avCapturePhotoCaptureDelegate: self)
    }
    
    // MARK: - Method
    /// 回転時の処理
    @objc
    private func onOrientationDidChange(notification: NSNotification) {
        // カメラの向きを調整する
        self.viewModel.setCameraOrientation()
    }

    /// ガイド枠を設定する
    /// - Parameter orientation:画面の向き
    private func setRectView(orientation: ORIENTATION) {
        // 撮影項目のフレーム値
        var itemFrame: CGRect? = nil
        //　実際のカメラ表示画像の幅
        var width: CGFloat = 0
        // 基準値と実際の画面の比率
        var ratio: CGFloat = 0
        // ガイド枠の幅
        let BORDER_WIDTH: CGFloat = 2.0
        
        switch orientation {
        case .UP, .DOWN:
            // 撮影項目に応じて設定値を取得
            itemFrame = self.viewModel.getInspectionItemFrame(isVertical: true)
            // 横幅の設定
            width = (self.cameraView.frame.height * RESOLUTION_720 / RESOLUTION_1280)
            ratio = width / RESOLUTION_720
        case .RIGHT, .LEFT:
            // 撮影項目に応じて設定値を取得
            itemFrame = self.viewModel.getInspectionItemFrame(isVertical: false)
            // 横幅の設定
            width = (self.cameraView.frame.height * RESOLUTION_1280 / RESOLUTION_720)
            ratio = width / RESOLUTION_1280
        }
        
        // 取得したフレームがnilならフレームを表示しない
        if let frame = itemFrame {
            // 表示する
            self.rectView.isHidden = false
            // カメラーフレームの設定
            // アシスト画像X座標
            var posX = (self.cameraView.frame.width - width) / 2 + (frame.origin.x * ratio)
            // インナーカメラを使用していたら座標を修正
            if self.viewModel.getUsedInnerCameraState() {
                posX = self.cameraView.frame.width - (posX + frame.width * ratio)
            }
            // アシスト画像Y座標
            let posY = self.cameraView.frame.origin.y + (frame.origin.y * ratio)
            // アシスト線を設定
            self.rectView.frame = CGRectMake(posX, posY, frame.width * ratio, frame.height * ratio)
            //枠線の太さを指定
            self.rectView.layer.borderWidth = BORDER_WIDTH
            //枠線の色を指定
            self.rectView.layer.borderColor = UIColor.red.cgColor
            
        } else {
            // 非表示にする
            self.rectView.isHidden = true
        }
    }
    
    /// カメラの権限チェック
    private func checkCameraPermissions() {
        // カメラの権限チェック
        if !(self.viewModel.checkCameraPermission()) {
            // エラー表示
            Alert.okAlert(vc: self, message: DialogMessage.NoCameraPermission.rawValue, handler: { _ in
                // アプリ設定へ遷移
                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                // 前の画面に戻る
                self.navigationController?.popViewController(animated: true)
            })
        }
    }
    
    /// 撮影例ボタンの制御
    private func setActivationShowDescriptionOfShootinButton() {
        // 点検項目名ID(Int)がnilなら、撮影例ボタンを非活性
        if self.viewModel.getInspectionViewInfo().inspectionItemID == nil {
            self.showDescriptionOfShootinButton.isEnabled = false
        }
    }
}

//MARK: - AVCapturePhotoCaptureDelegateデリゲートメソッド
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    /// 撮影した画像データが生成されたときに呼び出されるデリゲートメソッド
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        do {
            // プレビュー情報の設定
            try self.viewModel.setPreviewInfo(photo: photo, date: Date())
            // プレビュー画面に遷移
            if let vc = R.storyboard.previewViewController.instantiateInitialViewController() {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } catch {
            // エラー表示
            errorDialog(error: ErrorID.ID0024, vc: self, handler: nil)
        }
    }
}
