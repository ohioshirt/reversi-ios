/// 盤面上の座標を表す型
public struct Position {
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

extension Position: Hashable {}
extension Position: Codable {}
