import Foundation

/// プレイヤーの手選択戦略を定義するプロトコル
/// ManualStrategy（手動）とComputerStrategy（AI）を統一的に扱う
public protocol PlayerStrategy {
    /// 次の手を選択する
    /// - Parameters:
    ///   - board: 現在の盤面
    ///   - side: プレイヤーの色
    ///   - validMoves: 有効な手のリスト
    /// - Returns: 選択した手（パスの場合はnil）
    func selectMove(
        in board: Board,
        for side: Disk,
        validMoves: [Position]
    ) async -> Position?
}

/// コンピュータプレイヤーの戦略
/// 現在の実装：有効な手からランダムに選択
public final class ComputerStrategy: PlayerStrategy {

    public init() {}

    public func selectMove(
        in board: Board,
        for side: Disk,
        validMoves: [Position]
    ) async -> Position? {
        // 有効な手がない場合はnil
        guard !validMoves.isEmpty else {
            return nil
        }

        // 思考時間をシミュレート（2秒待機）
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // ランダムに手を選択
        return validMoves.randomElement()
    }
}
