import UIKit
import RealmSwift

/// 点検画面のView
final class InspectionViewController: UIViewController {
    
    // MARK: - Injection
    var viewModel: InspectionViewModelProtocol!
    
    // MARK: - Property
    /// コンテンツ領域のアウトレット
    @IBOutlet weak var contentView: UIStackView!
    /// 点検リストを表示する領域
    @IBOutlet weak var inspectionView: UIView!
    /// 点検リストの高さ
    @IBOutlet weak var inspectionViewHeight: NSLayoutConstraint!
    /// 点検項目がない時のメッセージのアウトレット
    @IBOutlet weak var nothingInspectionItemMessage: UILabel!
    /// 新規追加ボタンのアウトレット
    @IBOutlet weak var addNewButton: CustomButton!
    /// 検査完了ボタンのアウトレット
    @IBOutlet weak var inspectionCompletedButton: CustomButton!
    /// ポーリング基準時間
    private var pollingReferenceTime: Date?
    /// 次回ポーリング時間
    private var nextPollingReferenceTime: Date?
    /// タイマー(ポーリング処理用)
    private var timer: Timer = Timer()
    
    //MARK: -  定数
    /// 点検項目最大登録可能数
    private let MAX_ITEM_NUM: Int = 10
    /// ポーリング基準時間を設定する際の現在時刻からマイナスする時間量(分)
    private let REFERENCE_TIME: Int = 2
    /// 画面名
    private let SCREEN_NAME: String = "点検画面"
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // ナビゲーションバーの設定
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("unexpected error occured. UIAplication delegate is not AppDelegate.")
        }
        appDelegate.setNavigationController(self)
        //　縦画面に固定
        self.lockOrientation(UIInterfaceOrientationMask.portrait)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        infoLog(screen: SCREEN_NAME, logMessage: "画面表示")
        // ナビゲーションバーを設定
        NavigationBarController.shared.setNavigationBar(viewController: self, isUsedNavigationBar: true)
        //　縦画面に固定
        self.lockOrientation(UIInterfaceOrientationMask.portrait)
        // ポーリング時間の設定
        self.nextPollingReferenceTime = Calendar.current.date(byAdding: .minute, value: -REFERENCE_TIME, to:self.viewModel.getInspectionViewInfo().createDate ?? Date())
        // ポーリングインターバル毎にポーリング処理を実行
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(self.viewModel.getSettingValues().pollingPeriod), target: self, selector: #selector(self.pollingProcess), userInfo: nil, repeats: true)
        // 初回ポーリング
        timer.fire()
        // 点検Viewを表示
        self.showInspectionView()
        // 点検項目を取得し表示
        self.showInspectionItemView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // タイマーを破棄
        timer.invalidate()
        // インジケータ停止
        self.dismissIndicator()
    }
    
    // UITextField以外の部分を押下時キーボードを閉じる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // MARK: - Action
    
    /// 新規追加ボタンを押した時
    @IBAction func onTapNewButton(_ sender: Any) {
        infoLog(screen: SCREEN_NAME, logMessage: "新規追加ボタン押下")
        do {
            // 点検項目が10件よりも多い場合エラーを出す
            if self.contentView.subviews.count >= MAX_ITEM_NUM {
                throw ErrorID.ID0012
            }
            
            let popUpView = try self.viewModel.getPopUpView(popUpNo: INSPECTION_ITEM_POP_UP_NUMBER.ADD_NEW_RECORD, inspectionItemUUID: nil, uiImage: nil)
            popUpView.frame = self.view.bounds
            self.view.addSubview(popUpView)
        } catch {
            // エラー表示
            errorDialog(error: error == ErrorID.ID0012 ? error : ErrorID.ID9999, vc: self, handler: nil)
        }
    }
    
    /// 検査完了ボタンを押した時
    /// - Parameter sender: 検査完了ボタン
    @IBAction func onTapCompleteInspectionButton(_ sender: Any) {
        infoLog(screen: SCREEN_NAME, logMessage: "検査完了ボタン押下")
        // WSエビデンス登録画面を表示
        do {
            let popUpView = try self.viewModel.getPopUpView(popUpNo: INSPECTION_ITEM_POP_UP_NUMBER.WS_EVIDENCE, inspectionItemUUID: nil, uiImage: nil)
            popUpView.frame = self.view.bounds
            self.view.addSubview(popUpView)
        } catch {
            // エラー表示
            errorDialog(error: ErrorID.ID0028, vc: self, handler: nil)
        }
    }

    /// コメント表示ボタンが押された時
    func onTapDisplayCommentButton() {
        infoLog(screen: SCREEN_NAME, logMessage: "コメントボタン押下")
        do {
            // コメント表示ポップアップを生成する
            let popUpView = try self.viewModel.getPopUpView(popUpNo: INSPECTION_ITEM_POP_UP_NUMBER.SHOW_COMMENT, inspectionItemUUID: nil, uiImage: nil)
            popUpView.frame = self.view.bounds
            self.view.addSubview(popUpView)
        } catch {
            // エラー表示
            errorDialog(error: ErrorID.ID0016, vc: self, handler: nil)
        }
    }
    
    /// 点検結果編集ボタンを押した時
    /// - Parameter inspectionItemUUID: 点検項目ID
    func onTapExitInspectionResultButton(inspectionItemUUID: UUID) {
        infoLog(screen: SCREEN_NAME, logMessage: "点検結果編集ボタン押下")
        do {
            // 点検項目UUIDをセットする
            self.viewModel.setInspectionItemUUID(inspectionItemUUID: inspectionItemUUID)
            // 点検項目IDに該当するデータを取得
            let popUpView = try self.viewModel.getPopUpView(popUpNo: INSPECTION_ITEM_POP_UP_NUMBER.EXIT_INSPECTION_RESULT, inspectionItemUUID: inspectionItemUUID, uiImage: nil)
            popUpView.frame = self.view.bounds
            self.view.addSubview(popUpView)
        } catch {
            // エラー表示
            errorDialog(error: ErrorID.ID0014, vc: self, handler: nil)
        }
    }
    
    /// 点検項目削除ボタンを押した時
    /// - Parameter inspectionItemUUID: 点検項目ID
    func onTapDeleteButton(inspectionItemUUID: UUID) {
        infoLog(screen: SCREEN_NAME, logMessage: "点検削除ボタン押下")
        // 本当に削除するかどうかのアラートを表示
        Alert.cancelAlert(vc: self, message: DialogMessage.PartiallyDelete.rawValue, handler: { (_) in
            do {
                // 削除処理
                try self.viewModel.deleteInspectionItemData(inspectionItemUUID: inspectionItemUUID)
                // 点検項目を取得し表示
                self.showInspectionItemView()
            } catch {
                // エラー表示
                errorDialog(error: ErrorID.ID0008, vc: self, handler: nil)
            }
        })
    }

    /// NGコメント登録画面を表示
    /// - Parameter inspectionItemID: 点検項目ID
    func onTapNGCommentButton(inspectionItemUUID: UUID) {
        infoLog(screen: SCREEN_NAME, logMessage: "NGコメントボタン押下")
        do {
            // 点検IDをセットする
            self.viewModel.setInspectionItemUUID(inspectionItemUUID: inspectionItemUUID)
            /// 点検項目取得
            let popUpView = try self.viewModel.getPopUpView(popUpNo: INSPECTION_ITEM_POP_UP_NUMBER.REGIST_NG_COMMENT, inspectionItemUUID: inspectionItemUUID, uiImage: nil)
            popUpView.frame = self.view.bounds
            self.view.addSubview(popUpView)
        } catch {
            // エラー表示
            errorDialog(error: ErrorID.ID0017, vc: self, handler: nil)
        }
    }
    
    /// 画像拡大画面を表示
    /// - Parameter inspectionItemUUID: 点検項目ID
    func onTapEnlargeImageButton(inspectionItemUUID: UUID) {
        infoLog(screen: SCREEN_NAME, logMessage: "画像拡大ボタン押下")
        do {
            /// 点検項目取得
            let item = try RealmService.shared.getInspectionItemData(inspectionItemUUID: inspectionItemUUID)
            guard let s3Path = item.s3_original_image_path else {
                throw ErrorID.ID9999
            }
            // S3保存先バケット名の取得
            let bucketName = SettingDatasource.shared.getSettingValuesInfo().bucketName
            // インジケータの表示
            self.showIndicator()
            ApiService.shared.getS3ImageData(bucketName:bucketName, s3Path:s3Path) { uiImage in
                DispatchQueue.main.sync{
                    do {
                        // インジケータの非表示
                        self.dismissIndicator()
                        let popUpView = try self.viewModel.getPopUpView(popUpNo: INSPECTION_ITEM_POP_UP_NUMBER.ENLARGE_IMAGE, inspectionItemUUID: inspectionItemUUID, uiImage: uiImage)
                        popUpView.frame = self.view.bounds
                        self.view.addSubview(popUpView)
                    } catch {
                        // インジケータの非表示
                        self.dismissIndicator()
                        // 警告メッセージを表示し、noImageを表示する
                        errorDialog(error: ErrorID.ID0032, vc: self, handler: {_ in
                            let popUpView = EnlargeImageView()
                            popUpView.frame = self.view.bounds
                            self.view.addSubview(popUpView)
                        })
                    }
                }
            } failureHandler: { error in
                DispatchQueue.main.sync {
                    // インジケータの非表示
                    self.dismissIndicator()
                    // 警告メッセージを表示し、noImageを表示する
                    errorDialog(error: error == ErrorCause.ConnectionError ? ErrorID.ID0031 : ErrorID.ID0032, vc: self, handler: { _ in
                        let popUpView = EnlargeImageView()
                        popUpView.setImage(image: #imageLiteral(resourceName: "noImage.png"))
                        popUpView.frame = self.view.bounds
                        self.view.addSubview(popUpView)
                    })
                }
            }
        } catch {
            // インジケータの非表示
            self.dismissIndicator()
            // エラー表示
            errorDialog(error: ErrorID.ID0032, vc: self, handler: {_ in
                let popUpView = EnlargeImageView()
                popUpView.frame = self.view.bounds
                self.view.addSubview(popUpView)
            })
        }
    }
    
    /// 点検項目追加
    /// - Parameter inspectionItemName: 新しい点検項目名
    /// - Parameter handler: 自ビューの削除
    func onTapAddInspectionItem(inspectionItemName: String, handler: () -> Void) {
        do {
            // 点検項目名の入力チェック
            try validationInspectionItemName(itemName: inspectionItemName)
            // 該当の点検項目を取得
            let inspectionItemData = try self.viewModel.getInspectionItemDataList().filter({$0.item_name == inspectionItemName})
            
            // 点検項目名が重複しているか判別する
            if !inspectionItemData.isEmpty {
                // 点検項目名重複
                Alert.okAlert(vc: self, message: DialogMessage.DuplicateInspectionItemName.rawValue, handler: nil)
                return
            }
            // 点検項目をローカルDBに追加
            try self.viewModel.addInspectionItem(inspectionItemName: inspectionItemName)
            // 点検項目を再表示
            self.showInspectionItemView()
            // ハンドラー（自ビューの削除）
            handler()
        } catch {
            // エラー表示
            errorDialog(error: error == ErrorID.ID0011 ? error : ErrorID.ID0013, vc: self, handler: nil)
        }
    }
    
    /// 点検結果編集処理
    /// - Parameter exitInspectionResultView: 点検結果編集View
    /// - Parameter handler: 自ビューの削除
    func onTapExitInspectionResult(exitInspectionResultView: ExitInspectionResultView, handler: () -> Void) {
        do {
            // nilチェック
            guard let model = exitInspectionResultView.model.text, let serialNumber = exitInspectionResultView.serialNumber.text else {
                throw ErrorID.ID9999
            }
            // 品番入力チェック
            try validationModel(model: model)
            // 製造番号入力チェック
            try validationSerialNumber(serialNumber: serialNumber)
            // 点検結果編集
            try self.viewModel.exitInspectionResult(exitInspectionResultView: exitInspectionResultView)
            // 点検項目再表示
            self.showInspectionItemView()
            // ハンドラー（自ビューの削除）
            handler()
        } catch {
            // エラー表示
            errorDialog(error: error == ErrorID.ID0011 ? error : ErrorID.ID0015, vc: self, handler: nil)
        }
    }
    
    /// NGコメントを登録する処理
    /// - Parameter ngComment: NGコメント
    /// - Parameter handler: 自ビューの削除
    func onTapRegisterNGCommentButton(ngComment: String, handler: () -> Void) {
        do {
            // NGコメント入力チェック
            try validationNGComment(ngComment: ngComment)
            // NGコメント登録
            try self.viewModel.saveNGComment(ngComment: ngComment)
            // ハンドラー（自ビューの削除）
            handler()
        } catch {
            // エラー表示
            errorDialog(error: error == ErrorID.ID0011 ? error : ErrorID.ID0018, vc: self, handler: nil)
        }
    }
    
    /// 画像解析指示
    /// - Parameters:
    ///   - inspectionItemID: 点検項目ID
    ///   - inspectionItemName: 点検名
    func onTapAnalysisButton(inspectionItemID: Int) {
        infoLog(screen: SCREEN_NAME, logMessage: "解析ボタン押下")
        /// インジケータ表示
        self.showIndicator()
        do {
            
            // 画像チェック
            if try self.viewModel.checkLocalImageSize(inspectionItemId: inspectionItemID) == false {
                // インジケータの非表示
                self.dismissIndicator()
                // ダイアログ表示
                Alert.okAlert(vc: self, message: "横画面で撮影されているため画像解析ができません。再度縦画面で撮影をしてから画像解析を実施してください。", handler: nil)
                return
            }
            try self.viewModel.imageAnalysis(inspectionItemID: inspectionItemID, successHandler: {
                // インジケータの非表示
                self.dismissIndicator()
                // 点検Viewを更新
                self.showInspectionView()
                // 点検項目を取得し表示
                self.showInspectionItemView()
            }, failureHandler: {error in
                // インジケータの非表示
                self.dismissIndicator()
                // エラー表示
                errorDialog(error: error ?? ErrorID.ID9999 == ErrorCause.ConnectionError ? ErrorID.ID0006 : ErrorID.ID0007, vc: self, handler: nil)
            })
        } catch {
            // インジケータの非表示
            self.dismissIndicator()
            // エラー表示
            errorDialog(error: ErrorID.ID0007, vc: self, handler: nil)
        }
    }
    
    /// カメラ画面に遷移
    /// - Parameters:
    ///   - inspectionItemUUID: 点検項目ID(UUID)
    ///   - inspectionItemID: 点検項目ID(Int)
    ///   - inspectionItemName: 点検項目名
    ///   - inspectionItemNameID: 点検項目名ID
    ///   - analysisType: 解析種別
    func onTapPhotograph(inspectionItemUUID: UUID, inspectionItemID: Int?, inspectionItemName: String, inspectionItemNameID: Int?, analysisType: String?) {
        infoLog(screen: SCREEN_NAME, logMessage: "撮影ボタン押下")
        // 点検項目IDをセットする(UUID)
        self.viewModel.setInspectionItemUUID(inspectionItemUUID: inspectionItemUUID)
        // 点検項目IDをセットする(Int)
        self.viewModel.setInspectionItemID(inspectionItemID: inspectionItemID)
        // 点検項目名を設定
        self.viewModel.setInspectionItemName(inspectionItemName: inspectionItemName)
        // 解析種別を設定
        self.viewModel.setInspectionItemAnalysisType(analysisType: analysisType)
        /// 点検項目名IDを設定
        self.viewModel.setInspectionItemNameID(inspectionItemNameID: inspectionItemNameID)
        /// カメラ画面に遷移
        if let vc = R.storyboard.cameraViewController.instantiateInitialViewController() {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    /// 撮影画像再送
    /// - Parameters:
    ///   - inspectionItemUUID: 点検項目UUID
    ///   - inspectionItemID: 点検項目ID
    ///   - inspectionItemName: 点検項目名
    ///   - inspectionItemNameID: 点検項目名ID
    ///   - analysisType: 解析種別
    func onTapResend(inspectionItemUUID: UUID, inspectionItemID: Int?, inspectionItemName: String, inspectionItemNameID: Int?, analysisType: String?) {
        infoLog(screen: SCREEN_NAME, logMessage: "再送ボタン押下")
        // ローカルに画像が保存されているか確認
        do {
            try self.viewModel.checkSsavedLocally(inspectionItemUUID: inspectionItemUUID)
        } catch {
            // ローカルに画像なし
            // エラー表示
            errorDialog(error: ErrorID.ID0034, vc: self, handler: { _ in
                // カメラ画面に遷移
                self.onTapPhotograph(inspectionItemUUID: inspectionItemUUID, inspectionItemID: inspectionItemID, inspectionItemName: inspectionItemName, inspectionItemNameID: inspectionItemNameID , analysisType: analysisType)
            })
            // 後続処理を行わない
            return
        }
        
        // インジケータの表示
        self.showIndicator()
        
        // 画像の再送
        self.viewModel.resendImage(inspectionItemUUID: inspectionItemUUID, success: {
            // インジケータの非表示
            self.dismissIndicator()
            DispatchQueue.main.async {
                // ダイアログを表示する
                Alert.okAlert(vc: self, message: DialogMessage.SaveImageSuccess.rawValue) { _ in
                    self.showInspectionView()
                    self.showInspectionItemView()
                }
            }
        }, failure: { error in
            // インジケータの非表示
            self.dismissIndicator()
            DispatchQueue.main.async {
                // エラー表示
                errorDialog(error: ErrorID.ID0027, vc: self, handler: nil)
            }
        })
    }
    
    /// WSエビデンス登録ボタンが押されたとき
    /// - Parameter evidenceID: エビデンスID
    func onTapRegisterWSEvidence(evidenceID: Int, isEditable: Bool) {
        do {
            // 該当する点検項目データを取得
            let inspectionItemDataList = try self.viewModel.getInspectionItemDataList()
            // 検査完了による状態の遷移
            let checkStatusResult = self.checkStatus(evidenceID: evidenceID, isEditable: isEditable, inspectionItemDataList: inspectionItemDataList)
            // ダイアログの表示
            Alert.cancelAlert(vc: self, message: checkStatusResult.dialogMessage, handler: { (_) in
                // 検査完了APIを送信する
                self.inspectionResultApiRequest(evidenceID: evidenceID, isEditable: isEditable, inspectionItemDataList: inspectionItemDataList, status: checkStatusResult.status)
            })
        } catch {
            // エラー表示
            errorDialog(error: ErrorID.ID0030, vc: self, handler: nil)
        }
    }
    
    // MARK: - Method
    
    /// ポーリング処理
    @objc private func pollingProcess() {
        do {
            // 点検の取得
            let inspectionData = self.viewModel.getInspectionViewInfo()
            // 点検データが検査待ちならreturn
            if inspectionData.status == INSPECTION_STATUS.WAITING.rawValue {
                // 後続処理をしない
                return
            }
            // 保存しておいた日付をリクエストを送る際の日付に保存する
            self.pollingReferenceTime = self.nextPollingReferenceTime
            // ポーリング処理直前の日時を保存する
            let justBeforeDate = Date()
            
            guard let date = self.pollingReferenceTime?.ISO8601Format() else {
                throw ErrorID.ID0010
            }
            
            // 点検データが終了状態の時、ポーリング処理を止める
            if inspectionData.status != INSPECTION_STATUS.WAITING.rawValue && inspectionData.status != INSPECTION_STATUS.UNDER_INSPECTION.rawValue && inspectionData.status != INSPECTION_STATUS.RE_INSPECTION.rawValue {
                // タイマーを止める
                timer.invalidate()
            } else {
                infoLog(screen: SCREEN_NAME, logMessage: "ポーリング処理実施")
                // 最終更新日時以降に更新されたデータを取得し、versionが書き換わっているデータだけローカルに保存する
                try self.viewModel.getAnalysisResultApi(lastUpdatedAt: date, successHandler: {
                    // ポーリング処理が成功した場合のみ次ポーリングをかける日時を保存する
                    self.nextPollingReferenceTime = justBeforeDate
                    // 点検Viewを更新
                    self.showInspectionView()
                    // 点検項目を取得し表示
                    self.showInspectionItemView()
                }, failureHandler: { error in
                    // エラー表示
                    errorDialog(error: error ?? ErrorID.ID9999 == ErrorCause.ConnectionError ? ErrorID.ID0009 : ErrorID.ID0010, vc: self, handler: nil)
                })
            }
        } catch {
            // エラー表示
            errorDialog(error: error, vc: self, handler: nil)
        }
    }
    
    /// 点検情報を表示する処理
    private func showInspectionView() {
            // 点検情報を取得
            let inspectionContent = self.viewModel.getInspectionInfo()
            inspectionContent.frame = self.inspectionView.bounds
            inspectionViewHeight.constant = inspectionView.bounds.height
            // 状態のレイアウトセット
        self.showInspectionStatus(inspectionView: inspectionContent, state: INSPECTION_STATUS(rawValue: self.viewModel.getInspectionViewInfo().status) ?? .WAITING)
            // 点検情報コンテンツ追加
            self.inspectionView.addSubview(inspectionContent)
    }
    
    /// 点検項目を取得し表示する
    private func showInspectionItemView() {
        do {
            // 点検項目を取得
            let inspectionItemDataList = try self.viewModel.getInspectionItemDataList()
            let sortList = inspectionItemDataList.sorted(by: {
                if $0.inspection_item_id == nil { return false }
                else if $1.inspection_item_id == nil { return false }
                else { return $0.inspection_item_id! < $1.inspection_item_id!}
            })
            
            // 点検項目の表示をリセット
            self.contentView.subviews.forEach { subView in
                subView.removeFromSuperview()
            }
            // 点検項目の解析種別ごとのVIewを取得
            let contentsList = self.viewModel.getInspectionItem(inspectionItemDataList: sortList)
            // 点検画面に描画する
            contentsList.enumerated().forEach { (index, content) in
                // スクロールViewに表示
                self.contentView.insertArrangedSubview(content,at: index)
            }
            // 点検項目が0件の場合、メッセージを表示する
            self.nothingInspectionItemMessage.isHidden = (inspectionItemDataList.count != 0)

            // 点検画面のボタン(新規追加ボタン、検査完了ボタン)の活性非活性
            self.setActivationInspectionViewButton(inspectionItemDataList: inspectionItemDataList)
        } catch {
            // エラー表示
            errorDialog(error: ErrorID.ID0005, vc: self, handler: nil)
        }
    }
    
    /// 点検画面のボタンの活性非活性制御
    /// - 現段階では、新規追加ボタン、検査完了ボタンの制御
    /// - Parameter inspectionItemDataList: 点検項目データリスト
    private func setActivationInspectionViewButton(inspectionItemDataList: [TBL_T_INSPECTION_ITEM]) {
        let inspectionInfo = self.viewModel.getInspectionViewInfo()
        // progressでボタンを制御
        for inspectionItemData in inspectionItemDataList {
            // 点検項目のうち1つでもprogressが3(依頼中),4(解析中)である場合
            if inspectionItemData.progress == INSPECTION_PROGRESS.ANALYSIS_REQUEST.rawValue || inspectionItemData.progress == INSPECTION_PROGRESS.ANALYSIS.rawValue {
                // 検査完了ボタンを非活性
                self.inspectionCompletedButton.isEnabled = false
                break
            }
            // 検査完了ボタンを活性
            self.inspectionCompletedButton.isEnabled = true
        }
        // 点検データの状態で新規追加ボタン、検査完了ボタンを制御
        switch inspectionInfo.status {
            // 終了※（未完了がある場合）、全て正常
        case INSPECTION_STATUS.PARTIALLY_COMPLETED.rawValue, INSPECTION_STATUS.COMPLETED.rawValue:
            // 新規追加ボタンを非活性
            self.addNewButton.isEnabled = false
            // 検査完了ボタンを非活性
            self.inspectionCompletedButton.isEnabled = false
        default:
            break
        }
    }
    
    /// 検査完了API送信
    /// - Parameters:
    ///   - inspectionItemData: 点検項目データリスト
    ///   - inspectionData: 点検
    private func inspectionResultApiRequest(evidenceID: Int, isEditable: Bool, inspectionItemDataList: [TBL_T_INSPECTION_ITEM], status: INSPECTION_STATUS) {
        do {
            // インジケータの表示
            self.showIndicator()
            // 検査完了ボディの点検項目リスト
            let inspectionResultItems: [InspectionResultItems] = self.viewModel.getInspectionResultItems(inspectionItemDataList: inspectionItemDataList)
            // 検査完了ボディの削除リスト
            let deleteList: [DeleteList] = try self.viewModel.getDeleteInspectionItemDataList()
            
            // 検査完了APIを送信する
            self.viewModel.inspectionResultApiRequest(evidenceID: evidenceID, status: status, inspectionResultItems: inspectionResultItems, deleteList: deleteList, successHandler: {
                // インジケータ非表示
                self.dismissIndicator()
                // ログアウトし待機画面へ遷移
                NavigationBarController.shared.logout()
            }, failureHandler: { error in
                // インジケータ非表示
                self.dismissIndicator()
                // エラー表示
                errorDialog(error: error ?? ErrorID.ID9999 == ErrorCause.ConnectionError ? ErrorID.ID0029 : ErrorID.ID0030, vc: self, handler: nil)
            })
        } catch {
            // インジケータ非表示
            self.dismissIndicator()
            // エラー表示
            errorDialog(error: ErrorID.ID0030, vc: self, handler: nil)
        }
    }
    
    /// ステータスをチェックし、判定結果とセットしたい点検状態を返す
    /// - Parameter inspectionItemDataList: 点検項目データリスト
    /// - Returns: 判定結果(Bool),点検状態
    private func checkStatus(evidenceID: Int, isEditable: Bool, inspectionItemDataList: [TBL_T_INSPECTION_ITEM]) -> (dialogMessage: String, status: INSPECTION_STATUS) {
            for data in inspectionItemDataList {
                // 解析種別によって判定する
                switch data.analysis_type {
                    // OCRの時
                case INSPECTION_ITEM_TYPE.OCR.rawValue:
                    // 進捗状況が解析完了以外の時
                    if data.progress != INSPECTION_PROGRESS.ANALYSIS_COMPLETED.rawValue {
                        return isEditable ?
                        (DialogMessage.InspectionNotImplemented.rawValue, INSPECTION_STATUS.RE_INSPECTION) :
                        (DialogMessage.InspectionNotImplemented.rawValue, INSPECTION_STATUS.PARTIALLY_COMPLETED)
                    }
                    // 読取失敗がある場合
                    if (data.model == OCR_FAILURE && ((data.edited_model?.isEmpty) == nil)) || (data.serial_number == OCR_FAILURE && ((data.edited_serial_number?.isEmpty) == nil)) {
                        return isEditable ?
                        (DialogMessage.InspectionAnalysisFailed.rawValue, INSPECTION_STATUS.RE_INSPECTION) :
                        (DialogMessage.InspectionAnalysisFailed.rawValue, INSPECTION_STATUS.PARTIALLY_COMPLETED)
                    }
                    // AIの時
                case INSPECTION_ITEM_TYPE.AI.rawValue:
                    // 進捗状況が解析完了以外の時
                    if data.progress != INSPECTION_PROGRESS.ANALYSIS_COMPLETED.rawValue {
                        return isEditable ?
                        (DialogMessage.InspectionNotImplemented.rawValue, INSPECTION_STATUS.RE_INSPECTION) :
                        (DialogMessage.InspectionNotImplemented.rawValue, INSPECTION_STATUS.PARTIALLY_COMPLETED)
                    }
                    
                    // NGがあり、NGコメントを書いていないものがある場合
                    if data.ai_result == AI_NG && data.ng_comment == nil  {
                        return isEditable ?
                        (DialogMessage.InspectionNg.rawValue, INSPECTION_STATUS.RE_INSPECTION) :
                        (DialogMessage.InspectionNg.rawValue, INSPECTION_STATUS.PARTIALLY_COMPLETED)
                    }
                    
                    // 解析失敗があり、NGコメントを書いていないものがある場合
                    if data.ai_result == AI_FAILURE && data.ng_comment == nil {
                        return isEditable ?
                        (DialogMessage.InspectionAnalysisFailed.rawValue, INSPECTION_STATUS.RE_INSPECTION) :
                        (DialogMessage.InspectionAnalysisFailed.rawValue, INSPECTION_STATUS.PARTIALLY_COMPLETED)
                    }
                    // それ以外
                default:
                    // 撮影していないかどうかを判定
                    if (data.progress == INSPECTION_PROGRESS.WAITING_SHOOTING.rawValue) {
                        return isEditable ?
                        (DialogMessage.InspectionNotImplemented.rawValue, INSPECTION_STATUS.RE_INSPECTION) :
                        (DialogMessage.InspectionNotImplemented.rawValue, INSPECTION_STATUS.PARTIALLY_COMPLETED)
                    }
                }
            }
            return isEditable ? 
            (DialogMessage.InspectionCompleted.rawValue, INSPECTION_STATUS.RE_INSPECTION) :
            (DialogMessage.InspectionCompleted.rawValue, INSPECTION_STATUS.COMPLETED)
    }
    
    /// 点検データの点検状態によってイメージを変更
    /// - Parameters:
    ///   - inspectionView: 点検データ
    ///   - state: 状態
    private func showInspectionStatus(inspectionView: InspectionView, state: INSPECTION_STATUS) {
        switch state {
        case .WAITING:
            // 検査待ち
            inspectionView.statusButton.setBackgroundImage(#imageLiteral(resourceName: "label_status1.svg"), for: .normal)
            inspectionView.statusButton.setImage(#imageLiteral(resourceName: "label_status1_icon.svg"), for: .normal)
        case .UNDER_INSPECTION:
            // 検査中
            inspectionView.statusButton.setBackgroundImage(#imageLiteral(resourceName: "label_status2.svg"), for: .normal)
            inspectionView.statusButton.setImage(#imageLiteral(resourceName: "label_status2_icon.svg"), for: .normal)
        case .RE_INSPECTION:
            // 再点検
            inspectionView.statusButton.setBackgroundImage(#imageLiteral(resourceName: "label_status5.svg"), for: .normal)
            inspectionView.statusButton.setImage(#imageLiteral(resourceName: "label_status5_icon.svg"), for: .normal)
        case .PARTIALLY_COMPLETED:
            // 終了※
            inspectionView.statusButton.setBackgroundImage(#imageLiteral(resourceName: "label_status4.svg"), for: .normal)
            inspectionView.statusButton.setImage(#imageLiteral(resourceName: "label_status4_icon.svg"), for: .normal)

        case .COMPLETED:
            // 終了
            inspectionView.statusButton.setBackgroundImage(#imageLiteral(resourceName: "label_status3.svg"), for: .normal)
            inspectionView.statusButton.setImage(#imageLiteral(resourceName: "label_status3_icon.svg"), for: .normal)
        }
    }
}
