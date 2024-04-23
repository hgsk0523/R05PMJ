import Foundation

struct SettingValues: Codable {
    var version: Int
    var bucketName: String
    var pollingPeriod: Int
    var dataRetentionPeriod: Int
    var settings: [Settings]
    
    /// 設定値の設定
    mutating func setSetingValues(version: Int, bucketName: String, pollingPeriod: Int, dataRetentionPeriod: Int, settings: [Settings]) {
        self.version = version
        self.bucketName = bucketName
        self.pollingPeriod = pollingPeriod
        self.dataRetentionPeriod = dataRetentionPeriod
        self.settings = settings
    }
}
 
struct Settings: Codable {
    var inspectionNameId: Int
    var guideFrame: [GuideFrame]
    var trimingPosition: [TrimingPosition]
    var worksheetEvidenceItem: [WorksheetEvidenceItem]
    var inspectionItem: [InspectionItem]
    var photoSample: [PhotoSample]
    var comment: String
}
 
struct GuideFrame: Codable {
    var inspectionItemNameId: Int
    var coordinate: [Coordinate]?
}
 
struct TrimingPosition: Codable {
    var inspectionItemNameId: Int
    var coordinate: [Coordinate]?
}

struct Coordinate: Codable {
    var isVertical: Bool
    var x: Int
    var y: Int
    var width: Int
    var height: Int
}
 
struct WorksheetEvidenceItem: Codable {
    var evidenceId: Int
    var evidenceName: String
    var isEditable: Bool
}
 
struct InspectionItem: Codable {
    var inspectionItemNameId: Int
    var inspectionItemName: String
    var type: String
}
 
struct PhotoSample: Codable {
    var inspectionItemNameId: Int
    var photoInfo: [PhotoInfo]?
}
 
struct PhotoInfo: Codable {
    var fileName: String
    var explanation: String
    var s3Path: String
}
