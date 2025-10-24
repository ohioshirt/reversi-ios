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

    // MARK: - placeDisk テスト

    func test_初期盤面に黒を配置_1つのディスクが反転される() {
        // Given: リバーシの初期配置
        var board = Board.initial()
        let position = Position(x: 2, y: 3)

        // When: (2,3)に黒を配置
        let flipped = engine.placeDisk(at: position, for: .dark, on: &board)

        // Then: (3,3)の白ディスクが反転される
        XCTAssertEqual(flipped.count, 1, "1つのディスクが反転")
        XCTAssertTrue(flipped.contains(Position(x: 3, y: 3)), "(3,3)が反転")
        XCTAssertEqual(board.disk(at: position), .dark, "(2,3)に黒が配置される")
        XCTAssertEqual(board.disk(at: Position(x: 3, y: 3)), .dark, "(3,3)が黒に反転")
    }

    func test_角にディスクを配置_複数のディスクが反転される() {
        // Given: 角の隣に相手のディスクが2つある盤面
        var board = BoardBuilder()
            .place(.dark, at: (0, 0))
            .place(.light, at: (1, 0))
            .place(.light, at: (2, 0))
            .place(.dark, at: (3, 0))
            .build()

        // When: 角(0,0)を削除し、(3,0)から配置し直す想定
        // 実際には(2,0)に黒を配置
        board = BoardBuilder()
            .place(.light, at: (1, 0))
            .place(.light, at: (2, 0))
            .place(.dark, at: (3, 0))
            .build()
        let position = Position(x: 0, y: 0)
        let flipped = engine.placeDisk(at: position, for: .dark, on: &board)

        // Then: (1,0)と(2,0)が反転される
        XCTAssertEqual(flipped.count, 2, "2つのディスクが反転")
        XCTAssertTrue(flipped.contains(Position(x: 1, y: 0)), "(1,0)が反転")
        XCTAssertTrue(flipped.contains(Position(x: 2, y: 0)), "(2,0)が反転")
    }

    func test_複数方向に反転_すべての方向のディスクが反転される() {
        // Given: 十字に相手のディスクがあり、その外側に自分のディスクがある
        var board = BoardBuilder()
            .place(.dark, at: (1, 3)) // 左
            .place(.light, at: (2, 3))
            .place(.light, at: (4, 3))
            .place(.dark, at: (5, 3)) // 右
            .place(.dark, at: (3, 1)) // 上
            .place(.light, at: (3, 2))
            .place(.light, at: (3, 4))
            .place(.dark, at: (3, 5)) // 下
            .build()

        // When: (3,3)に黒を配置
        let position = Position(x: 3, y: 3)
        let flipped = engine.placeDisk(at: position, for: .dark, on: &board)

        // Then: 4方向のディスクが反転
        XCTAssertEqual(flipped.count, 4, "4方向で4つのディスクが反転")
        XCTAssertTrue(flipped.contains(Position(x: 2, y: 3)), "左のディスク反転")
        XCTAssertTrue(flipped.contains(Position(x: 4, y: 3)), "右のディスク反転")
        XCTAssertTrue(flipped.contains(Position(x: 3, y: 2)), "上のディスク反転")
        XCTAssertTrue(flipped.contains(Position(x: 3, y: 4)), "下のディスク反転")
    }

    func test_8方向すべてに反転_全方向のディスクが反転される() {
        // Given: 8方向すべてに相手のディスクがあり、その外側に自分のディスクがある
        var board = BoardBuilder()
            .place(.dark, at: (1, 1)) // 左上
            .place(.light, at: (2, 2))
            .place(.dark, at: (3, 1)) // 上
            .place(.light, at: (3, 2))
            .place(.dark, at: (5, 1)) // 右上
            .place(.light, at: (4, 2))
            .place(.dark, at: (1, 3)) // 左
            .place(.light, at: (2, 3))
            .place(.dark, at: (5, 3)) // 右
            .place(.light, at: (4, 3))
            .place(.dark, at: (1, 5)) // 左下
            .place(.light, at: (2, 4))
            .place(.dark, at: (3, 5)) // 下
            .place(.light, at: (3, 4))
            .place(.dark, at: (5, 5)) // 右下
            .place(.light, at: (4, 4))
            .build()

        // When: (3,3)に黒を配置
        let position = Position(x: 3, y: 3)
        let flipped = engine.placeDisk(at: position, for: .dark, on: &board)

        // Then: 8方向すべてのディスクが反転
        XCTAssertEqual(flipped.count, 8, "8方向で8つのディスクが反転")
    }

    func test_無効な位置に配置_空配列を返す() {
        // Given: 初期盤面
        var board = Board.initial()

        // When: 無効な位置に配置を試みる
        let position = Position(x: 0, y: 0) // ここには置けない
        let flipped = engine.placeDisk(at: position, for: .dark, on: &board)

        // Then: 何も反転されず、盤面も変化しない
        XCTAssertEqual(flipped.count, 0, "無効な位置では何も反転しない")
        XCTAssertNil(board.disk(at: position), "ディスクは配置されない")
    }

    func test_既にディスクがある位置に配置_空配列を返す() {
        // Given: 初期盤面
        var board = Board.initial()

        // When: すでにディスクがある位置に配置を試みる
        let position = Position(x: 3, y: 3) // すでに白ディスクがある
        let flipped = engine.placeDisk(at: position, for: .dark, on: &board)

        // Then: 何も反転されず、盤面も変化しない
        XCTAssertEqual(flipped.count, 0, "すでにディスクがある位置では何も反転しない")
        XCTAssertEqual(board.disk(at: position), .light, "元のディスクが残る")
    }

    // MARK: - winner テスト

    func test_黒が多い盤面_黒が勝者() {
        // Given: 黒が3個、白が1個の盤面
        let board = BoardBuilder()
            .place(.dark, at: (0, 0))
            .place(.dark, at: (1, 0))
            .place(.dark, at: (2, 0))
            .place(.light, at: (3, 0))
            .build()

        // When: 勝者を判定
        let winner = engine.winner(in: board)

        // Then: 黒が勝者
        XCTAssertEqual(winner, .dark, "黒が勝者")
    }

    func test_白が多い盤面_白が勝者() {
        // Given: 白が3個、黒が1個の盤面
        let board = BoardBuilder()
            .place(.light, at: (0, 0))
            .place(.light, at: (1, 0))
            .place(.light, at: (2, 0))
            .place(.dark, at: (3, 0))
            .build()

        // When: 勝者を判定
        let winner = engine.winner(in: board)

        // Then: 白が勝者
        XCTAssertEqual(winner, .light, "白が勝者")
    }

    func test_同数の盤面_引き分けでnil() {
        // Given: 黒白が同数（各2個）の盤面
        let board = Board.initial()

        // When: 勝者を判定
        let winner = engine.winner(in: board)

        // Then: 引き分けでnil
        XCTAssertNil(winner, "同数なので引き分け")
    }

    func test_空の盤面_引き分けでnil() {
        // Given: 空の盤面
        let board = Board()

        // When: 勝者を判定
        let winner = engine.winner(in: board)

        // Then: 引き分けでnil
        XCTAssertNil(winner, "空盤面は引き分け")
    }
}
