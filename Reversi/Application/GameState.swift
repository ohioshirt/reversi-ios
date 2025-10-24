import Foundation

/// ゲームの状態を表すImmutableな構造体
/// すべての状態変更は新しいインスタンスを返す
public struct GameState: Equatable, Codable {
    /// 盤面の状態
    public let board: Board

    /// 現在のターン（nilはゲーム終了）
    public let currentTurn: Disk?

    /// 黒のプレイヤーモード
    public let darkPlayerMode: PlayerMode

    /// 白のプレイヤーモード
    public let lightPlayerMode: PlayerMode

    // MARK: - Initialization

    /// カスタム状態で初期化
    /// - Parameters:
    ///   - board: 盤面
    ///   - currentTurn: 現在のターン
    ///   - darkPlayerMode: 黒のプレイヤーモード
    ///   - lightPlayerMode: 白のプレイヤーモード
    public init(
        board: Board,
        currentTurn: Disk?,
        darkPlayerMode: PlayerMode,
        lightPlayerMode: PlayerMode
    ) {
        self.board = board
        self.currentTurn = currentTurn
        self.darkPlayerMode = darkPlayerMode
        self.lightPlayerMode = lightPlayerMode
    }

    /// リバーシの初期状態を作成
    /// - 盤面: 中央に4つのディスク
    /// - ターン: 黒（先手）
    /// - プレイヤーモード: 両方とも手動
    public static func initial() -> GameState {
        return GameState(
            board: Board.initial(),
            currentTurn: .dark,
            darkPlayerMode: .manual,
            lightPlayerMode: .manual
        )
    }

    // MARK: - Computed Properties

    /// ゲームが終了しているかどうか
    public var isGameOver: Bool {
        return currentTurn == nil
    }

    // MARK: - Immutable Updates

    /// 盤面を更新した新しい状態を返す
    /// - Parameter board: 新しい盤面
    /// - Returns: 更新された状態
    public func settingBoard(_ board: Board) -> GameState {
        return GameState(
            board: board,
            currentTurn: currentTurn,
            darkPlayerMode: darkPlayerMode,
            lightPlayerMode: lightPlayerMode
        )
    }

    /// ターンを更新した新しい状態を返す
    /// - Parameter turn: 新しいターン
    /// - Returns: 更新された状態
    public func settingCurrentTurn(_ turn: Disk?) -> GameState {
        return GameState(
            board: board,
            currentTurn: turn,
            darkPlayerMode: darkPlayerMode,
            lightPlayerMode: lightPlayerMode
        )
    }

    /// 黒のプレイヤーモードを更新した新しい状態を返す
    /// - Parameter mode: 新しいプレイヤーモード
    /// - Returns: 更新された状態
    public func settingDarkPlayerMode(_ mode: PlayerMode) -> GameState {
        return GameState(
            board: board,
            currentTurn: currentTurn,
            darkPlayerMode: mode,
            lightPlayerMode: lightPlayerMode
        )
    }

    /// 白のプレイヤーモードを更新した新しい状態を返す
    /// - Parameter mode: 新しいプレイヤーモード
    /// - Returns: 更新された状態
    public func settingLightPlayerMode(_ mode: PlayerMode) -> GameState {
        return GameState(
            board: board,
            currentTurn: currentTurn,
            darkPlayerMode: darkPlayerMode,
            lightPlayerMode: mode
        )
    }

    // MARK: - Player Mode Access

    /// 指定されたプレイヤーのモードを取得
    /// - Parameter side: プレイヤーの色
    /// - Returns: プレイヤーモード
    public func playerMode(for side: Disk) -> PlayerMode {
        switch side {
        case .dark:
            return darkPlayerMode
        case .light:
            return lightPlayerMode
        }
    }

    /// 指定されたプレイヤーのモードを更新した新しい状態を返す
    /// - Parameters:
    ///   - mode: 新しいプレイヤーモード
    ///   - side: プレイヤーの色
    /// - Returns: 更新された状態
    public func settingPlayerMode(_ mode: PlayerMode, for side: Disk) -> GameState {
        switch side {
        case .dark:
            return settingDarkPlayerMode(mode)
        case .light:
            return settingLightPlayerMode(mode)
        }
    }
}
