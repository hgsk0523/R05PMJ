import Foundation
import UIKit

// MARK: - Property

/// AI判定OK
let AI_OK = "OK"
/// AI判定NG
let AI_NG = "NG"
/// OCR読取失敗
let OCR_FAILURE: String = "ReadError"
/// 解析失敗
let AI_FAILURE: String = "解析失敗"

/// 点検項目ポップアップ画面対応番号
enum INSPECTION_ITEM_POP_UP_NUMBER {
    /// 新規追加
    case ADD_NEW_RECORD
    /// コメント
    case SHOW_COMMENT
    /// 点検結果編集
    case EXIT_INSPECTION_RESULT
    /// NGコメント登録
    case REGIST_NG_COMMENT
    /// WSエビデンス
    case WS_EVIDENCE
    /// 画像拡大
    case ENLARGE_IMAGE
}

/// 点検状態
enum INSPECTION_STATUS: Int {
    /// 検査待ち
    case WAITING = 0
    /// 検査中
    case UNDER_INSPECTION = 1
    /// 再点検
    case RE_INSPECTION = 2
    /// 終了※
    case PARTIALLY_COMPLETED = 3
    /// 終了
    case COMPLETED = 4
}

/// 点検進行状態
enum INSPECTION_PROGRESS: Int {
    /// 撮影待ち
    case WAITING_SHOOTING = 0
    /// ローカルDBに画像保存済み
    case IMAGE_SAVED_LOCAL = 1
    /// サーバに画像保存済み
    case IMAGE_SAVED_REMOTE = 2
    /// 解析依頼中
    case ANALYSIS_REQUEST = 3
    /// 解析中
    case ANALYSIS = 4
    /// 解析完了
    case ANALYSIS_COMPLETED = 5
}

/// 点検項目タイプ
enum INSPECTION_ITEM_TYPE: String {
    case OCR = "ocr"
    case AI = "ai"
    case OTHER = "other"
}

// MARK: - Method

/// サムネイル画像ボタンの制御
/// - Parameter inspectionItemData: 点検項目データ
func setThumbnailImage(inspectionItemData: TBL_T_INSPECTION_ITEM, inspectionData: InspectionViewInfo, thumbnailButton: UIButton) {
    // 進捗に応じてボタンを制御
    switch inspectionItemData.progress {
        // サーバーに画像保存済み、解析完了の場合
    case INSPECTION_PROGRESS.IMAGE_SAVED_REMOTE.rawValue, INSPECTION_PROGRESS.ANALYSIS_COMPLETED.rawValue:
        // 画像解析ボタンの活性化
        thumbnailButton.isEnabled = true
    default:
        // 画像解析ボタンの非活性化
        thumbnailButton.isEnabled = false
    }
}

/// 撮影・再送ボタンの制御
/// - Parameters:
///   - inspectionItemData: 点検項目
///   - inspectionData: 点検データ
///   - isUnsent: 再撮影フラグ
///   - photographButton: 撮影ボタン
func setShootingResendButton(inspectionItemData: TBL_T_INSPECTION_ITEM, inspectionData: InspectionViewInfo, isUnsent: inout Bool, photographButton: CustomButton) {
    // 撮影ボタンの状態変更
    isUnsent = false
    // 進捗に応じてボタンを再送ボタンにする
    switch inspectionItemData.progress {
        // ローカルDBに画像保存済みの場合
    case INSPECTION_PROGRESS.IMAGE_SAVED_LOCAL.rawValue:
        // 1つ目のボタンを再送ボタンに設定
        photographButton.setBackgroundImage(UIImage(named: "bt_photography_resend.dio"), for: .normal)
        // 撮影ボタンのアイコンの設定
        photographButton.setImage(UIImage(systemName: "arrow.up.square"), for: .normal)
        // 撮影ボタンの状態変更
        isUnsent = true
        // 再送ボタンの場合は後続処理を行わない
        return
        // 解析依頼中、解析中の場合
    case INSPECTION_PROGRESS.ANALYSIS_REQUEST.rawValue, INSPECTION_PROGRESS.ANALYSIS.rawValue:
        // 非活性
        photographButton.isEnabled = false
    default:
        break
    }
    // 現在のステータスが検査待ち、検査中、再点検でなければ非活性化
    if inspectionData.status != INSPECTION_STATUS.WAITING.rawValue && inspectionData.status != INSPECTION_STATUS.UNDER_INSPECTION.rawValue && inspectionData.status != INSPECTION_STATUS.RE_INSPECTION.rawValue {
        photographButton.isEnabled = false
    }
}
