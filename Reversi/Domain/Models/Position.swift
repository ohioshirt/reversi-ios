import Foundation

/// リバーシ盤面上の座標を表す構造体
/// 8x8盤面での位置を(x, y)で表現（0-indexed）
public struct Position: Equatable, Hashable, Codable {
    /// x座標（0-7の範囲、左から右へ）
    public let x: Int

    /// y座標（0-7の範囲、上から下へ）
    public let y: Int

    // MARK: - Initialization

    /// x, y座標を指定して初期化
    /// - Parameters:
    ///   - x: x座標（0-7）
    ///   - y: y座標（0-7）
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    /// インデックスから初期化（0-63を8x8盤面の座標に変換）
    /// - Parameter index: 盤面のインデックス（0-63）
    /// - Note: index = y * 8 + x
    public init(index: Int) {
        self.x = index % 8
        self.y = index / 8
    }

    // MARK: - Validation

    /// 座標が有効な範囲内（0-7）にあるかを判定
    public var isValid: Bool {
        return (0...7).contains(x) && (0...7).contains(y)
    }

    // MARK: - Movement

    /// 指定された方向に移動した新しい座標を返す
    /// - Parameters:
    ///   - dx: x方向の移動量
    ///   - dy: y方向の移動量
    /// - Returns: 移動後の新しいPosition
    public func moved(dx: Int, dy: Int) -> Position {
        return Position(x: x + dx, y: y + dy)
    }
}

// MARK: - CustomStringConvertible

extension Position: CustomStringConvertible {
    public var description: String {
        return "(\(x), \(y))"
    }
}
