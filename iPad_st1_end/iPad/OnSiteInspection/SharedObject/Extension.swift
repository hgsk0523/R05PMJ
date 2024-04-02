import Foundation
import UIKit

extension Date {
    
    func toJst(format: String) -> String {
        
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "JST")
        formatter.locale = Locale.init(identifier: "ja_JP")
        formatter.dateFormat = format
        
        return formatter.string(from: self)
    }
    
    /// UTC時間でミリ秒までISO 8601フォーマットで取得
    func nowISO8601() -> String {
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        
        return formatter.string(from: Date.now)
    }
}

extension URL {
    /// 指定したURLクエリパラメーターの値を取得する
    ///
    /// - Parameter key: URLクエリパラメーターのキー
    /// - Returns: 指定したURLクエリパラメーターの値（存在しない場合はnil）
    func queryValue(for key: String) -> String? {
        let queryItems = URLComponents(string: absoluteString)?.queryItems
        return queryItems?.filter { $0.name == key }.compactMap { $0.value }.first
    }
}

extension UIView {
    
    /// 枠線の色
      @IBInspectable var borderColor: UIColor? {
        get {
          layer.borderColor.map { UIColor(cgColor: $0) }
        }
        set {
          layer.borderColor = newValue?.cgColor
        }
      }

      /// 枠線のWidth
      @IBInspectable var borderWidth: CGFloat {
        get {
          layer.borderWidth
        }
        set {
          layer.borderWidth = newValue
        }
      }

      /// 角丸の大きさ
      @IBInspectable var cornerRound: CGFloat {
        get {
          layer.cornerRadius
        }
        set {
          layer.cornerRadius = newValue
          layer.masksToBounds = newValue > 0
        }
      }
    
    func getImage() -> UIImage {
        
        // キャプチャする範囲を取得
        let rect = self.bounds
        
        // ビットマップ画像のcontextを作成
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        
        // 対象のview内の描画をcontextに複写する
        self.layer.render(in: context)
        
        // 現在のcontextのビットマップをUIImageとして取得
        let capturedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        // contextを閉じる
        UIGraphicsEndImageContext()
        
        return capturedImage
    }
    
    /// UIviewが親ビューをとってこれるように拡張
    /// - Returns: UIviewController
    func parentViewController() -> UIViewController? {
        var parentResponder: UIResponder? = self
        while true {
            guard let nextResponder = parentResponder?.next else { return nil }
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            parentResponder = nextResponder
        }
    }
    
    func parentView<T: UIView>(type: T.Type) -> T? {
        var parentResponder: UIResponder? = self
        while true {
            guard let nextResponder = parentResponder?.next else { return nil }
            if let view = nextResponder as? T {
                return view
            }
            parentResponder = nextResponder
        }
    }
}

extension UIImage {
    func resize(width: Double , height: Double) -> UIImage {

        // 画像をリサイズ
        let resizedSize = CGSize(width: width, height: height)
        
        // リサイズ後のUIImageを生成して返却
        UIGraphicsBeginImageContext(resizedSize)
        self.draw(in: CGRect(x: 0, y: 0, width: resizedSize.width, height: resizedSize.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage!
    }
}

// 現在表示されているViewControllerを取得するために拡張
extension UIApplication {
    class func topViewController(controller: UIViewController? = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first { $0.isKeyWindow }?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}

extension NSTextAttachment {
    convenience init(image: UIImage, font: UIFont, size: CGSize, alignment: VerticalAlignment) {
        self.init()
        self.image = image
        let y: CGFloat
        switch alignment {
        case .top:
            y = font.capHeight - size.height
        case .bottom:
            y = font.descender
        case .center:
            y = (font.capHeight - size.height).rounded() / 2
        case .baseline:
            y = 0
        }
        bounds.origin = CGPoint(x: 0, y: y)
        bounds.size = size
    }

    enum VerticalAlignment {
        case bottom, baseline, center, top
    }
}

extension UIViewController {
    /// インジケータを表示する
    func showIndicator() {
        // インジケータ生成
        let indicator = IndicatorView()
        // インジケータのレイヤーの設定
        indicator.frame = self.view.bounds
        self.view.addSubview(indicator)
        indicator.showIndicator()
    }
    
    /// インジケータを削除する
    func dismissIndicator() {
        // subviewの中でインジケータのものを探索し削除する
        (self.view.subviews.first(where: { $0 is IndicatorView}) as? IndicatorView)?.dismissIndicator()
    }
    
    /// Lock your orientation
    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
        self.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
    
    /// OPTIONAL Added method to adjust lock and rotate to the desired orientation
    func lockOrientation(_ allowOrientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation: UIInterfaceOrientationMask) {
        
        self.lockOrientation(allowOrientation)
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: rotateOrientation))
        
        self.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}
