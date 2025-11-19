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
///
/// ViewModelはUI関連の状態を管理するため、MainActorで実行されます。
/// これにより、すべての状態変更とイベント発行がメインスレッドで安全に実行されることが保証されます。
@MainActor
public class GameViewModel: ObservableObject {
    /// ゲームエンジン
    private let engine: GameEngine

    /// ゲームの状態
    @Published public var state: GameState

    /// パスイベントを発行するSubject
    ///
    /// ライフサイクル:
    /// - 発行: advanceTurn()内で次のプレイヤーがパスする場合にsend()で発行
    /// - 購読: ViewControllerがsink経由で検知し、パスアラートを表示
    ///
    /// 注:
    /// - PassthroughSubjectはイベントを永続化せず、発行時のみ通知します。手動でのクリア処理は不要です。
    /// - クラス全体がMainActorで実行されるため、イベントは常にメインスレッドで発行・購読されます。
    public let passEvent = PassthroughSubject<PassEvent, Never>()

    public init(engine: GameEngine, initialState: GameState = GameState()) {
        self.engine = engine
        self.state = initialState
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
    private func advanceTurn() {
        guard let current = state.currentTurn else { return }

        let next = current.flipped

        // 次のプレイヤーに有効な手があるか確認
        if !validMoves(for: next).isEmpty {
            state.currentTurn = next
            return
        }

        // 次のプレイヤーがパスの場合
        passEvent.send(PassEvent(passedPlayer: next))

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
    public func newGame() {
        state = GameState(
            darkPlayerMode: state.darkPlayerMode,
            lightPlayerMode: state.lightPlayerMode
        )
    }

    /// プレイヤーモードを切り替え
    public func togglePlayerMode(for disk: Disk) {
        let currentMode = state.playerMode(for: disk)
        let newMode: PlayerMode = currentMode == .manual ? .computer : .manual
        state.setPlayerMode(newMode, for: disk)
    }
}
