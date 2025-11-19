/// リバーシのゲームロジックを提供するエンジン
public struct GameEngine {
    public init() {}

    /// 8方向の定義
    private static let directions: [(x: Int, y: Int)] = [
        (x: -1, y: -1), (x:  0, y: -1), (x:  1, y: -1), (x:  1, y:  0),
        (x:  1, y:  1), (x:  0, y:  1), (x: -1, y:  1), (x: -1, y:  0),
    ]

    /// 指定位置にディスクを配置し、反転するディスクの座標を返す
    ///
    /// - Parameters:
    ///   - position: 配置する座標
    ///   - disk: 配置するディスク
    ///   - board: 盤面（inoutで更新される）
    /// - Returns: 反転されたディスクの座標配列
    ///
    /// 失敗時の挙動:
    /// - 既にディスクがある位置の場合: 空配列を返す（盤面は変更されない）
    /// - 反転するディスクがない場合（無効な手）: 空配列を返す（盤面は変更されない）
    ///
    /// 注: 空配列が返された場合、配置は失敗しています。呼び出し側は、事前に
    /// `canPlaceDisk(at:for:in:)`で配置可能かを確認するか、または
    /// `flippedDiskPositions(at:for:in:)`で反転座標を取得してから呼び出すことを推奨します。
    @discardableResult
    public func placeDisk(at position: Position, for disk: Disk, on board: inout Board) -> [Position] {
        guard board.disk(at: position) == nil else { return [] }

        let flippedPositions = flippedDiskPositions(at: position, for: disk, in: board)
        guard !flippedPositions.isEmpty else { return [] }

        // ディスクを配置
        board.setDisk(disk, at: position)

        // ディスクを反転
        for flippedPosition in flippedPositions {
            board.setDisk(disk, at: flippedPosition)
        }

        return flippedPositions
    }

    /// 指定位置にディスクを配置した場合に反転されるディスクの座標を返す（盤面は変更しない）
    /// - Parameters:
    ///   - position: 配置する座標
    ///   - disk: 配置するディスク
    ///   - board: 盤面
    /// - Returns: 反転されるディスクの座標配列
    public func flippedDiskPositions(at position: Position, for disk: Disk, in board: Board) -> [Position] {
        guard board.disk(at: position) == nil else { return [] }

        var allFlipped: [Position] = []

        for direction in Self.directions {
            var currentPos = position
            var flippedInLine: [Position] = []

            directionLoop: while true {
                currentPos = Position(
                    x: currentPos.x + direction.x,
                    y: currentPos.y + direction.y
                )

                guard board.isValid(position: currentPos) else { break directionLoop }

                switch board.disk(at: currentPos) {
                case .some(let d) where d == disk:
                    // 自分の色に到達 → この方向のディスクを反転対象に追加
                    allFlipped.append(contentsOf: flippedInLine)
                    break directionLoop
                case .some(let d) where d == disk.flipped:
                    // 相手の色 → 反転候補に追加して継続
                    flippedInLine.append(currentPos)
                default:
                    // 空マスまたは盤外 → この方向は無効
                    break directionLoop
                }
            }
        }

        return allFlipped
    }

    /// 指定位置にディスクを配置できるか判定
    /// - Parameters:
    ///   - position: 配置する座標
    ///   - disk: 配置するディスク
    ///   - board: 盤面
    /// - Returns: 配置可能ならtrue
    public func canPlaceDisk(at position: Position, for disk: Disk, in board: Board) -> Bool {
        return !flippedDiskPositions(at: position, for: disk, in: board).isEmpty
    }

    /// 指定されたディスクが配置可能なすべての座標を返す
    /// - Parameters:
    ///   - disk: 配置するディスク
    ///   - board: 盤面
    /// - Returns: 配置可能な座標の配列
    public func validMoves(for disk: Disk, in board: Board) -> [Position] {
        return Board.allPositions.filter { position in
            canPlaceDisk(at: position, for: disk, in: board)
        }
    }

    /// ゲームの勝者を判定
    /// - Parameter board: 盤面
    /// - Returns: 勝者のディスク。引き分けの場合はnil
    public func winner(in board: Board) -> Disk? {
        let darkCount = diskCount(for: .dark, in: board)
        let lightCount = diskCount(for: .light, in: board)

        if darkCount == lightCount {
            return nil
        }
        return darkCount > lightCount ? .dark : .light
    }

    /// 指定されたディスクの枚数を数える
    /// - Parameters:
    ///   - disk: 数えるディスク
    ///   - board: 盤面
    /// - Returns: ディスクの枚数
    public func diskCount(for disk: Disk, in board: Board) -> Int {
        return Board.allPositions.filter { position in
            board.disk(at: position) == disk
        }.count
    }
}
