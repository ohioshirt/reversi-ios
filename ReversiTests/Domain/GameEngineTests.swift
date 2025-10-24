import XCTest
@testable import Reversi

/// GameEngine のテスト
/// t-wadaスタイル: Given-When-Then パターン、AAA パターンを使用
final class GameEngineTests: XCTestCase {
    var engine: GameEngine!

    override func setUp() {
        super.setUp()
        engine = GameEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - validMoves テスト

    func test_初期盤面_黒の有効な手が4つ() {
        // Given: リバーシの初期配置
        // ○●
        // ●○
        let board = Board.initial()

        // When: 黒（先手）の有効な手を取得
        let validMoves = engine.validMoves(for: .dark, in: board)

        // Then: 初期配置では黒は4箇所に置ける
        XCTAssertEqual(validMoves.count, 4, "黒の有効な手は4つ")
        XCTAssertTrue(validMoves.contains(Position(x: 2, y: 3)), "(2,3)は有効")
        XCTAssertTrue(validMoves.contains(Position(x: 3, y: 2)), "(3,2)は有効")
        XCTAssertTrue(validMoves.contains(Position(x: 4, y: 5)), "(4,5)は有効")
        XCTAssertTrue(validMoves.contains(Position(x: 5, y: 4)), "(5,4)は有効")
    }

    func test_初期盤面_白の有効な手が4つ() {
        // Given: リバーシの初期配置
        let board = Board.initial()

        // When: 白の有効な手を取得
        let validMoves = engine.validMoves(for: .light, in: board)

        // Then: 初期配置では白は4箇所に置ける
        XCTAssertEqual(validMoves.count, 4, "白の有効な手は4つ")
        XCTAssertTrue(validMoves.contains(Position(x: 2, y: 4)), "(2,4)は有効")
        XCTAssertTrue(validMoves.contains(Position(x: 3, y: 5)), "(3,5)は有効")
        XCTAssertTrue(validMoves.contains(Position(x: 4, y: 2)), "(4,2)は有効")
        XCTAssertTrue(validMoves.contains(Position(x: 5, y: 3)), "(5,3)は有効")
    }

    func test_空の盤面_有効な手がゼロ() {
        // Given: 空の盤面
        let board = Board()

        // When: 有効な手を取得
        let validMoves = engine.validMoves(for: .dark, in: board)

        // Then: ディスクがないので有効な手はゼロ
        XCTAssertEqual(validMoves.count, 0, "空盤面では有効な手はない")
    }

    func test_特定の盤面_角に置ける() {
        // Given: 角の隣に相手のディスクがある盤面
        let board = BoardBuilder()
            .place(.light, at: (1, 0))
            .place(.dark, at: (2, 0))
            .build()

        // When: 黒の有効な手を取得
        let validMoves = engine.validMoves(for: .dark, in: board)

        // Then: 角(0,0)に置ける
        XCTAssertTrue(validMoves.contains(Position(x: 0, y: 0)), "角(0,0)は有効")
    }

    func test_全方向に挟める盤面_8方向すべてが検出される() {
        // Given: 中心に黒を置き、その周りを白で囲む
        let board = BoardBuilder()
            .place(.dark, at: (3, 3))
            .place(.light, at: (2, 3)) // 左
            .place(.light, at: (4, 3)) // 右
            .place(.light, at: (3, 2)) // 上
            .place(.light, at: (3, 4)) // 下
            .place(.light, at: (2, 2)) // 左上
            .place(.light, at: (4, 2)) // 右上
            .place(.light, at: (2, 4)) // 左下
            .place(.light, at: (4, 4)) // 右下
            .build()

        // When: 黒の有効な手を取得
        let validMoves = engine.validMoves(for: .dark, in: board)

        // Then: 8方向すべてに置ける
        XCTAssertEqual(validMoves.count, 8, "8方向すべてに置ける")
        XCTAssertTrue(validMoves.contains(Position(x: 1, y: 3)), "左に置ける")
        XCTAssertTrue(validMoves.contains(Position(x: 5, y: 3)), "右に置ける")
        XCTAssertTrue(validMoves.contains(Position(x: 3, y: 1)), "上に置ける")
        XCTAssertTrue(validMoves.contains(Position(x: 3, y: 5)), "下に置ける")
        XCTAssertTrue(validMoves.contains(Position(x: 1, y: 1)), "左上に置ける")
        XCTAssertTrue(validMoves.contains(Position(x: 5, y: 1)), "右上に置ける")
        XCTAssertTrue(validMoves.contains(Position(x: 1, y: 5)), "左下に置ける")
        XCTAssertTrue(validMoves.contains(Position(x: 5, y: 5)), "右下に置ける")
    }

    func test_盤面の端_範囲外はチェックしない() {
        // Given: 端にディスクがある盤面
        let board = BoardBuilder()
            .place(.dark, at: (0, 0))
            .place(.light, at: (1, 0))
            .build()

        // When: 黒の有効な手を取得
        let validMoves = engine.validMoves(for: .dark, in: board)

        // Then: 範囲外に出る手は含まれない（エラーにならない）
        XCTAssertNotNil(validMoves, "範囲外チェックでエラーにならない")
    }

    func test_有効な手がない場合_空配列を返す() {
        // Given: 自分のディスクしかない盤面（相手のディスクを挟めない）
        let board = BoardBuilder()
            .place(.dark, at: (3, 3))
            .place(.dark, at: (3, 4))
            .build()

        // When: 黒の有効な手を取得
        let validMoves = engine.validMoves(for: .dark, in: board)

        // Then: 有効な手はゼロ
        XCTAssertEqual(validMoves.count, 0, "挟めないので有効な手はない")
    }
}
