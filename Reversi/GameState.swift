import Foundation

/// ゲームの状態を表す構造体（immutable）
public struct GameState: Codable {
    /// 盤面
    public var board: Board

    /// 現在のターン（nilの場合はゲーム終了）
    public var currentTurn: Disk?

    /// 各プレイヤーのモード
    public var darkPlayerMode: PlayerMode
    public var lightPlayerMode: PlayerMode

    public init(
        board: Board = .initial(),
        currentTurn: Disk? = .dark,
        darkPlayerMode: PlayerMode = .manual,
        lightPlayerMode: PlayerMode = .manual
    ) {
        self.board = board
        self.currentTurn = currentTurn
        self.darkPlayerMode = darkPlayerMode
        self.lightPlayerMode = lightPlayerMode
    }

    /// 指定されたディスクのプレイヤーモードを取得
    public func playerMode(for disk: Disk) -> PlayerMode {
        switch disk {
        case .dark:
            return darkPlayerMode
        case .light:
            return lightPlayerMode
        }
    }

    /// 指定されたディスクのプレイヤーモードを設定
    public mutating func setPlayerMode(_ mode: PlayerMode, for disk: Disk) {
        switch disk {
        case .dark:
            darkPlayerMode = mode
        case .light:
            lightPlayerMode = mode
        }
    }
}
