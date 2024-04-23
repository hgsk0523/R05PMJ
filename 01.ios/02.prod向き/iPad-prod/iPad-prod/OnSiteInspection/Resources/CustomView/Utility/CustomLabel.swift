import UIKit

class CustomLabel: UILabel {
    
    /// 画像イメージ
    @IBInspectable var labelImage: UIImage?
    
    /// イメージ追加完了フラグ
    private var isAddComplete = false
    
    // ボタン枠のx座標
    private let BUTTON_BORDER_X_COORDINATE: CGFloat = 0
    
    // ボタン枠の高さ
    private let BUTTON_BORDER_HEIGHT: CGFloat = 1.0

    override func layoutSubviews() {
        super.layoutSubviews()
        
        if isAddComplete {
            return
        }
        //下線のCALayerを作成
        let buttomBorder = CALayer()
        buttomBorder.frame = CGRect(x: BUTTON_BORDER_X_COORDINATE, y: self.frame.height, width: self.frame.width, height: BUTTON_BORDER_HEIGHT)
        buttomBorder.backgroundColor = UIColor.lightGray.cgColor
        
        //作成したViewに下線を追加
        self.layer.addSublayer(buttomBorder)
        
        // イメージが選択されていたら左橋に画像を追加
        if let image = labelImage {
            // イメージ追加
            self.insertImage(image: image)
            // イメージ追加完了フラグをON
            isAddComplete = true
        }
    }
    
    /// ラベルの最初にイメージを追加
    /// - Parameter image: 挿入画像イメージ
    private func insertImage(image: UIImage) {
        let attr = attributedText as? NSMutableAttributedString ?? NSMutableAttributedString(string: text ?? "")
        let attachment = NSTextAttachment(image: image, font: font, size: image.size, alignment: .center)
        attr.insert(NSAttributedString(attachment: attachment), at: 0)
        attributedText = attr
    }
}
