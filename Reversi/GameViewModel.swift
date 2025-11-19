import Foundation
import Combine

/// パスイベントを表す構造体
public struct PassEvent {
    public let passedPlayer: Disk
    public let timestamp: Date

    public init(passedPlayer: Disk, timestamp: Date = Date()) {
        self.passedPlayer = passedPlayer
        self.timestamp = timestamp
    }
}

/// ゲームのViewModel（Application層）
public class GameViewModel: ObservableObject {
    /// ゲームエンジン
    private let engine: GameEngine

    /// ゲームの状態
    @Published public var state: GameState

    /// パスイベント（nilでない場合はパスが発生したことを示す）
    @Published public var passEvent: PassEvent?

    public init(engine: GameEngine, initialState: GameState = GameState()) {
        self.engine = engine
        self.state = initialState
        self.passEvent = nil
    }

    /// 指定されたディスクの枚数を返す
    public func diskCount(for disk: Disk) -> Int {
        return engine.diskCount(for: disk, in: state.board)
    }

    /// 勝者を判定
    public func winner() -> Disk? {
        return engine.winner(in: state.board)
    }

    /// 有効な手を取得
    public func validMoves(for disk: Disk) -> [Position] {
        return engine.validMoves(for: disk, in: state.board)
    }

    /// ディスクを配置
    /// - Parameter position: 配置する座標
    /// - Returns: 配置に成功したかどうか
    @MainActor
    public func placeDisk(at position: Position) async -> Bool {
        guard let currentDisk = state.currentTurn else { return false }

        // ディスクを配置
        let flipped = engine.placeDisk(at: position, for: currentDisk, on: &state.board)
        guard !flipped.isEmpty else { return false }

        // 次のターンを決定
        advanceTurn()

        return true
    }

    /// ターンを進める
    @MainActor
    private func advanceTurn() {
        guard let current = state.currentTurn else { return }

        let next = current.flipped

        // 次のプレイヤーに有効な手があるか確認
        if !validMoves(for: next).isEmpty {
            state.currentTurn = next
            return
        }

        // 次のプレイヤーがパスの場合
        passEvent = PassEvent(passedPlayer: next)

        // 現在のプレイヤーに有効な手があるか確認
        if !validMoves(for: current).isEmpty {
            // 現在のプレイヤーのターンを継続（次のプレイヤーはパス）
            state.currentTurn = current
            return
        }

        // 両プレイヤーとも有効な手がない場合、ゲーム終了
        state.currentTurn = nil
    }

    /// ゲームをリセット
    @MainActor
    public func newGame() {
        state = GameState(
            darkPlayerMode: state.darkPlayerMode,
            lightPlayerMode: state.lightPlayerMode
        )
        passEvent = nil
    }

    /// パスイベントをクリア
    @MainActor
    public func clearPassEvent() {
        passEvent = nil
    }

    /// プレイヤーモードを切り替え
    public func togglePlayerMode(for disk: Disk) {
        let currentMode = state.playerMode(for: disk)
        let newMode: PlayerMode = currentMode == .manual ? .computer : .manual
        state.setPlayerMode(newMode, for: disk)
    }
}
