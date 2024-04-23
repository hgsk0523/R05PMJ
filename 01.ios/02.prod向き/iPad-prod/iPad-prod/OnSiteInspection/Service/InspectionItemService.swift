import UIKit

/// 点検項目サービスクラス
class InspectionItemService: NSObject {
    
    // MARK: - Property
    
    /// シングルトン
    private override init() {}
    public static let shared = InspectionItemService()
    
    /// 点検画面Info
    private var inspectionViewInfo = InspectionViewInfo()
    
    // MARK: - Method
    
    /// 点検項目追加ポップアップの画面の作成
    func createAddInspectionItemView() -> UIView {
        return AddInspectionItemView()
    }
    
    /// 点検結果編集ポップアップの画面の作成
    func createExitInspectionResultView(inspectionItemData: TBL_T_INSPECTION_ITEM) -> UIView {
        let exitInspectionResultView = ExitInspectionResultView()
        exitInspectionResultView.setInspectionItemData(inspectionItemData: inspectionItemData)
        return exitInspectionResultView
    }
    
    /// エビデンス登録ポップアップの画面の作成
    func createDisplayCommentView() -> UIView {
        return DisplayCommentView()
    }
    
    /// 写真エビデンス登録ポップアップの画面の作成
    func createRegisterNGCommentView(inspectionItemData: TBL_T_INSPECTION_ITEM) -> UIView {
        let registerNGCommentView = RegisterNGCommentView()
        registerNGCommentView.setInspectionItemData(inspectionItemData: inspectionItemData)
        return registerNGCommentView
    }
    
    /// WSエビデンスポップアップの画面の作成
    func createWSEvidenceView(worksheetEvidenceItem: [WorksheetEvidenceItem]) -> UIView {
        let wsEvidenceView = RegisterEvidenceView()
        wsEvidenceView.setWorksheetEvidenceItem(worksheetEvidenceItem: worksheetEvidenceItem)
        return wsEvidenceView
    }
    
    /// 画像拡大画面の作成
    func createEnlargeImageView(image: UIImage) -> UIView {
        let enlargeImageView = EnlargeImageView()
        enlargeImageView.setImage(image: image)
        return enlargeImageView
    }
}
