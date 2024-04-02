import Foundation

/// 設定データソース
class SettingDatasource: NSObject {
    
    // MARK: - Property
    /// シングルトン
    private override init() {}
    public static let shared = SettingDatasource()
    
    /// 設定情報
    var settingValuesInfo: SettingValues!
        
    // MARK: - Method
 
    /// パラメータをセット
    func setSettingValuesInfo(version: Int, bucketName: String,  pollingPeriod: Int, dataRetentionPeriod: Int, settings: [Settings]) {
        // 設定情報を保存
        self.settingValuesInfo = SettingValues(version: version, bucketName: bucketName, pollingPeriod: pollingPeriod, dataRetentionPeriod: dataRetentionPeriod, settings: settings)
    }
    
    /// パラメータ情報を返す
    /// - Returns: パラメータ情報
    func getSettingValuesInfo() -> SettingValues {
        return self.settingValuesInfo
    }
    
    /// ローカルの設定ファイルをinfoに保存する
    func saveSettingInfo(settingInfo: SettingValues) {
        // 読み込んだ設定ファイルの情報をinfoに保存
        SettingDatasource.shared.setSettingValuesInfo(version: settingInfo.version, bucketName: settingInfo.bucketName, pollingPeriod: settingInfo.pollingPeriod, dataRetentionPeriod: settingInfo.dataRetentionPeriod, settings: settingInfo.settings)
    }
    
    /// 該当する設定情報を取得する
    /// - Parameter inspectionNameId: 点検名ID
    func getSettings(inspectionNameId: Int) throws -> Settings {
        do {
            // 設定ファイルのnilチェック
            guard let settingValuesInfo = self.settingValuesInfo else {
                throw ErrorID.ID9999
            }
            // 該当する点検の設定ファイルを保存する変数
            var setting: Settings?
            // 該当する点検の設定データをとり出す
            for data in settingValuesInfo.settings {
                // 点検名IDが一致する設定を取り出す
                if data.inspectionNameId == inspectionNameId {
                    setting = data
                    break
                }
            }
            // 設定のnilチェック
            guard let setting = setting else {
                throw ErrorID.ID9999
            }
            return setting
        } catch {
            throw error
        }
    }
    
    /// エビデンス項目情報を取り出す
    /// - Parameter inspectionNameId: 点検名ID
    func getWSEvidenceInfo(inspectionNameId: Int) throws -> [WorksheetEvidenceItem] {
        do {
            // 設定ファイルのnilチェック
            guard let settingValuesInfo = self.settingValuesInfo else {
                throw ErrorID.ID9999
            }
            // 該当する点検の設定ファイルを保存する変数
            var setting: Settings?
            // 該当する点検の設定データをとり出す
            for data in settingValuesInfo.settings {
                // 点検名IDが一致する設定を取り出す
                if data.inspectionNameId == inspectionNameId {
                    setting = data
                    break
                }
            }
            // 設定のnilチェック
            guard let setting = setting else {
                throw ErrorID.ID9999
            }
            
            return setting.worksheetEvidenceItem
        } catch {
            throw error
        }
    }
    
    /// ガイド枠情報を取り出す
    /// - Parameter inspectionNameId: 点検名ID
    /// - Parameter inspectionItemNameId: 点検項目名ID
    /// - Returns: ガイド枠設定
    func getGuideFrameCoodinateInfo(inspectionNameId: Int, inspectionItemNameId: Int?, isVertical: Bool) -> Coordinate? {
            // 設定ファイルのnilチェック
            guard let settingValuesInfo = self.settingValuesInfo else {
                // 入らない想定
                return nil
            }
            // 該当する点検の設定ファイルを保存する変数
            var setting: Settings!
            // 該当する点検の設定データをとり出す
            for data in settingValuesInfo.settings {
                // 点検名IDが一致する設定を取り出す
                if data.inspectionNameId == inspectionNameId {
                    setting = data
                    break
                }
            }
            // 該当するガイド枠情報を保存する変数
            var guideFrame: GuideFrame?
            // 該当するガイド枠を取り出す
            for guideData in setting.guideFrame {
                // 点検項目名IDが一致する設定を取り出す
                if guideData.inspectionItemNameId == inspectionItemNameId {
                    guideFrame = guideData
                }
            }

            // nilチェック
        guard let coordinateDataList = guideFrame?.coordinate else {
                // 入らない想定
                return nil
            }
            
            for coordinateData in coordinateDataList {
                // 縦横フラグで返すものを判断
                if isVertical == coordinateData.isVertical {
                    // 画面縦の時
                    return coordinateData
                }
            }
            // 入らない想定
            return nil
    }
    
    /// トリミング座標情報を取り出す
    /// - Parameter inspectionNameId: 点検名ID
    /// - Parameter inspectionItemNameId: 点検項目名ID
    /// - Returns: トリミング座標情報
    func getTrimmingPositionCoodinateInfo(inspectionNameId: Int, inspectionItemNameId: Int?, isVertical: Bool) -> Coordinate? {
            // 設定ファイルのnilチェック
            guard let settingValuesInfo = self.settingValuesInfo else {
                // 入らない想定
                return nil
            }
            // 該当する点検の設定ファイルを保存する変数
            var setting: Settings!
            // 該当する点検の設定データをとり出す
            for data in settingValuesInfo.settings {
                // 点検名IDが一致する設定を取り出す
                if data.inspectionNameId == inspectionNameId {
                    setting = data
                    break
                }
            }
            // 該当するトリミング情報を保存する変数
            var trimingPosition: TrimingPosition?
            // 該当するトリミンング座標を取り出す
            for trimingData in setting.trimingPosition {
                // 点検項目名IDが一致する設定を取り出す
                if trimingData.inspectionItemNameId == inspectionItemNameId {
                    trimingPosition = trimingData
                }
            }

            // nilチェック
        guard let coordinateDataList = trimingPosition?.coordinate else {
                // 入らない想定
                return nil
            }
            
            for coordinateData in coordinateDataList {
                // 縦横フラグで返すものを判断
                if isVertical == coordinateData.isVertical {
                    // 画面縦の時
                    return coordinateData
                }
            }
            // 入らない想定
            return nil
    }
    
    /// 設定ファイルから点検項目がどのタイプかを返す
    func getInspectionItemType(inspectionNameId: Int, inspectionItemNameID: Int?) throws -> String? {
        do {
            // 設定ファイルのnilチェック
            guard let settingValuesInfo = self.settingValuesInfo else {
                throw ErrorID.ID9999
            }
            // 該当する点検の設定ファイルを保存する変数
            var setting: Settings?
            // 該当する点検の設定データをとり出す
            for data in settingValuesInfo.settings {
                // 点検名IDが一致する設定を取り出す
                if data.inspectionNameId == inspectionNameId {
                    setting = data
                    break
                }
            }
            // 設定のnilチェック
            guard let setting = setting else {
                throw ErrorID.ID9999
            }
            // 各点検項目のタイプを決定し、リストに追加する
            // 設定ファイルの点検項目IDと一致するデータを検索し、タイプを決める
            for inspectionItemSetting in setting.inspectionItem {
                // 点検項目IDが一致した時、リストにその点検項目データとタイプを保存
                if inspectionItemSetting.inspectionItemNameId == inspectionItemNameID {
                    return inspectionItemSetting.type
                }
            }
            return nil
        } catch {
            throw error
        }
    }
    
    /// 全ての設定ファイルを返す
    /// - Parameter inspectionName: 点検名
    /// - Returns: 撮影例情報
    func getAllSettings() throws -> [Settings] {
        do {
            // 設定ファイルのnilチェック
            guard let settingValuesInfo = self.settingValuesInfo else {
                throw ErrorID.ID9999
            }
            
            return settingValuesInfo.settings
        } catch {
            throw error
        }
    }
}
