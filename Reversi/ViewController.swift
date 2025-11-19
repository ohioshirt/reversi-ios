import UIKit
import Combine

class ViewController: UIViewController {
    @IBOutlet private var boardView: BoardView!

    @IBOutlet private var messageDiskView: DiskView!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var messageDiskSizeConstraint: NSLayoutConstraint!
    /// Storyboard 上で設定されたサイズを保管します。
    /// 引き分けの際は `messageDiskView` の表示が必要ないため、
    /// `messageDiskSizeConstraint.constant` を `0` に設定します。
    /// その後、新しいゲームが開始されたときに `messageDiskSize` を
    /// 元のサイズで表示する必要があり、
    /// その際に `messageDiskSize` に保管された値を使います。
    private var messageDiskSize: CGFloat!

    @IBOutlet private var playerControls: [UISegmentedControl]!
    @IBOutlet private var countLabels: [UILabel]!
    @IBOutlet private var playerActivityIndicators: [UIActivityIndicatorView]!

    // MARK: - New Architecture Components

    /// ゲームエンジン（Domain層）
    private let gameEngine: GameEngine

    /// ゲームViewModel（Application層）
    private let viewModel: GameViewModel

    /// ゲームリポジトリ（Repository層）
    private let repository: GameRepository

    /// Combineのキャンセル管理
    private var cancellables = Set<AnyCancellable>()

    /// 前回の盤面状態（diffingに使用）
    private var previousBoard: Board?

    // MARK: - Animation Management

    private var animationCanceller: Canceller?
    private var isAnimating: Bool { animationCanceller != nil }

    private var playerCancellers: [Disk: Canceller] = [:]

    // MARK: - Initialization

    /// 依存性のファクトリークロージャ（テスト時にモックと差し替え可能）
    static var makeDependencies: () -> (GameEngine, GameViewModel, GameRepository) = {
        let engine = GameEngine()
        let viewModel = GameViewModel(engine: engine)
        let repository = FileGameRepository()
        return (engine, viewModel, repository)
    }

    init?(coder: NSCoder, gameEngine: GameEngine, viewModel: GameViewModel, repository: GameRepository) {
        self.gameEngine = gameEngine
        self.viewModel = viewModel
        self.repository = repository
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        // ファクトリーから依存性を取得（テスト時には差し替え可能）
        let (engine, viewModel, repository) = Self.makeDependencies()
        self.gameEngine = engine
        self.viewModel = viewModel
        self.repository = repository
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        boardView.delegate = self
        messageDiskSize = messageDiskSizeConstraint.constant

        // ViewModelの状態変更を監視
        setupBindings()

        do {
            try loadGame()
        } catch _ {
            newGame()
        }
    }

    // MARK: - ViewModel Bindings (Board state changes, Pass events)

    /// ViewModelの状態変更をUIに反映するバインディングを設定
    private func setupBindings() {
        // 盤面の変更を監視
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.syncBoardViewWithState(state)
            }
            .store(in: &cancellables)

        // パスイベントを監視
        viewModel.passEvent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] passEvent in
                self?.showPassAlert(for: passEvent.passedPlayer)
            }
            .store(in: &cancellables)
    }

    /// パスアラートを表示
    private func showPassAlert(for disk: Disk) {
        let alertController = UIAlertController(
            title: "Pass",
            message: "Cannot place a disk.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default) { [weak self] _ in
            self?.waitForPlayer()
        })
        present(alertController, animated: true)
    }

    /// ViewModelのStateとBoardViewを同期
    ///
    /// パフォーマンス最適化: 前回の盤面状態とdiffを取り、変更されたセルのみを更新します。
    private func syncBoardViewWithState(_ state: GameState) {
        let currentBoard = state.board

        if let previousBoard = previousBoard {
            // Diffをとって、変更されたセルのみを更新（最適化）
            for y in 0..<Board.height {
                for x in 0..<Board.width {
                    let position = Position(x: x, y: y)
                    let currentDisk = currentBoard.disk(at: position)
                    let previousDisk = previousBoard.disk(at: position)

                    if currentDisk != previousDisk {
                        boardView.setDisk(currentDisk, atX: x, y: y, animated: false)
                    }
                }
            }
        } else {
            // 初回またはリセット後は全セルを更新
            for y in 0..<Board.height {
                for x in 0..<Board.width {
                    let position = Position(x: x, y: y)
                    let disk = currentBoard.disk(at: position)
                    boardView.setDisk(disk, atX: x, y: y, animated: false)
                }
            }
        }

        // 盤面状態を保存（次回のdiff用）
        previousBoard = currentBoard

        // UI要素を更新
        updateMessageViews()
        updateCountLabels()
    }
    
    private var viewHasAppeared: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if viewHasAppeared { return }
        viewHasAppeared = true
        waitForPlayer()
    }
}

// MARK: Reversi logics

extension ViewController {
    /// `side` で指定された色のディスクが盤上に置かれている枚数を返します。
    /// - Parameter side: 数えるディスクの色です。
    /// - Returns: `side` で指定された色のディスクの、盤上の枚数です。
    func countDisks(of side: Disk) -> Int {
        // ViewModelに委譲
        return viewModel.diskCount(for: side)
    }

    /// 盤上に置かれたディスクの枚数が多い方の色を返します。
    /// 引き分けの場合は `nil` が返されます。
    /// - Returns: 盤上に置かれたディスクの枚数が多い方の色です。引き分けの場合は `nil` を返します。
    func sideWithMoreDisks() -> Disk? {
        // ViewModelに委譲
        return viewModel.winner()
    }
    
    private func flippedDiskCoordinatesByPlacingDisk(_ disk: Disk, atX x: Int, y: Int) -> [(Int, Int)] {
        // GameEngineに委譲（読み取り専用）
        let position = Position(x: x, y: y)
        let flippedPositions = gameEngine.flippedDiskPositions(at: position, for: disk, in: viewModel.state.board)
        return flippedPositions.map { (x: $0.x, y: $0.y) }
    }
    
    /// `x`, `y` で指定されたセルに、 `disk` が置けるかを調べます。
    /// ディスクを置くためには、少なくとも 1 枚のディスクをひっくり返せる必要があります。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Returns: 指定されたセルに `disk` を置ける場合は `true` を、置けない場合は `false` を返します。
    func canPlaceDisk(_ disk: Disk, atX x: Int, y: Int) -> Bool {
        // ViewModelに委譲
        let position = Position(x: x, y: y)
        return gameEngine.canPlaceDisk(at: position, for: disk, in: viewModel.state.board)
    }

    /// `side` で指定された色のディスクを置ける盤上のセルの座標をすべて返します。
    /// - Returns: `side` で指定された色のディスクを置ける盤上のすべてのセルの座標の配列です。
    func validMoves(for side: Disk) -> [(x: Int, y: Int)] {
        // ViewModelに委譲
        let positions = viewModel.validMoves(for: side)
        return positions.map { (x: $0.x, y: $0.y) }
    }

    /// `x`, `y` で指定されたセルに `disk` を置きます。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Parameter isAnimated: ディスクを置いたりひっくり返したりするアニメーションを表示するかどうかを指定します。
    /// - Parameter completion: アニメーション完了時に実行されるクロージャです。
    ///     このクロージャは値を返さず、アニメーションが完了したかを示す真偽値を受け取ります。
    ///     もし `animated` が `false` の場合、このクロージャは次の run loop サイクルの初めに実行されます。
    ///
    /// 注: 配置の検証はViewModelレイヤーで一度だけ実行されます。
    /// 無効な配置の場合、completionにfalseが渡されます。
    func placeDisk(_ disk: Disk, atX x: Int, y: Int, animated isAnimated: Bool, completion: ((Bool) -> Void)? = nil) {
        let position = Position(x: x, y: y)

        Task {
            // 配置検証と反転座標取得（ViewModelレイヤーで一度だけ実行）
            let flippedPositions = gameEngine.flippedDiskPositions(at: position, for: disk, in: viewModel.state.board)

            guard !flippedPositions.isEmpty else {
                // 無効な手の場合は何もせずに終了
                completion?(false)
                return
            }

            let diskCoordinates = flippedPositions.map { ($0.x, $0.y) }

            if isAnimated {
                let cleanUp: () -> Void = { [weak self] in
                    self?.animationCanceller = nil
                }
                self.animationCanceller = Canceller(cleanUp)

                let animationCompleted = await self.animateSettingDisksAsync(at: [(x, y)] + diskCoordinates, to: disk)

                guard let canceller = self.animationCanceller else { return }
                if canceller.isCancelled { return }

                // ViewModelの状態を更新（非同期）
                // 注: すでに検証済みなので、placeDiskは成功するはず
                let placementSuccess = await self.viewModel.placeDisk(at: position)
                if placementSuccess {
                    try? self.saveGame()
                }

                // アニメーションキャンセラーをクリーンアップ
                cleanUp()
                completion?(animationCompleted && placementSuccess)
            } else {
                let success = await self.viewModel.placeDisk(at: position)
                if success {
                    try? self.saveGame()
                }
                completion?(success)
            }
        }
    }
    
    /// `coordinates` で指定されたセルに、アニメーションしながら順番に `disk` を置く（async版）
    ///
    /// このメソッドは `animateSettingDisks` のasyncラッパーで、
    /// コールバックベースのAPIをasync/awaitスタイルに変換します。
    ///
    /// - Parameters:
    ///   - coordinates: ディスクを置くセルの座標のコレクション
    ///   - disk: 配置するディスク
    /// - Returns: すべてのアニメーションが正常に完了した場合は `true`、キャンセルされた場合は `false`
    @MainActor
    private func animateSettingDisksAsync<C: Collection>(at coordinates: C, to disk: Disk) async -> Bool
        where C.Element == (Int, Int)
    {
        await withCheckedContinuation { continuation in
            animateSettingDisks(at: coordinates, to: disk) { completed in
                continuation.resume(returning: completed)
            }
        }
    }

    /// `coordinates` で指定されたセルに、アニメーションしながら順番に `disk` を置く。
    /// `coordinates` から先頭の座標を取得してそのセルに `disk` を置き、
    /// 残りの座標についてこのメソッドを再帰呼び出しすることで処理が行われる。
    /// すべてのセルに `disk` が置けたら `completion` ハンドラーが呼び出される。
    private func animateSettingDisks<C: Collection>(at coordinates: C, to disk: Disk, completion: @escaping (Bool) -> Void)
        where C.Element == (Int, Int)
    {
        guard let (x, y) = coordinates.first else {
            completion(true)
            return
        }

        let animationCanceller = self.animationCanceller!
        boardView.setDisk(disk, atX: x, y: y, animated: true) { [weak self] isFinished in
            guard let self = self else { return }
            if animationCanceller.isCancelled { return }
            if isFinished {
                self.animateSettingDisks(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                for (x, y) in coordinates {
                    self.boardView.setDisk(disk, atX: x, y: y, animated: false)
                }
                completion(false)
            }
        }
    }
}

// MARK: Game management

extension ViewController {
    /// ゲームの状態を初期化し、新しいゲームを開始します。
    func newGame() {
        // ViewModelで新しいゲームを開始
        viewModel.newGame()

        // プレイヤーモードをマニュアルにリセット
        for playerControl in playerControls {
            playerControl.selectedSegmentIndex = Player.manual.rawValue
        }

        // ViewModelの状態更新により、Combineバインディングで自動的にUIが更新される
        try? saveGame()
    }
    
    /// プレイヤーの行動を待ちます。
    func waitForPlayer() {
        guard let turn = viewModel.state.currentTurn else { return }
        switch Player(rawValue: playerControls[turn.index].selectedSegmentIndex)! {
        case .manual:
            break
        case .computer:
            playTurnOfComputer()
        }
    }
    
    /// ディスク配置後のゲームフローを続けます。
    /// 現在のプレイヤー（ViewModelで自動的に決定されたターン）の行動を待ちます。
    ///
    /// 注: ターン管理自体はGameViewModelが行います。このメソッドは単に
    /// 次のプレイヤー（コンピュータまたは手動）の行動を促すだけです。
    func continueGameFlow() {
        waitForPlayer()
    }
    
    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    func playTurnOfComputer() {
        guard let turn = viewModel.state.currentTurn else { preconditionFailure() }
        let (x, y) = validMoves(for: turn).randomElement()!

        playerActivityIndicators[turn.index].startAnimating()
        
        let cleanUp: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.playerActivityIndicators[turn.index].stopAnimating()
            self.playerCancellers[turn] = nil
        }
        let canceller = Canceller(cleanUp)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            if canceller.isCancelled { return }
            cleanUp()

            self.placeDisk(turn, atX: x, y: y, animated: true) { [weak self] _ in
                self?.continueGameFlow()
            }
        }
        
        playerCancellers[turn] = canceller
    }
}

// MARK: Views

extension ViewController {
    /// 各プレイヤーの獲得したディスクの枚数を表示します。
    func updateCountLabels() {
        for side in Disk.sides {
            countLabels[side.index].text = "\(countDisks(of: side))"
        }
    }
    
    /// 現在の状況に応じてメッセージを表示します。
    func updateMessageViews() {
        switch viewModel.state.currentTurn {
        case .some(let side):
            messageDiskSizeConstraint.constant = messageDiskSize
            messageDiskView.disk = side
            messageLabel.text = "'s turn"
        case .none:
            if let winner = self.sideWithMoreDisks() {
                messageDiskSizeConstraint.constant = messageDiskSize
                messageDiskView.disk = winner
                messageLabel.text = " won"
            } else {
                messageDiskSizeConstraint.constant = 0
                messageLabel.text = "Tied"
            }
        }
    }
}

// MARK: Inputs

extension ViewController {
    /// リセットボタンが押された場合に呼ばれるハンドラーです。
    /// アラートを表示して、ゲームを初期化して良いか確認し、
    /// "OK" が選択された場合ゲームを初期化します。
    @IBAction func pressResetButton(_ sender: UIButton) {
        let alertController = UIAlertController(
            title: "Confirmation",
            message: "Do you really want to reset the game?",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            self.animationCanceller?.cancel()
            self.animationCanceller = nil
            
            for side in Disk.sides {
                self.playerCancellers[side]?.cancel()
                self.playerCancellers.removeValue(forKey: side)
            }
            
            self.newGame()
            self.waitForPlayer()
        })
        present(alertController, animated: true)
    }
    
    /// プレイヤーのモードが変更された場合に呼ばれるハンドラーです。
    @IBAction func changePlayerControlSegment(_ sender: UISegmentedControl) {
        let side: Disk = Disk(index: playerControls.firstIndex(of: sender)!)

        // ViewModelのプレイヤーモードを更新
        viewModel.togglePlayerMode(for: side)

        try? saveGame()

        if let canceller = playerCancellers[side] {
            canceller.cancel()
        }

        // コンピュータモードに変更された場合、即座にプレイ
        if !isAnimating, side == viewModel.state.currentTurn, case .computer = Player(rawValue: sender.selectedSegmentIndex)! {
            playTurnOfComputer()
        }
    }
}

extension ViewController: BoardViewDelegate {
    /// `boardView` の `x`, `y` で指定されるセルがタップされたときに呼ばれます。
    /// - Parameter boardView: セルをタップされた `BoardView` インスタンスです。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int) {
        guard let turn = viewModel.state.currentTurn else { return }
        if isAnimating { return }
        guard case .manual = Player(rawValue: playerControls[turn.index].selectedSegmentIndex)! else { return }
        // 配置が無効な場合はcompletionでfalseが返される
        placeDisk(turn, atX: x, y: y, animated: true) { [weak self] _ in
            self?.continueGameFlow()
        }
    }
}

// MARK: Save and Load

extension ViewController {
    /// ゲームの状態をファイルに書き出し、保存します。
    func saveGame() throws {
        // ViewModelの状態をGameRepositoryで保存
        try repository.saveGame(viewModel.state)
    }

    /// ゲームの状態をファイルから読み込み、復元します。
    func loadGame() throws {
        // GameRepositoryから状態を読み込み
        let loadedState = try repository.loadGame()

        // ViewModelの状態を更新
        viewModel.state = loadedState

        // プレイヤーモードUIを同期
        for side in Disk.sides {
            let mode = loadedState.playerMode(for: side)
            playerControls[side.index].selectedSegmentIndex = Player(playerMode: mode).rawValue
        }

        // ViewModelの状態更新により、Combineバインディングで自動的にUIが更新される
    }
}

// MARK: Additional types

extension ViewController {
    enum Player: Int {
        case manual = 0
        case computer = 1

        /// PlayerModeからPlayerへの変換イニシャライザ
        init(playerMode: PlayerMode) {
            switch playerMode {
            case .manual:
                self = .manual
            case .computer:
                self = .computer
            }
        }
    }
}

final class Canceller {
    private(set) var isCancelled: Bool = false
    private let body: (() -> Void)?

    init(_ body: (() -> Void)?) {
        self.body = body
    }

    func cancel() {
        if isCancelled { return }
        isCancelled = true
        body?()
    }
}

// MARK: File-private extensions

extension Disk {
    init(index: Int) {
        for side in Disk.sides {
            if index == side.index {
                self = side
                return
            }
        }
        preconditionFailure("Illegal index: \(index)")
    }
    
    var index: Int {
        switch self {
        case .dark: return 0
        case .light: return 1
        }
    }
}

extension Optional where Wrapped == Disk {
    fileprivate init?<S: StringProtocol>(symbol: S) {
        switch symbol {
        case "x":
            self = .some(.dark)
        case "o":
            self = .some(.light)
        case "-":
            self = .none
        default:
            return nil
        }
    }
    
    fileprivate var symbol: String {
        switch self {
        case .some(.dark):
            return "x"
        case .some(.light):
            return "o"
        case .none:
            return "-"
        }
    }
}
