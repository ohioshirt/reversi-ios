import Foundation
import Combine

/// ゲーム全体のViewModelクラス
/// Combineを使用してリアクティブな状態管理を提供
@MainActor
public final class GameViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 現在のゲーム状態（リアクティブ）
    @Published public var state: GameState

    /// アニメーション実行中フラグ
    @Published public var isAnimating: Bool = false

    // MARK: - Dependencies

    /// ゲームエンジン
    public let engine: GameEngine

    // MARK: - Initialization

    /// 初期化
    /// - Parameter engine: ゲームエンジン
    public init(engine: GameEngine) {
        self.engine = engine
        self.state = GameState.initial()
    }

    // MARK: - Game Control

    /// 新しいゲームを開始
    public func newGame() {
        state = GameState.initial()
        isAnimating = false
    }

    /// 指定された位置にディスクを配置
    /// - Parameter position: 配置する位置
    /// - Returns: 配置に成功した場合はtrue
    public func placeDisk(at position: Position) async -> Bool {
        // 現在のターンを取得
        guard let currentTurn = state.currentTurn else {
            return false
        }

        // 配置可能かチェック
        guard engine.canPlaceDisk(at: position, for: currentTurn, in: state.board) else {
            return false
        }

        // アニメーション開始
        isAnimating = true

        // ディスクを配置
        var newBoard = state.board
        let flipped = engine.placeDisk(at: position, for: currentTurn, on: &newBoard)

        // 盤面を更新
        state = state.settingBoard(newBoard)

        // 次のターンに移行
        let nextTurn = currentTurn.flipped

        // 次のプレイヤーの有効な手をチェック
        let nextValidMoves = engine.validMoves(for: nextTurn, in: newBoard)

        if nextValidMoves.isEmpty {
            // 次のプレイヤーが打てない場合、現在のプレイヤーの有効な手をチェック
            let currentValidMoves = engine.validMoves(for: currentTurn, in: newBoard)

            if currentValidMoves.isEmpty {
                // 両者とも打てない場合、ゲーム終了
                state = state.settingCurrentTurn(nil)
            } else {
                // 現在のプレイヤーが続行（パス）
                // ターンはそのまま
            }
        } else {
            // 次のターンに移行
            state = state.settingCurrentTurn(nextTurn)
        }

        // アニメーション終了
        isAnimating = false

        return true
    }

    /// プレイヤーモードを切り替える
    /// - Parameter side: プレイヤーの色
    public func togglePlayerMode(for side: Disk) {
        let currentMode = state.playerMode(for: side)
        let newMode: PlayerMode = currentMode == .manual ? .computer : .manual
        state = state.settingPlayerMode(newMode, for: side)
    }

    /// 現在のプレイヤーの有効な手を取得
    /// - Returns: 有効な手の配列
    public func validMovesForCurrentPlayer() -> [Position] {
        guard let currentTurn = state.currentTurn else {
            return []
        }
        return engine.validMoves(for: currentTurn, in: state.board)
    }

    /// 指定されたプレイヤーの有効な手を取得
    /// - Parameter side: プレイヤーの色
    /// - Returns: 有効な手の配列
    public func validMoves(for side: Disk) -> [Position] {
        return engine.validMoves(for: side, in: state.board)
    }

    /// ディスク数を取得
    /// - Parameter side: プレイヤーの色
    /// - Returns: ディスク数
    public func diskCount(for side: Disk) -> Int {
        return state.board.count(of: side)
    }

    /// 勝者を取得
    /// - Returns: 勝者（引き分けの場合はnil）
    public func winner() -> Disk? {
        return engine.winner(in: state.board)
    }
}
