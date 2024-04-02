import UIKit

/// プレビュー画面ViewController
final class PreviewViewController: UIViewController {
    
    // MARK: - Injection
    var viewModel: PreviewViewModelProtocol!
    // MARK: - Property
    /// 点検項目名
    @IBOutlet weak var titleLabel: UILabel!
    /// 撮影画像
    @IBOutlet weak var previewImage: UIImageView!
    /// 詳細情報
    @IBOutlet weak var infoView: UIView!
    /// 画像保存用View
    @IBOutlet weak var saveImageViewHorizon: UIView!
    /// WSCD情報
    @IBOutlet weak var wscdLabel: UILabel!
    /// 日時情報
    @IBOutlet weak var dateLabel: UILabel!
    /// お客様名情報
    @IBOutlet weak var nameLabel: UILabel!
    /// 撮影内容情報
    @IBOutlet weak var contentLabel: UILabel!
    /// 詳細情報格納用View
    @IBOutlet weak var infoStackView: UIStackView!
    /// 撮影画像
    @IBOutlet weak var previewImageVertical: UIImageView!
    /// 詳細情報
    @IBOutlet weak var infoViewVertical: UIView!
    /// 画像保存用View
    @IBOutlet weak var saveImageViewVertical: UIView!
    /// WSCD情報
    @IBOutlet weak var wscdLabelVertical: UILabel!
    /// 日時情報
    @IBOutlet weak var dateLabelVertical: UILabel!
    /// お客様名情報
    @IBOutlet weak var nameLabelVertical: UILabel!
    /// 撮影内容情報
    @IBOutlet weak var contentLabelVertical: UILabel!
    /// 詳細情報格納用View
    @IBOutlet weak var infoStackViewVertical: UIStackView!
    /// 縦横フラグ
    private var isVertical = true
    
    /// 画面名
    private let SCREEN_NAME: String = "プレビュー画面"
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // ナビゲーションバーを設定
        NavigationBarController.shared.setNavigationBarHidden(viewController: self)
        //　縦画面に固定
        self.lockOrientation(UIInterfaceOrientationMask.portrait)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        infoLog(screen: SCREEN_NAME, logMessage: "画面表示")
        // タイトルの設定
        self.titleLabel.text = self.viewModel.getItemName()
        // レイアウトの設定
        self.setLayout()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // インジケータ停止
        self.dismissIndicator()
    }
    
    // MARK: - Action
    /// 再撮影ボタン押下時
    @IBAction func onTapReshootButton(_ sender: Any) {
        infoLog(screen: SCREEN_NAME, logMessage: "再撮影ボタン押下")
        // 撮影画面に戻る
        navigationController?.popViewController(animated: true)
    }
    
    /// 保存ボタン押下時
    @IBAction func onTapSaveButton(_ sender: Any) {
        infoLog(screen: SCREEN_NAME, logMessage: "保存ボタン押下")
        do {
            // デバイスの容量確認
            try viewModel.checkCapacity()
        } catch {
            // エラー表示
            errorDialog(error: ErrorID.ID0033, vc: self, handler: nil)
            // 後続処理を行わない
            return
        }
        
        // ローカルに画像を保存
        do {
            // 保存用オリジナル画像取得
            let originalImage = self.saveImageViewHorizon.isHidden == true ? self.saveImageViewVertical.getImage() : self.saveImageViewHorizon.getImage()
            // トリミング処理
            let trimmingImage = try self.viewModel.trimming(image: originalImage, isVertical: self.isVertical)
            // 画像を保存
            try self.viewModel.saveImageToLocal(originalImage: originalImage, trimmingImage: trimmingImage)
        } catch {
            // エラー表示
            errorDialog(error: error as? ErrorID == ErrorID.ID0025 ? error : ErrorID.ID0026, vc: self, handler: nil)
            // 後続処理を行わない
            return
        }
        
        // インジケータの表示
        self.showIndicator()
        
        // 画像を保存
        self.viewModel.saveImageToRemote() {
            DispatchQueue.main.async {
                // インジケータの非表示
                self.dismissIndicator()
                do {
                    // 点検状態更新
                    try self.viewModel.updateInspectionDataStatus()
                } catch {
                    // エラー表示
                    // 入らない想定
                    errorDialog(error: ErrorID.ID9999, vc: self, handler: nil)
                }
                // 点検項目画面に遷移
                self.showInspection()
            }
        } failure: { error in
            // 画像保存失敗
            // 点検画面に遷移
            DispatchQueue.main.async {
                // インジケータの非表示
                self.dismissIndicator()
                // エラー時処理
                errorDialog(error: ErrorID.ID0027, vc: self, handler: { _ in
                    // 点検項目画面に遷移
                    self.showInspection()
                })
            }
        }
    }
    
    // MARK: - Method
    
    /// 点検項目画面に遷移する
    private func showInspection() {
        // 点検画面に遷移
        DispatchQueue.main.async {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    /// 表示するレイアウトの設定
    private func setLayout() {
        // プレビュー情報取得
        let info = self.viewModel.getPreviewInfo()
        
        // 横画面で撮影されていた場合レイアウトを修正する
        if info.image!.size.width > info.image!.size.height {
            // 画像保存用View
            self.saveImageViewHorizon.isHidden = true
            // 画像保存用View
            self.saveImageViewVertical.isHidden = false
            // 表示画像の設定
            self.previewImageVertical.image = info.image
            // WSCDの設定
            self.wscdLabelVertical.text! = self.viewModel.getWorkSheetCode()
            // 撮影日時の設定
            self.dateLabelVertical.text! = Date().toJst(format: DRAW_DATE_FORMAT)
            // お客様名の設定
            self.nameLabelVertical.text! = self.viewModel.getClientName()
            // 撮影内容の設定
            self.contentLabelVertical.text! = self.viewModel.getItemName()
            // 縦横フラグ更新(横)
            self.isVertical = false
            
        } else {
            // 画像保存用View
            self.saveImageViewVertical.isHidden = true
            // 表示画像の設定
            self.previewImage.image = info.image
            // WSCDの設定
            self.wscdLabel.text! = self.viewModel.getWorkSheetCode()
            // 撮影日時の設定
            self.dateLabel.text! = Date().toJst(format: DRAW_DATE_FORMAT)
            // お客様名の設定
            self.nameLabel.text! = self.viewModel.getClientName()
            // 撮影内容の設定
            self.contentLabel.text! = self.viewModel.getItemName()
            // 縦横フラグ更新(縦)
            self.isVertical = true
        }
    }
}
