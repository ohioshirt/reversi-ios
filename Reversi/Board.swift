/// リバーシの盤面を表す構造体
public struct Board {
    public static let width = 8
    public static let height = 8

    private var disks: [[Disk?]]

    public init(disks: [[Disk?]]) {
        precondition(disks.count == Board.height, "盤面の高さは\(Board.height)である必要があります")
        precondition(disks.allSatisfy { $0.count == Board.width }, "盤面の幅は\(Board.width)である必要があります")
        self.disks = disks
    }

    /// 初期配置の盤面を作成
    public static func initial() -> Board {
        var disks = Array(repeating: Array(repeating: Optional<Disk>.none, count: width), count: height)
        // 初期配置: 中央4マス
        disks[3][3] = .light
        disks[3][4] = .dark
        disks[4][3] = .dark
        disks[4][4] = .light
        return Board(disks: disks)
    }

    /// 指定位置のディスクを取得
    public func disk(at position: Position) -> Disk? {
        guard isValid(position: position) else { return nil }
        return disks[position.y][position.x]
    }

    /// 指定位置にディスクを配置
    public mutating func setDisk(_ disk: Disk?, at position: Position) {
        guard isValid(position: position) else { return }
        disks[position.y][position.x] = disk
    }

    /// 座標が盤面内か判定
    public func isValid(position: Position) -> Bool {
        return (0..<Board.width).contains(position.x) && (0..<Board.height).contains(position.y)
    }

    /// すべての座標を列挙
    public static func allPositions() -> [Position] {
        var positions: [Position] = []
        for y in 0..<height {
            for x in 0..<width {
                positions.append(Position(x: x, y: y))
            }
        }
        return positions
    }
}

extension Board: Codable {}
