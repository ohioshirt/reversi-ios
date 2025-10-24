import Foundation

/// リバーシのゲームエンジン
/// ゲームのコアロジック（ビジネスルール）を担当
/// UIに依存しない純粋なSwiftコード
public final class GameEngine {

    /// 8方向のベクトル（dx, dy）
    /// 上下左右と斜め4方向
    private static let directions: [(dx: Int, dy: Int)] = [
        (-1, -1), (0, -1), (1, -1), // 左上、上、右上
        (-1,  0),          (1,  0), // 左、右
        (-1,  1), (0,  1), (1,  1), // 左下、下、右下
    ]

    public init() {}

    // MARK: - Valid Moves

    /// 指定されたプレイヤーの有効な手をすべて取得
    /// - Parameters:
    ///   - side: プレイヤーの色
    ///   - board: 現在の盤面
    /// - Returns: 有効な手の位置の配列
    public func validMoves(for side: Disk, in board: Board) -> [Position] {
        var moves: [Position] = []

        // すべてのマスをチェック
        for y in 0..<Board.height {
            for x in 0..<Board.width {
                let position = Position(x: x, y: y)
                if canPlaceDisk(at: position, for: side, in: board) {
                    moves.append(position)
                }
            }
        }

        return moves
    }

    /// 指定された位置にディスクを置けるかどうかを判定
    /// - Parameters:
    ///   - position: 置く位置
    ///   - side: プレイヤーの色
    ///   - board: 現在の盤面
    /// - Returns: 置ける場合はtrue
    public func canPlaceDisk(at position: Position, for side: Disk, in board: Board) -> Bool {
        // 位置が有効範囲外
        guard position.isValid else {
            return false
        }

        // すでにディスクがある
        guard board.disk(at: position) == nil else {
            return false
        }

        // 8方向のいずれかで相手のディスクを挟めるか
        for direction in Self.directions {
            if canFlip(from: position, direction: direction, for: side, in: board) {
                return true
            }
        }

        return false
    }

    // MARK: - Place Disk

    /// 指定された位置にディスクを配置し、反転されるディスクの位置を返す
    /// - Parameters:
    ///   - position: 配置する位置
    ///   - side: プレイヤーの色
    ///   - board: 盤面（inout: 実際に変更される）
    /// - Returns: 反転されたディスクの位置の配列
    @discardableResult
    public func placeDisk(at position: Position, for side: Disk, on board: inout Board) -> [Position] {
        // 配置できない場合は空配列を返す
        guard canPlaceDisk(at: position, for: side, in: board) else {
            return []
        }

        var flipped: [Position] = []

        // 8方向それぞれで反転するディスクを収集
        for direction in Self.directions {
            let flippedInDirection = disksToFlip(from: position, direction: direction, for: side, in: board)
            flipped.append(contentsOf: flippedInDirection)
        }

        // ディスクを配置
        board.setDisk(side, at: position)

        // 反転を実行
        for pos in flipped {
            board.setDisk(side, at: pos)
        }

        return flipped
    }

    // MARK: - Private Helpers

    /// 指定された方向に相手のディスクを挟めるかチェック
    /// - Parameters:
    ///   - position: 開始位置
    ///   - direction: 方向ベクトル
    ///   - side: プレイヤーの色
    ///   - board: 盤面
    /// - Returns: 挟める場合はtrue
    private func canFlip(from position: Position, direction: (dx: Int, dy: Int), for side: Disk, in board: Board) -> Bool {
        let opponent = side.flipped
        var current = position.moved(dx: direction.dx, dy: direction.dy)
        var hasOpponentBetween = false

        // 方向に沿って探索
        while current.isValid {
            guard let disk = board.disk(at: current) else {
                // 空マスに到達 → 挟めない
                return false
            }

            if disk == opponent {
                // 相手のディスク → 探索を続ける
                hasOpponentBetween = true
                current = current.moved(dx: direction.dx, dy: direction.dy)
            } else {
                // 自分のディスク → 間に相手のディスクがあれば挟める
                return hasOpponentBetween
            }
        }

        // 盤面の端に到達 → 挟めない
        return false
    }

    /// 指定された方向で反転されるディスクの位置を返す
    /// - Parameters:
    ///   - position: 開始位置
    ///   - direction: 方向ベクトル
    ///   - side: プレイヤーの色
    ///   - board: 盤面
    /// - Returns: 反転されるディスクの位置の配列
    private func disksToFlip(from position: Position, direction: (dx: Int, dy: Int), for side: Disk, in board: Board) -> [Position] {
        guard canFlip(from: position, direction: direction, for: side, in: board) else {
            return []
        }

        let opponent = side.flipped
        var flipped: [Position] = []
        var current = position.moved(dx: direction.dx, dy: direction.dy)

        // 相手のディスクを収集
        while current.isValid {
            guard let disk = board.disk(at: current) else {
                break
            }

            if disk == opponent {
                flipped.append(current)
                current = current.moved(dx: direction.dx, dy: direction.dy)
            } else {
                // 自分のディスクに到達
                break
            }
        }

        return flipped
    }
}
