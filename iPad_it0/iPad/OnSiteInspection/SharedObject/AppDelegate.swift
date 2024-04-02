import UIKit
import RealmSwift
import Swinject
import SwinjectStoryboard

@main
class AppDelegate: UIResponder {
    
    // MARK: - Property
    
    private let assember = Assembler([ViewAssembly(), ViewModelAssembly(), ModelDataAssembly()],
                                     container: SwinjectStoryboard.defaultContainer)
    
    var window: UIWindow?

    /// 画面向き
    var orientationLock = UIInterfaceOrientationMask.portrait
    
    /// ログの保存先
    let documentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.endIndex - 1]
    }()
    
    // 階層
    private let hierarchy = "設定値ファイル/"
    // 設定ファイル名
    private let settingFileName = "SettingFile.json"
    // S3設定ファイル名
    private let s3settingFileName = "setting/SettingFile.json"
    
    // MARK: - Method
    
    /// ナビゲーションバーの設定
    /// 本メソッドで設定した画面がRootViewControllerになる
    func setNavigationController(_ rootViewController: UIViewController) {
        // ナビゲーションバーの設定
        let navigationController = UINavigationController(rootViewController: rootViewController)
        self.window?.rootViewController = navigationController
    }
}

// MARK: - UIApplicationDelegate

extension AppDelegate: UIApplicationDelegate {
    
    func application(_ application : UIApplication, open url: URL, options : [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        do {
            // 保存先にフォルダがなければ作成
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask ).first {
                let folderName = dir.appendingPathComponent( self.hierarchy , isDirectory: true)
                do {
                    try FileManager.default.createDirectory( at: folderName, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    throw error
                }
            }
            // デフォルトの解析ログ機能がSwinjectStoryboardと競合するらしく、エラーログが出るのを防ぐ
            Container.loggingFunction = nil
            // ローカルのJsonファイルのファイル名
            let localJsonFileName = "\(self.hierarchy)\(self.settingFileName)"
            // ローカルのJsonパス名
            let localJsonPath = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(localJsonFileName)
            // カスタムnilチェック
            guard let urlString = URL(string: url.absoluteString), let katasiki = urlString.queryValue(for: "KATASIKI") else {
                throw ErrorID.ID0011
            }
            do {
                // 品番S3ガイドラインチェック
                try validationS3Guidelines(text: katasiki)
            } catch {
                // 品番S3ガイドラインチェックに引っかかったのでエラーフラグを立てる
                CustomURLSchemeDatasource.shared.setModelCheckFlag(flag: true)
                throw error
            }
            // パラメータをセットする
            try CustomURLSchemeDatasource.shared.setCustomURLSchemeParameters(url: url)
            // サーバーから設定JSONファイルを取得
            ApiService.shared.getS3JsonFileData(s3Path: s3settingFileName) { response in
                DispatchQueue.main.sync {
                    do {                        
                        // 現在端末に持っている設定JSONファイルを取得
                        let currentSettingJson = SettingService.shared.getSettingInfoFromDevice(localPath: localJsonFileName)
                        // 設定ファイルの設定
                        try SettingService.shared.setSettingFile(localJsonPath: localJsonPath, currentSettingJson: currentSettingJson, newSettingJson: response)
                        // データ保持期間が過ぎている写真を削除する
                        // エラーは無視
                        try? ImageService.shared.deleteOldImageData()
                        // パラメータ取得
                        let parameterInfo = CustomURLSchemeDatasource.shared.getCustomURLSchemeParameters()
                        // パラメータチェック
                        try CustomURLSchemeService.shared.checkLoginParameters(companyCD: parameterInfo.KAISHACD, baseCD: parameterInfo.KYOTENCD, repCD: parameterInfo.STANTOUCD)
                        // インジケータ表示
                        UIApplication.topViewController()?.showIndicator()
                        // 点検情報作成時間更新
                        InspectionViewDataSource.shared.setCreateDate(date: Date())
                        // 点検項目情報取得
                        SettingService.shared.saveInspectionInfo(parametersInfo: parameterInfo) { response in
                            // インジケータの非表示
                            UIApplication.topViewController()?.dismissIndicator()
                            // 点検画面に遷移
                            self.window?.rootViewController = R.storyboard.inspectionViewController.instantiateInitialViewController()
                        } failureHandler: { error in
                            // インジケータの非表示
                            UIApplication.topViewController()?.dismissIndicator()
                            // 待機画面に遷移
                            self.window?.rootViewController = R.storyboard.standbyViewController.instantiateInitialViewController()
                            // エラーを返す
                            errorDialog(error: error == ErrorCause.ConnectionError ? ErrorID.ID0004 :  ErrorID.ID0005, vc: UIApplication.topViewController()!, handler: nil)
                        }
                    } catch {  
                        // インジケータの非表示
                        UIApplication.topViewController()?.dismissIndicator()
                        // 待機画面に遷移
                        self.window?.rootViewController = R.storyboard.standbyViewController.instantiateInitialViewController()
                        // エラーを返す
                        errorDialog(error: error == ErrorID.ID0003 ? ErrorID.ID0003 :  ErrorID.ID0002, vc: UIApplication.topViewController()!, handler: nil)
                    }
                } 
            } failureHandler: { error in
                DispatchQueue.main.sync {
                    // インジケータの非表示
                    UIApplication.topViewController()?.dismissIndicator()
                    // 待機画面に遷移
                    self.window?.rootViewController = R.storyboard.standbyViewController.instantiateInitialViewController()
                    // エラーを返す
                    errorDialog(error: error == ErrorCause.ConnectionError ? ErrorID.ID0001 :  ErrorID.ID0002, vc: UIApplication.topViewController()!, handler: nil)
                }
            }
            return true
        } catch {
            // 待機画面に遷移
            self.window?.rootViewController = R.storyboard.standbyViewController.instantiateInitialViewController()
            // エラー表示
            errorDialog(error: error, vc: UIApplication.topViewController()!, handler: nil)
            return true
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 解析ログ機能を無効化する
        Container.loggingFunction = nil
        // 待機画面に遷移
        self.window?.rootViewController = R.storyboard.standbyViewController.instantiateInitialViewController()
        // UIButtonの同時押し制御
        UIButton.appearance().isExclusiveTouch = true
        
        return true
    }
    
    func application(_ application: UIApplication,supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // バックグラウンド移行
        log.info("バックグラウンドに移行")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // ログの初期化
        log = initLog()
        // フォアグラウンド移行
        log.info("フォアグラウンドに移行")
    }
}

