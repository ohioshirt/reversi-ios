import Foundation

/// リバーシの8x8盤面を表す構造体
/// 各マスには、黒ディスク、白ディスク、または空のいずれかが入る
public struct Board: Equatable, Codable {
    /// 盤面の幅
    public static let width = 8

    /// 盤面の高さ
    public static let height = 8

    /// 盤面のディスク配置（Position -> Disk のマッピング）
    private var disks: [Position: Disk]

    // MARK: - Initialization

    /// 空の盤面を作成
    public init() {
        self.disks = [:]
    }

    /// リバーシの初期配置を作成
    /// 中央に4つのディスクを配置:
    /// ```
    /// ○●
    /// ●○
    /// ```
    public static func initial() -> Board {
        var board = Board()
        board.setDisk(.light, at: Position(x: 3, y: 3))
        board.setDisk(.dark, at: Position(x: 4, y: 3))
        board.setDisk(.dark, at: Position(x: 3, y: 4))
        board.setDisk(.light, at: Position(x: 4, y: 4))
        return board
    }

    // MARK: - Disk Access

    /// 指定された位置のディスクを取得
    /// - Parameter position: 取得する位置
    /// - Returns: ディスク（存在しない場合はnil）
    public func disk(at position: Position) -> Disk? {
        return disks[position]
    }

    /// 指定された位置にディスクを設置
    /// - Parameters:
    ///   - disk: 設置するディスク（nilで削除）
    ///   - position: 設置する位置
    public mutating func setDisk(_ disk: Disk?, at position: Position) {
        disks[position] = disk
    }

    // MARK: - Subscript

    /// Position を使った subscript アクセス
    public subscript(position: Position) -> Disk? {
        get { disk(at: position) }
        set { setDisk(newValue, at: position) }
    }

    /// インデックスを使った subscript アクセス（0-63）
    public subscript(index: Int) -> Disk? {
        get { disk(at: Position(index: index)) }
        set { setDisk(newValue, at: Position(index: index)) }
    }

    // MARK: - Disk Counting

    /// 指定された色のディスクの数を数える
    /// - Parameter side: カウントするディスクの色
    /// - Returns: ディスクの個数
    public func count(of side: Disk) -> Int {
        return disks.values.filter { $0 == side }.count
    }
}
