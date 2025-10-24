import XCTest
@testable import Reversi

/// Board構造体のテスト
/// t-wadaスタイル: Given-When-Then パターンを使用
final class BoardTests: XCTestCase {

    // MARK: - 初期化テスト

    func test_空の盤面で初期化_すべてのマスが空() {
        // Given & When
        let board = Board()

        // Then
        for y in 0..<8 {
            for x in 0..<8 {
                let position = Position(x: x, y: y)
                XCTAssertNil(board.disk(at: position), "(\(x), \(y))は空のマス")
            }
        }
    }

    func test_初期配置で初期化_中央4マスにディスクが配置される() {
        // Given & When
        let board = Board.initial()

        // Then: 初期配置は中央に4つのディスク
        // ○●
        // ●○
        XCTAssertEqual(board.disk(at: Position(x: 3, y: 3)), .light, "(3,3)は白")
        XCTAssertEqual(board.disk(at: Position(x: 4, y: 3)), .dark, "(4,3)は黒")
        XCTAssertEqual(board.disk(at: Position(x: 3, y: 4)), .dark, "(3,4)は黒")
        XCTAssertEqual(board.disk(at: Position(x: 4, y: 4)), .light, "(4,4)は白")

        // その他のマスは空
        XCTAssertNil(board.disk(at: Position(x: 0, y: 0)), "(0,0)は空")
        XCTAssertNil(board.disk(at: Position(x: 7, y: 7)), "(7,7)は空")
    }

    // MARK: - ディスク配置・取得テスト

    func test_空のマスにディスクを配置_正しく配置される() {
        // Given
        var board = Board()
        let position = Position(x: 2, y: 3)

        // When
        board.setDisk(.dark, at: position)

        // Then
        XCTAssertEqual(board.disk(at: position), .dark, "黒ディスクが配置される")
    }

    func test_既存のディスクを上書き_新しいディスクに置き換わる() {
        // Given
        var board = Board()
        let position = Position(x: 2, y: 3)
        board.setDisk(.dark, at: position)

        // When
        board.setDisk(.light, at: position)

        // Then
        XCTAssertEqual(board.disk(at: position), .light, "白ディスクに置き換わる")
    }

    func test_ディスクを削除_nilが設定される() {
        // Given
        var board = Board.initial()
        let position = Position(x: 3, y: 3)

        // When
        board.setDisk(nil, at: position)

        // Then
        XCTAssertNil(board.disk(at: position), "ディスクが削除される")
    }

    // MARK: - サブスクリプトテスト

    func test_サブスクリプトで取得_disk_atと同じ結果() {
        // Given
        let board = Board.initial()
        let position = Position(x: 3, y: 3)

        // When & Then
        XCTAssertEqual(board[position], board.disk(at: position), "サブスクリプトで取得可能")
    }

    func test_サブスクリプトで設定_setDiskと同じ結果() {
        // Given
        var board = Board()
        let position = Position(x: 2, y: 3)

        // When
        board[position] = .dark

        // Then
        XCTAssertEqual(board[position], .dark, "サブスクリプトで設定可能")
    }

    func test_インデックスサブスクリプトで取得_正しい座標のディスクが取得される() {
        // Given
        let board = Board.initial()

        // When & Then
        // index 27 = (3, 3) = 白ディスク
        XCTAssertEqual(board[27], .light, "インデックス27は(3,3)の白ディスク")
    }

    // MARK: - ディスク数カウントテスト

    func test_初期配置_黒と白が2個ずつ() {
        // Given
        let board = Board.initial()

        // When
        let darkCount = board.count(of: .dark)
        let lightCount = board.count(of: .light)

        // Then
        XCTAssertEqual(darkCount, 2, "黒ディスクは2個")
        XCTAssertEqual(lightCount, 2, "白ディスクは2個")
    }

    func test_空の盤面_すべてのディスクが0個() {
        // Given
        let board = Board()

        // When
        let darkCount = board.count(of: .dark)
        let lightCount = board.count(of: .light)

        // Then
        XCTAssertEqual(darkCount, 0, "黒ディスクは0個")
        XCTAssertEqual(lightCount, 0, "白ディスクは0個")
    }

    func test_ディスクを複数配置_正しくカウントされる() {
        // Given
        var board = Board()
        board.setDisk(.dark, at: Position(x: 0, y: 0))
        board.setDisk(.dark, at: Position(x: 1, y: 1))
        board.setDisk(.dark, at: Position(x: 2, y: 2))
        board.setDisk(.light, at: Position(x: 3, y: 3))

        // When
        let darkCount = board.count(of: .dark)
        let lightCount = board.count(of: .light)

        // Then
        XCTAssertEqual(darkCount, 3, "黒ディスクは3個")
        XCTAssertEqual(lightCount, 1, "白ディスクは1個")
    }

    // MARK: - Equatableテスト

    func test_同じ盤面状態_等しいと判定される() {
        // Given
        var board1 = Board()
        board1.setDisk(.dark, at: Position(x: 3, y: 3))

        var board2 = Board()
        board2.setDisk(.dark, at: Position(x: 3, y: 3))

        // When & Then
        XCTAssertEqual(board1, board2, "同じ盤面状態は等しい")
    }

    func test_異なる盤面状態_等しくないと判定される() {
        // Given
        var board1 = Board()
        board1.setDisk(.dark, at: Position(x: 3, y: 3))

        var board2 = Board()
        board2.setDisk(.light, at: Position(x: 3, y: 3))

        // When & Then
        XCTAssertNotEqual(board1, board2, "異なる盤面状態は等しくない")
    }

    // MARK: - エッジケーステスト

    func test_角のマスにディスクを配置_正しく配置される() {
        // Given
        var board = Board()
        let corners = [
            Position(x: 0, y: 0),
            Position(x: 7, y: 0),
            Position(x: 0, y: 7),
            Position(x: 7, y: 7),
        ]

        // When & Then
        for (index, corner) in corners.enumerated() {
            let disk: Disk = index % 2 == 0 ? .dark : .light
            board.setDisk(disk, at: corner)
            XCTAssertEqual(board.disk(at: corner), disk, "角\(corner)にディスクが配置される")
        }
    }
}
