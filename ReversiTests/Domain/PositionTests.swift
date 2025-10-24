import XCTest
@testable import Reversi

/// Position構造体のテスト
/// t-wadaスタイル: AAA (Arrange-Act-Assert) パターンを使用
final class PositionTests: XCTestCase {

    // MARK: - 初期化テスト

    func test_座標を指定して初期化_x座標とy座標が正しく設定される() {
        // Arrange & Act
        let position = Position(x: 3, y: 4)

        // Assert
        XCTAssertEqual(position.x, 3, "x座標が正しく設定される")
        XCTAssertEqual(position.y, 4, "y座標が正しく設定される")
    }

    func test_インデックスを指定して初期化_8x8盤面の座標に変換される() {
        // Arrange & Act
        let position = Position(index: 0)

        // Assert
        XCTAssertEqual(position.x, 0, "インデックス0はx=0")
        XCTAssertEqual(position.y, 0, "インデックス0はy=0")
    }

    func test_インデックス変換_中央の座標が正しく計算される() {
        // Arrange & Act
        let position = Position(index: 27) // 3行目の4列目 (y=3, x=3)

        // Assert
        XCTAssertEqual(position.x, 3, "インデックス27はx=3")
        XCTAssertEqual(position.y, 3, "インデックス27はy=3")
    }

    func test_インデックス変換_最後の座標が正しく計算される() {
        // Arrange & Act
        let position = Position(index: 63) // 8x8の最後

        // Assert
        XCTAssertEqual(position.x, 7, "インデックス63はx=7")
        XCTAssertEqual(position.y, 7, "インデックス63はy=7")
    }

    // MARK: - Equatableテスト

    func test_同じ座標のPosition_等しいと判定される() {
        // Arrange
        let position1 = Position(x: 2, y: 3)
        let position2 = Position(x: 2, y: 3)

        // Act & Assert
        XCTAssertEqual(position1, position2, "同じ座標は等しい")
    }

    func test_異なる座標のPosition_等しくないと判定される() {
        // Arrange
        let position1 = Position(x: 2, y: 3)
        let position2 = Position(x: 3, y: 2)

        // Act & Assert
        XCTAssertNotEqual(position1, position2, "異なる座標は等しくない")
    }

    // MARK: - Hashableテスト

    func test_Positionをセットに格納_重複が除去される() {
        // Arrange
        let position1 = Position(x: 2, y: 3)
        let position2 = Position(x: 2, y: 3)
        let position3 = Position(x: 3, y: 2)

        // Act
        let set: Set<Position> = [position1, position2, position3]

        // Assert
        XCTAssertEqual(set.count, 2, "重複する座標は1つにまとめられる")
    }

    // MARK: - バリデーションテスト

    func test_有効な座標範囲_isValidがtrueを返す() {
        // Arrange
        let validPositions = [
            Position(x: 0, y: 0),
            Position(x: 7, y: 7),
            Position(x: 3, y: 4),
        ]

        // Act & Assert
        for position in validPositions {
            XCTAssertTrue(position.isValid, "\(position)は有効な座標")
        }
    }

    func test_無効な座標範囲_isValidがfalseを返す() {
        // Arrange
        let invalidPositions = [
            Position(x: -1, y: 0),
            Position(x: 0, y: -1),
            Position(x: 8, y: 0),
            Position(x: 0, y: 8),
            Position(x: -1, y: -1),
            Position(x: 8, y: 8),
        ]

        // Act & Assert
        for position in invalidPositions {
            XCTAssertFalse(position.isValid, "\(position)は無効な座標")
        }
    }

    // MARK: - 方向計算テスト

    func test_上方向に移動_y座標が減少する() {
        // Arrange
        let position = Position(x: 3, y: 3)

        // Act
        let moved = position.moved(dx: 0, dy: -1)

        // Assert
        XCTAssertEqual(moved.x, 3, "x座標は変わらない")
        XCTAssertEqual(moved.y, 2, "y座標が1減る")
    }

    func test_右下方向に移動_x座標とy座標が増加する() {
        // Arrange
        let position = Position(x: 3, y: 3)

        // Act
        let moved = position.moved(dx: 1, dy: 1)

        // Assert
        XCTAssertEqual(moved.x, 4, "x座標が1増える")
        XCTAssertEqual(moved.y, 4, "y座標が1増える")
    }
}
