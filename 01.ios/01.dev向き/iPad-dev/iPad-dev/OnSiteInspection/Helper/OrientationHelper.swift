import Foundation
import UIKit

// MARK: - Property

/// 画面の向き
enum ORIENTATION: Int {
    /// ホームボタンが右側
    case RIGHT = -1
    /// ホームボタンが下側
    case DOWN = 0
    /// ホームボタンが左側
    case LEFT = 1
    /// ホームボタンが上側
    case UP = 2
}

// MARK: - Method

/// 画面の向きからオリエンテーションを取得する
func getDeviceOrientation() -> ORIENTATION {
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene
    let window = windowScene?.windows.first
    
    guard let interfaceOrientation = window?.windowScene?.interfaceOrientation else {
        return .RIGHT
    }
    
    switch interfaceOrientation {
    case .landscapeLeft:
        return .LEFT
    case .landscapeRight:
        return .RIGHT
    case .portrait:
        return .DOWN
    case .portraitUpsideDown:
        return .UP
        
    default:
        return .RIGHT
    }
}
