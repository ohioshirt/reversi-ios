import Foundation
@testable import Reversi

/// テスト用のBoardビルダー
/// t-wadaスタイル: テストデータビルダーパターン
///
/// 使用例:
/// ```swift
/// let board = BoardBuilder()
///     .withInitialSetup()
///     .place(.dark, at: (2, 3))
///     .place(.light, at: (2, 4))
///     .build()
/// ```
final class BoardBuilder {
    private var disks: [Position: Disk] = [:]

    /// 指定された位置にディスクを配置
    /// - Parameters:
    ///   - disk: 配置するディスク
    ///   - position: 配置する位置（x, y のタプル）
    /// - Returns: self（メソッドチェーン用）
    @discardableResult
    func place(_ disk: Disk, at position: (Int, Int)) -> BoardBuilder {
        disks[Position(x: position.0, y: position.1)] = disk
        return self
    }

    /// リバーシの初期配置を設定
    /// 中央に4つのディスクを配置:
    /// ```
    /// ○●
    /// ●○
    /// ```
    /// - Returns: self（メソッドチェーン用）
    @discardableResult
    func withInitialSetup() -> BoardBuilder {
        return self
            .place(.light, at: (3, 3))
            .place(.dark, at: (4, 3))
            .place(.dark, at: (3, 4))
            .place(.light, at: (4, 4))
    }

    /// 1列にディスクを配置（テスト用）
    /// - Parameters:
    ///   - disk: 配置するディスク
    ///   - row: 行番号（y座標）
    ///   - columns: 列番号の配列（x座標）
    /// - Returns: self（メソッドチェーン用）
    @discardableResult
    func placeRow(_ disk: Disk, row: Int, columns: [Int]) -> BoardBuilder {
        for column in columns {
            place(disk, at: (column, row))
        }
        return self
    }

    /// 1列にディスクを配置（テスト用）
    /// - Parameters:
    ///   - disk: 配置するディスク
    ///   - column: 列番号（x座標）
    ///   - rows: 行番号の配列（y座標）
    /// - Returns: self（メソッドチェーン用）
    @discardableResult
    func placeColumn(_ disk: Disk, column: Int, rows: [Int]) -> BoardBuilder {
        for row in rows {
            place(disk, at: (column, row))
        }
        return self
    }

    /// 対角線にディスクを配置（テスト用）
    /// - Parameters:
    ///   - disk: 配置するディスク
    ///   - start: 開始位置
    ///   - count: ディスクの個数
    ///   - direction: 方向（1, 1）で右下、（1, -1）で右上など
    /// - Returns: self（メソッドチェーン用）
    @discardableResult
    func placeDiagonal(_ disk: Disk, start: (Int, Int), count: Int, direction: (Int, Int)) -> BoardBuilder {
        for i in 0..<count {
            place(disk, at: (start.0 + i * direction.0, start.1 + i * direction.1))
        }
        return self
    }

    /// Boardを構築
    /// - Returns: 構築されたBoard
    func build() -> Board {
        var board = Board()
        for (position, disk) in disks {
            board.setDisk(disk, at: position)
        }
        return board
    }
}
