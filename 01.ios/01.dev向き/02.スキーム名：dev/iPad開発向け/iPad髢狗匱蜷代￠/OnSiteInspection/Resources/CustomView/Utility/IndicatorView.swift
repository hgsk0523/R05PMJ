import NVActivityIndicatorView

/// インジケータ
class IndicatorView: UIView {
    
    /// インジケータ
    private var nvActivatorIndicator: NVActivityIndicatorView = NVActivityIndicatorView(frame: CGRect.zero, type: NVActivityIndicatorType.circleStrokeSpin, color: .red, padding: 0)
    
    // インジケータのpadding
    private let indicatorPadding: CGFloat = 50
    
    @IBOutlet weak var background: UIView!
    // MARK: - Lifecycle
    
    // コードから生成された場合
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
        // 非表示にする
        self.background.isHidden = true
        // インジケータ設定
        self.setIndicator()
    }
    
    // ストーリーボードから生成された場合
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        loadNib()
        // 非表示にする
        self.background.isHidden = true
        // インジケータ設定
        self.setIndicator()
    }
    
    private func loadNib() {
        let view = Bundle.main.loadNibNamed("IndicatorView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
    }
    
    // MARK: - Method
    
    /// インジケータのセット
    private func setIndicator() {
        self.nvActivatorIndicator = NVActivityIndicatorView(frame: CGRect.zero, type: NVActivityIndicatorType.lineSpinFadeLoader, color: .white, padding: self.indicatorPadding)
        self.nvActivatorIndicator.center = self.background.center
        self.background.addSubview(nvActivatorIndicator)
    }
    
    // MARK: - Action
    
    /// インジケータの表示
    func showIndicator() {
        self.background.isHidden = false
        nvActivatorIndicator.startAnimating()
    }
    
    /// インジケータの非表示
    func dismissIndicator() {
        DispatchQueue.main.async {
            self.nvActivatorIndicator.stopAnimating()
            self.removeFromSuperview()
        }
    }
}
