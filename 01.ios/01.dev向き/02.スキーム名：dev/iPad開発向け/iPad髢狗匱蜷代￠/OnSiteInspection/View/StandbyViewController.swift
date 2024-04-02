import UIKit

/// 待機画面ViewController
final class StandbyViewController: UIViewController {
    
    /// 画面名
    private let SCREEN_NAME: String = "待機画面"
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        infoLog(screen: SCREEN_NAME, logMessage: "画面表示")
        // ナビゲーションバーの設定
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("unexpected error occured. UIAplication delegate is not AppDelegate.")
        }
        appDelegate.setNavigationController(self)
        // ナビゲーションバーを設定
        NavigationBarController.shared.setNavigationBar(viewController: self, isUsedNavigationBar: true)
        // 品番S3ガイドラインチェックフラグが立っていればエラー時のViewを表示する
        if CustomURLSchemeDatasource.shared.getModelCheckFlag() {
            // エラー画面表示
            self.setActivationFrameErr()
            // フラグをもとに戻す
            CustomURLSchemeDatasource.shared.setModelCheckFlag(flag: false)
        }
    }
    
    // MARK: - Property
    
    /// エラーの時のViewのアウトレット
    @IBOutlet weak var frameErrView: UIImageView!
    
    // MARK: - Method
    
    /// エラー画面の時の処理
    func setActivationFrameErr() {
        // エラー画面を表示する
        frameErrView.isHidden = false
    }
}
