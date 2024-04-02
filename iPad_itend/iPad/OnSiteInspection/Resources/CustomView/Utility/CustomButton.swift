import UIKit

class CustomButton: UIButton {
    
    @IBInspectable var leftFixedFlag: Bool = true
    @IBInspectable var magnification: Double = 1.0
    
    private var imageSize: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    
    // 左寄せの場合のイメージViewのX座標
    private let IMAGE_X_COORDINATE: CGFloat = 15
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let imageView = self.imageView {
            // imageが指定されていない場合は処理をしない
            if let _ = imageView.image {} else { return }
            // 画像がすでに縮小されているかを確認
            if imageSize == imageView.frame { return }
            // 指定の倍率で画像を縮小
            let image = imageView.image!.resize(width: (imageView.frame.width * magnification), height: (imageView.frame.height * magnification))
            let iconWidth = image.size.width
            let iconHeight = image.size.height
            // 設定されているフラグごとにボタンのImageを配置
            if !leftFixedFlag {
                imageView.frame = CGRect(x: (self.frame.width - iconWidth) / 2, y: (self.frame.height - iconHeight) / 2, width: iconWidth, height: iconHeight)
            } else {
                // 左よせの場合
                imageView.frame = CGRect(x: IMAGE_X_COORDINATE, y: (self.frame.height - iconHeight) / 2, width: iconWidth, height: iconHeight)
            }
            // サイズを更新
            imageSize = imageView.frame
            imageView.autoresizingMask = [.flexibleRightMargin]
        }
    }
}
