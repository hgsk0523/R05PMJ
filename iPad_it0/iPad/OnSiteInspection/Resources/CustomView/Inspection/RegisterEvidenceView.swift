import UIKit

/// エビデンス登録View
class RegisterEvidenceView: UIView {
    
    // MARK: - Property
    
    /// ラジオコンテンツのテーブルビュー
    @IBOutlet weak var registerEvidenceContent: UITableView!
    
    /// 登録ボタン
    @IBOutlet weak var registerButton: UIButton!
    
    /// コンテンツテーブルのセルのオブジェクトを格納する配列
    private let contentCellArray : NSMutableArray = NSMutableArray.init()
    
    // MARK: - Lifecycle
    
    /// コードから生成された場合
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
        // 初期設定
        self.initialSetting()
    }
    
    /// ストーリーボードから生成された場合
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        loadNib()
        // 初期設定
        self.initialSetting()
    }
    
    private func loadNib(){
        let view = Bundle.main.loadNibNamed("RegisterEvidenceView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
    }
    // MARK: - Method
    
    /// 初期設定をする関数
    private func initialSetting() {
        // デリゲートの設定
        self.registerEvidenceContent.delegate = self
        self.registerEvidenceContent.dataSource = self
        // テーブルにカスタムViewを入れるための処理
        self.registerEvidenceContent.register(UINib(nibName: "WSEvidenceContentView", bundle: nil), forCellReuseIdentifier: "customCell")
        // 登録ボタンを非活性
        self.registerButton.isEnabled = false
        // テーブルビューをリロードする
        self.registerEvidenceContent.reloadData()
    }
    
    /// ボタンの活性非活性を設定
    private func setActivationButton() {
        // 配列の型チェック
        if let contentCellArray = self.contentCellArray as? [WSEvidenceContentView] {
            // １つでもラジオボタンが押されているかどうかを判断する
            for data : WSEvidenceContentView in contentCellArray {
                if data.getRadioButtonFlag() {
                    // 登録ボタンを活性
                    self.registerButton.isEnabled = true
                    return
                }
            }
            // 登録ボタンを非活性
            self.registerButton.isEnabled = false
        }
    }
    
    /// エビデンス情報設定
    /// - Parameter worksheetEvidenceItem: エビデンス情報
    func setWorksheetEvidenceItem(worksheetEvidenceItem: [WorksheetEvidenceItem]) {
        // エビデンス情報分、エビデンスを作成する
        worksheetEvidenceItem.enumerated().forEach { (index, info) in
            // テーブル追加処理
            let cell : WSEvidenceContentView = WSEvidenceContentView.initFromNib()
            // エビデンス名
            cell.label.text = info.evidenceName
            // エビデンスID
            cell.setEvidenceID(evidenceID: info.evidenceId)
            // 再点検フラグ
            cell.setIsEditable(isEditable: info.isEditable)
            // 新しいコンテンツが上に表示されるように挿入する
            self.contentCellArray.insert(cell, at: index)
        }
    }
    
    // MARK: - Action
    
    /// 閉じるボタンを押した時
    /// - Parameter sender: 閉じるボタン
    @IBAction func onTapCloseButton(_ sender: Any) {
        self.removeFromSuperview()
    }
    
    /// 登録ボタンを押した時
    /// - Parameter sender: 登録ボタン
    @IBAction func onTapRegisterButton(_ sender: Any) {
        // 配列の型チェック
        if let contentCellArray = self.contentCellArray as? [WSEvidenceContentView] {
            // 押されているラジオボタンを判断する
            for data : WSEvidenceContentView in contentCellArray {
                if data.getRadioButtonFlag() {
                    // 押されているラジオボタンを発見したら、そのボタンのデータを引数に持たせてエビデンス登録処理をする
                    if let parentVC = self.parentViewController() as? InspectionViewController {
                        // エビデンス登録処理
                        parentVC.onTapRegisterWSEvidence(evidenceID: data.getEvidenceID(), isEditable: data.getIsEditable())
                    }
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension RegisterEvidenceView: UITableViewDelegate, UITableViewDataSource {
    /// テーブルビューのセルの数を設定する
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contentCellArray.count
    }
    
    /// テーブルビューのセルの中身を設定する
    /// セルの数だけ処理が行われる
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = self.contentCellArray.object(at: indexPath.row) as? WSEvidenceContentView else {
            return UITableViewCell()
        }
        return cell
    }
    
    /// テーブルビューのセルが押されたら呼ばれる
    internal func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 押されたWSエビデンスコンテンツの取得
        guard let tappedCell = self.contentCellArray.object(at: indexPath.row) as? WSEvidenceContentView else {
            return
        }
        // ラジオボタンの状態によってフラグ、イメージを変更する
        self.contentCellArray.objectEnumerator().forEach { wsContent in
            // セルのnilチェック
            guard let cell = wsContent as? WSEvidenceContentView else {
                return
            }
            // タップされたセル、押された状態のセル以外の時
            // 何もしない
            if !(tappedCell == cell || cell.getRadioButtonFlag()) {
                return
            }
            // フラグとイメージをセット
            cell.setRadioButtonFlag(flag: !cell.getRadioButtonFlag())
            cell.setRadioButtonImage()
        }
        // 登録ボタンの活性非活性
        self.setActivationButton()
    }
    
    /// セルの高さを決める
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // 押されたWSエビデンスコンテンツの取得
        guard let cell = self.contentCellArray.object(at: indexPath.row) as? WSEvidenceContentView else {
            return 0
        }
        return cell.wsEvidenceContent.bounds.height
    }
}
