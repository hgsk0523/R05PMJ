import UIKit

/// 画像拡大View
class EnlargeImageView: UIView {
    
    // MARK: - Property
    
    /// 基準となる比率
    private static let BASE_RATE: CGFloat = 1
    
    /// イメージのレイアウト
    @IBOutlet weak var imageView: UIImageView!
    
    /// 拡大・縮小率を保存する変数
    private var imageMagnification: CGFloat = 1
    
    /// 画面名
    private let SCREEN_NAME: String = "画像拡大画面"
    
    // MARK: - Lifecycle
    
    /// コードから生成された場合
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNib()
        // 初期設定
        self.initSetting()
    }
    
    /// ストーリーボードから生成された場合
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.loadNib()
        // 初期設定
        self.initSetting()
    }
    
    private func loadNib() {
        let view = Bundle.main.loadNibNamed("EnlargeImageView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
    }
    
    // MARK: - Method
    
    /// 初期設定
    private func initSetting() {
        // ピンチイン、ピンチアウトのジェスチャーを登録
        let pinchGesture = UIPinchGestureRecognizer()
        pinchGesture.addTarget(self, action: #selector(pinchAction(_:)))
        self.imageView.isUserInteractionEnabled = true
        self.imageView.addGestureRecognizer(pinchGesture)
    }
    
    /// 画像を設定
    /// - Parameter image: 画像
    func setImage(image: UIImage) {
        self.imageView.image = image.resize(width: image.size.width * 0.5, height: image.size.height * 0.5)
    }
    
    // MARK: - Action
    
    /// バックグラウンドが押された時
    /// - Parameter sender: バックグラウンド
    @IBAction func onTapBackground(_ sender: Any) {
        infoLog(screen: SCREEN_NAME, logMessage: "画像外押下")
        self.removeFromSuperview()
    }
    
    /// 画像がピンチイン、ピンアウトされた時
    @objc func pinchAction(_ gesture: UIPinchGestureRecognizer ) {
        // 前回の拡大縮小も含めて初期値からの拡大縮小比率を計算
        // gesture.scaleはピンチイン、ピンアウト開始時の画像を基準として何倍されているかの比率
        var rate = gesture.scale * self.imageMagnification
        if rate > EnlargeImageView.BASE_RATE {
            // 拡大縮小の反映
            self.imageView.transform = CGAffineTransform(scaleX: rate , y: rate )
        } else {
            rate = EnlargeImageView.BASE_RATE
        }
        // ピンチイン、ピンアウト終了時
        if(gesture.state == .ended) {
            //終了時に拡大・縮小率を保存しておいて次回に使いまわす
            self.imageMagnification = rate
        }
    }
}
