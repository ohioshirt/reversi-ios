import XCTest
@testable import Reversi

/// ComputerStrategyのテスト
/// t-wadaスタイル: Given-When-Then パターンを使用
final class ComputerStrategyTests: XCTestCase {

    var strategy: ComputerStrategy!

    override func setUp() {
        super.setUp()
        strategy = ComputerStrategy()
    }

    override func tearDown() {
        strategy = nil
        super.tearDown()
    }

    // MARK: - 基本動作テスト

    func test_有効な手がある_いずれかの手を選択する() async {
        // Given: 初期盤面と有効な手
        let board = Board.initial()
        let engine = GameEngine()
        let validMoves = engine.validMoves(for: .dark, in: board)

        // When: コンピュータが手を選択
        let selected = await strategy.selectMove(
            in: board,
            for: .dark,
            validMoves: validMoves
        )

        // Then: 有効な手のいずれかが選択される
        XCTAssertNotNil(selected, "手が選択される")
        XCTAssertTrue(validMoves.contains(selected!), "有効な手から選択される")
    }

    func test_有効な手が空_nilを返す() async {
        // Given: 有効な手がない状況
        let board = Board()
        let validMoves: [Position] = []

        // When: コンピュータが手を選択
        let selected = await strategy.selectMove(
            in: board,
            for: .dark,
            validMoves: validMoves
        )

        // Then: nilが返される
        XCTAssertNil(selected, "有効な手がない場合はnil")
    }

    func test_複数回実行_毎回有効な手を選択する() async {
        // Given: 初期盤面
        let board = Board.initial()
        let engine = GameEngine()
        let validMoves = engine.validMoves(for: .dark, in: board)

        // When: 複数回実行
        for _ in 0..<10 {
            let selected = await strategy.selectMove(
                in: board,
                for: .dark,
                validMoves: validMoves
            )

            // Then: 毎回有効な手が選択される
            XCTAssertNotNil(selected, "毎回手が選択される")
            XCTAssertTrue(validMoves.contains(selected!), "毎回有効な手から選択される")
        }
    }

    func test_1つの手しかない_その手を選択する() async {
        // Given: 1つしか有効な手がない盤面
        let board = BoardBuilder()
            .place(.dark, at: (3, 3))
            .place(.light, at: (4, 3))
            .build()
        let validMoves = [Position(x: 5, y: 3)]

        // When: コンピュータが手を選択
        let selected = await strategy.selectMove(
            in: board,
            for: .dark,
            validMoves: validMoves
        )

        // Then: その手が選択される
        XCTAssertEqual(selected, Position(x: 5, y: 3), "唯一の手が選択される")
    }
}
