import Foundation

// MARK: - Property
/// 保存用画像クオリティ設定値
let SAVE_IMAGE_QUALITY: Double = 0.5
/// 画像保存フォルダ名
let FOLDER_NAME: String = "写真"
/// 撮影例保存フォルダ名
let FOLDER_NAME_EXSAMPLE_IMAGE: String = "撮影例画像/"
/// 解像度
let RESOLUTION_1280: Double = 1280
let RESOLUTION_720: Double = 720

// MARK: - Method

/// ローカルに保存している該当のオブジェクトの削除
func deleteLocalImage(hierarchy: String) {
    // 指定フォルダの削除
    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask ).first {
        let folderName = dir.appendingPathComponent( hierarchy , isDirectory: true)
        try? FileManager.default.removeItem(atPath: folderName.path)
    }
}
