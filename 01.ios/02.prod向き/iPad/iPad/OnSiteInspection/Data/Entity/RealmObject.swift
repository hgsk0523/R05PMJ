import Foundation
import RealmSwift

/// ローカルDB設定

/// 点検テーブル
final class TBL_T_INSPECTION: Object {
    /// 点検ID
    @Persisted(primaryKey: true) var inspection_id: Int
    /// 点検名ID
    @Persisted var inspection_name_id: Int
    /// WSCD
    @Persisted var worksheet_code: String
    /// 受注確定日
    @Persisted var receipt_confirmation_date: String
    /// 点検日
    @Persisted var inspection_date: String
    /// 品番
    @Persisted var model: String
    /// お客様名称
    @Persisted var client_name: String
    /// 状態
    @Persisted var status: Int
    /// 会社CD
    @Persisted var company_code: String
    /// 担当拠点CD
    @Persisted var base_code: String
    /// 担当者CD
    @Persisted var worker_code: String
    /// 作成日時
    @Persisted var mak_dt: Date
    /// 更新日時
    @Persisted var ren_dt: Date
}

/// 点検項目テーブル
final class TBL_T_INSPECTION_ITEM: Object {
    /// 点検項目ID
    @Persisted(primaryKey: true) var inspection_item_uuid: UUID = UUID()
    /// 点検項目ID
    @Persisted var inspection_item_id: Int?
    /// 点検ID
    @Persisted var inspection_id: Int
    /// 項目名ID
    @Persisted var item_name_id: Int?
    /// 項目名
    @Persisted var item_name: String?
    /// 撮影日時
    @Persisted var taken_dt: Date?
    /// ローカル画像パス(オリジナル)
    @Persisted var local_original_image_path: String?
    /// ローカル画像パス(トリミング)
    @Persisted var local_triming_image_path: String?
    /// S3画像パス(オリジナル)
    @Persisted var s3_original_image_path: String?
    /// S3画像パス(トリミング)
    @Persisted var s3_triming_image_path: String?
    /// AI判定結果
    @Persisted var ai_result: String?
    /// 品番
    @Persisted var model: String?
    /// 製造番号
    @Persisted var serial_number: String?
    /// 編集済品番
    @Persisted var edited_model: String?
    /// 編集済製造番号
    @Persisted var edited_serial_number: String?
    /// 進捗状況
    @Persisted var progress: Int
    /// NGコメント
    @Persisted var ng_comment: String?
    /// 削除フラグ
    @Persisted var delete_flg: Int?
    /// 解析種別
    @Persisted var analysis_type: String?
    /// 作成日時
    @Persisted var mak_dt: Date
    /// 更新日時
    @Persisted var ren_dt: Date
    /// バージョン番号
    @Persisted var version: Int
}

/// サンプル写真テーブル
final class TBL_M_SAMPLE_PHOTO: Object {
    /// 撮影例ID
    @Persisted(primaryKey: true) var sample_id: UUID = UUID()
    /// 点検名ID
    @Persisted var inspection_name_id: Int
    /// 項目名ID
    @Persisted var item_name_id: Int?
    /// ファイル名
    @Persisted var filename_name: String
    /// 説明文
    @Persisted var explanation: String
    /// ローカルパス
    @Persisted var local_image_path: String
    /// S3画像パス
    @Persisted var s3_image_path: String
    /// 作成日時
    @Persisted var mak_dt: Date
    /// 更新日時
    @Persisted var ren_dt: Date
}
