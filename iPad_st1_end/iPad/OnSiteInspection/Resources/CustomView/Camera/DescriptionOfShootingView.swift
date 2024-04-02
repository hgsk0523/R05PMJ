import UIKit

class DescriptionOfShootingView: UIView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var descriptionImageView: UIImageView!
    
    /// 画面名
    private let SCREEN_NAME: String = "撮影例表示画面"
    
    // コードから生成された場合
    override init(frame: CGRect) {
            super.init(frame: frame)
            loadNib()
        }

    // ストーリーボードから生成された場合
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        loadNib()
    }

    func loadNib() {
        let view = Bundle.main.loadNibNamed("DescriptionOfShootingView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
    }
    
    // MARK: - Method
    
    /// タイトルをセット
    func setTitle(text: String) {
        titleLabel.text = text
    }
    
    /// 説明をセット
    func setDescriptionText(text: String) {
        descriptionTextView.text = text
    }
    
    /// イメージ画像をセット
    func setDescriptionImage(image: UIImage) {
        descriptionImageView.image = image
    }
    
    /// TextViewの高さを調整
    func setTextViewHeight() {
        let height = descriptionTextView.sizeThatFits(CGSize(width: descriptionTextView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
        descriptionTextView.heightAnchor.constraint(equalToConstant: height).isActive = true
    }
    
    /// クローズボタン押下
    @IBAction func onTapCloseButton(_ sender: Any) {
        infoLog(screen: SCREEN_NAME, logMessage: "閉じるボタン押下")
        //　画面の向き固定解除
        if let parentVC = self.parentViewController() as? CameraViewController {
            parentVC.lockOrientation(UIInterfaceOrientationMask.all)
        }
        self.removeFromSuperview()
    }
    
    /// 右ボタン押下
    @IBAction func onTapRightButtonTap(_ sender: Any) {
        infoLog(screen: SCREEN_NAME, logMessage: "ページングボタン押下")
        DescriptionOfShootingService.shared.advanceDescriptionOfShootingView()
    }
    
    /// 左ボタン押下
    @IBAction func onTapLeftButtonTap(_ sender: Any) {
        infoLog(screen: SCREEN_NAME, logMessage: "ページングボタン押下")
        DescriptionOfShootingService.shared.decreaseDescriptionOfShootingView()
    }
}
