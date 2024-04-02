import Foundation
import UIKit
import Network

/// ナビゲーションのコントローラー
final class NavigationBarController: NSObject {
    
    public static let shared = NavigationBarController()
    
    // MARK: - Property
    
    /// ナビゲーションバーのタイトル
    private let NAVIGATION_TITLE: String = "現場点検アプリケーション"
    
    // MARK: - Method
    
    /// ナビゲーションバーの設定
    func setNavigationBar(viewController: UIViewController, isUsedNavigationBar: Bool) {
        // ナビゲーションバーの表示
        viewController.navigationController?.setNavigationBarHidden(false, animated: true)
        // ナビゲーションバーを設定
        let appearance = UINavigationBarAppearance()
        // ナビゲーションの表示/非表示で設定値が変わる
        if isUsedNavigationBar {
            // ナビゲーションバーの背景を設定
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0/255, green: 14/255, blue: 79/255, alpha: 1)
            // ナビゲーションバーのタイトルテキストの色を指定
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        } else {
            // ナビゲーションバーの背景を設定
            appearance.configureWithTransparentBackground()
            // ナビゲーションバーのタイトルテキストの色を指定
            appearance.titleTextAttributes = [.foregroundColor: UIColor.clear]
        }
        
        // タイトルを設定
        viewController.title = NAVIGATION_TITLE
        
        // ユーザーアカウントボタンを設置
        // 撮影画面の時は表示させない
        if  !(viewController is CameraViewController) && !(viewController is StandbyViewController) {
            let userAccountButton = NavigationBarButtonView()
            // ログアウトボタンのテキスト変更
            userAccountButton.repCd.text = CustomURLSchemeDatasource.shared.getCustomURLSchemeParameters().STANTOUCD
            // ナビゲーションエリアの右側にボタン配置
            let userAccount = UIBarButtonItem(customView: userAccountButton)
            viewController.navigationItem.rightBarButtonItem = userAccount
        }
        
        // 戻るボタンを設置
        // 点検画面、待機画面の時は表示させない
        if !(viewController is InspectionViewController) && !(viewController is StandbyViewController) {
            let button = BackView()
            // ナビゲーションエリアの左側にボタン配置
            let backButton = UIBarButtonItem(customView: button)
            viewController.navigationItem.leftBarButtonItem = backButton
        } else {
            // デフォルトのボタンが入っても非表示にする
            viewController.navigationItem.hidesBackButton = true
        }
        
        // 指定のViewにナビゲーションバーの設定を反映
        viewController.navigationItem.standardAppearance = appearance
        viewController.navigationItem.scrollEdgeAppearance = appearance
        viewController.navigationItem.compactAppearance = appearance
    }
    
    /// ログアウト用処理
    func logout() {
        let topViewController = UIApplication.topViewController()
        // 待機画面に遷移
        // ナビゲーションバーの設定
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("unexpected error occured. UIAplication delegate is not AppDelegate.")
        }
        // ルートを待機画面に変更
        appDelegate.window?.rootViewController = R.storyboard.standbyViewController.instantiateInitialViewController()
        // 待機画面に遷移
        if let vc = R.storyboard.standbyViewController.instantiateInitialViewController() {
            topViewController?.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    /// ナビゲーションバーを非表示にする
    func setNavigationBarHidden(viewController: UIViewController) {
        viewController.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    /// ナビゲーションバーのバックボタンを押した時の処理
    func backProcess() {
        let topViewController = UIApplication.topViewController()
        // １つ前の画面に戻る
        topViewController?.navigationController?.popViewController(animated: true)
    }
}
