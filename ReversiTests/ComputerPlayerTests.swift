import XCTest
@testable import Reversi

/// ComputerPlayerのテストスイート
///
/// t-wadaスタイルのTDDアプローチに従い、以下をテスト:
/// - PlayerStrategy プロトコルの実装
/// - ComputerPlayerController の動作
/// - キャンセル処理
@MainActor
final class ComputerPlayerTests: XCTestCase {

    var controller: ComputerPlayerController!

    override func setUp() {
        super.setUp()
        controller = ComputerPlayerController()
    }

    override func tearDown() {
        controller = nil
        super.tearDown()
    }

    // MARK: - RandomComputerPlayer テスト

    func test_RandomComputerPlayer_思考時間は2秒() {
        // Arrange
        let strategy = RandomComputerPlayer()

        // Assert
        XCTAssertEqual(strategy.thinkingDelay, 2.0, "思考時間は2秒")
    }

    func test_RandomComputerPlayer_有効な手からランダムに選択() {
        // Arrange
        let strategy = RandomComputerPlayer()
        let validMoves: [(x: Int, y: Int)] = [(0, 0), (1, 1), (2, 2), (3, 3)]

        // Act
        let selectedMove = strategy.selectMove(from: validMoves)

        // Assert
        XCTAssertNotNil(selectedMove, "有効な手が選択される")
        XCTAssertTrue(validMoves.contains(where: { $0 == selectedMove! }), "選択された手は有効な手の中にある")
    }

    func test_RandomComputerPlayer_空の配列_nilを返す() {
        // Arrange
        let strategy = RandomComputerPlayer()
        let emptyMoves: [(x: Int, y: Int)] = []

        // Act
        let selectedMove = strategy.selectMove(from: emptyMoves)

        // Assert
        XCTAssertNil(selectedMove, "有効な手がない場合はnil")
    }

    func test_RandomComputerPlayer_単一の手_その手を返す() {
        // Arrange
        let strategy = RandomComputerPlayer()
        let singleMove: [(x: Int, y: Int)] = [(2, 3)]

        // Act
        let selectedMove = strategy.selectMove(from: singleMove)

        // Assert
        XCTAssertEqual(selectedMove?.x, 2, "x座標が一致")
        XCTAssertEqual(selectedMove?.y, 3, "y座標が一致")
    }

    // MARK: - ComputerPlayerController 初期化テスト

    func test_ComputerPlayerController_デフォルト戦略で初期化() {
        // Arrange & Act
        let controller = ComputerPlayerController()

        // Assert
        XCTAssertNotNil(controller, "コントローラーが初期化される")
    }

    func test_ComputerPlayerController_カスタム戦略で初期化() {
        // Arrange
        struct TestStrategy: PlayerStrategy {
            let thinkingDelay: TimeInterval = 0.5
            func selectMove(from validMoves: [(x: Int, y: Int)]) -> (x: Int, y: Int)? {
                validMoves.first
            }
        }
        let customStrategy = TestStrategy()

        // Act
        let controller = ComputerPlayerController(strategy: customStrategy)

        // Assert
        XCTAssertNotNil(controller, "カスタム戦略でコントローラーが初期化される")
    }

    // MARK: - playTurn テスト

    func test_playTurn_思考開始コールバックが呼ばれる() {
        // Arrange
        let expectation = XCTestExpectation(description: "思考開始コールバック")
        let validMoves: [(x: Int, y: Int)] = [(0, 0)]
        var thinkingStartCalled = false

        // Act
        controller.playTurn(
            for: .dark,
            validMoves: validMoves,
            onThinkingStart: {
                thinkingStartCalled = true
                expectation.fulfill()
            },
            onThinkingEnd: {},
            completion: { _ in }
        )

        // Assert
        wait(for: [expectation], timeout: 0.5)
        XCTAssertTrue(thinkingStartCalled, "思考開始コールバックが呼ばれる")
    }

    func test_playTurn_思考終了コールバックが呼ばれる() {
        // Arrange
        let expectation = XCTestExpectation(description: "思考終了コールバック")
        let validMoves: [(x: Int, y: Int)] = [(0, 0)]
        var thinkingEndCalled = false

        // Act
        controller.playTurn(
            for: .dark,
            validMoves: validMoves,
            onThinkingStart: {},
            onThinkingEnd: {
                thinkingEndCalled = true
                expectation.fulfill()
            },
            completion: { _ in }
        )

        // Assert
        wait(for: [expectation], timeout: 3.0)
        XCTAssertTrue(thinkingEndCalled, "思考終了コールバックが呼ばれる")
    }

    func test_playTurn_選択された手がcompletionに渡される() {
        // Arrange
        let expectation = XCTestExpectation(description: "completion呼び出し")
        let validMoves: [(x: Int, y: Int)] = [(2, 3)]
        var receivedMove: (x: Int, y: Int)?

        // Act
        controller.playTurn(
            for: .dark,
            validMoves: validMoves,
            onThinkingStart: {},
            onThinkingEnd: {},
            completion: { move in
                receivedMove = move
                expectation.fulfill()
            }
        )

        // Assert
        wait(for: [expectation], timeout: 3.0)
        XCTAssertNotNil(receivedMove, "手が選択される")
        XCTAssertEqual(receivedMove?.x, 2, "x座標が一致")
        XCTAssertEqual(receivedMove?.y, 3, "y座標が一致")
    }

    func test_playTurn_有効な手が複数_いずれかが選択される() {
        // Arrange
        let expectation = XCTestExpectation(description: "completion呼び出し")
        let validMoves: [(x: Int, y: Int)] = [(0, 0), (1, 1), (2, 2)]
        var receivedMove: (x: Int, y: Int)?

        // Act
        controller.playTurn(
            for: .dark,
            validMoves: validMoves,
            onThinkingStart: {},
            onThinkingEnd: {},
            completion: { move in
                receivedMove = move
                expectation.fulfill()
            }
        )

        // Assert
        wait(for: [expectation], timeout: 3.0)
        XCTAssertNotNil(receivedMove, "手が選択される")
        XCTAssertTrue(
            validMoves.contains(where: { $0 == receivedMove! }),
            "選択された手は有効な手の中にある"
        )
    }

    func test_playTurn_有効な手が空_nilがcompletionに渡される() {
        // Arrange
        let expectation = XCTestExpectation(description: "completion呼び出し")
        let emptyMoves: [(x: Int, y: Int)] = []
        var receivedMove: (x: Int, y: Int)?

        // Act
        controller.playTurn(
            for: .dark,
            validMoves: emptyMoves,
            onThinkingStart: {},
            onThinkingEnd: {},
            completion: { move in
                receivedMove = move
                expectation.fulfill()
            }
        )

        // Assert
        wait(for: [expectation], timeout: 0.5)
        XCTAssertNil(receivedMove, "有効な手がない場合はnil")
    }

    // MARK: - cancelTurn テスト

    func test_cancelTurn_思考をキャンセル_completionが呼ばれない() {
        // Arrange
        let expectation = XCTestExpectation(description: "completion呼び出し")
        expectation.isInverted = true  // completionが呼ばれないことを期待
        let validMoves: [(x: Int, y: Int)] = [(0, 0)]

        // Act: 思考を開始
        controller.playTurn(
            for: .dark,
            validMoves: validMoves,
            onThinkingStart: {},
            onThinkingEnd: {},
            completion: { _ in
                expectation.fulfill()
            }
        )

        // 少し待ってからキャンセル
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.controller.cancelTurn(for: .dark)
        }

        // Assert
        wait(for: [expectation], timeout: 3.0)
    }

    func test_cancelTurn_思考していない場合_エラーなし() {
        // Act & Assert: エラーが発生しないことを確認
        controller.cancelTurn(for: .dark)
        XCTAssertTrue(true, "エラーなし")
    }

    // MARK: - cancelAllTurns テスト

    func test_cancelAllTurns_すべての思考をキャンセル() {
        // Arrange
        let expectation1 = XCTestExpectation(description: "黒のcompletion")
        expectation1.isInverted = true
        let expectation2 = XCTestExpectation(description: "白のcompletion")
        expectation2.isInverted = true
        let validMoves: [(x: Int, y: Int)] = [(0, 0)]

        // Act: 黒と白の両方で思考を開始
        controller.playTurn(
            for: .dark,
            validMoves: validMoves,
            onThinkingStart: {},
            onThinkingEnd: {},
            completion: { _ in
                expectation1.fulfill()
            }
        )

        controller.playTurn(
            for: .light,
            validMoves: validMoves,
            onThinkingStart: {},
            onThinkingEnd: {},
            completion: { _ in
                expectation2.fulfill()
            }
        )

        // 少し待ってからすべてキャンセル
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.controller.cancelAllTurns()
        }

        // Assert
        wait(for: [expectation1, expectation2], timeout: 3.0)
    }

    // MARK: - カスタム戦略テスト

    func test_カスタム戦略_最初の手を選択() {
        // Arrange: 常に最初の手を選択する戦略
        struct FirstMoveStrategy: PlayerStrategy {
            let thinkingDelay: TimeInterval = 0.1
            func selectMove(from validMoves: [(x: Int, y: Int)]) -> (x: Int, y: Int)? {
                validMoves.first
            }
        }

        let customController = ComputerPlayerController(strategy: FirstMoveStrategy())
        let expectation = XCTestExpectation(description: "completion呼び出し")
        let validMoves: [(x: Int, y: Int)] = [(5, 5), (6, 6), (7, 7)]
        var receivedMove: (x: Int, y: Int)?

        // Act
        customController.playTurn(
            for: .dark,
            validMoves: validMoves,
            onThinkingStart: {},
            onThinkingEnd: {},
            completion: { move in
                receivedMove = move
                expectation.fulfill()
            }
        )

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedMove?.x, 5, "最初の手のx座標")
        XCTAssertEqual(receivedMove?.y, 5, "最初の手のy座標")
    }

    func test_カスタム戦略_思考時間が反映される() {
        // Arrange: 思考時間が短い戦略
        struct FastStrategy: PlayerStrategy {
            let thinkingDelay: TimeInterval = 0.1
            func selectMove(from validMoves: [(x: Int, y: Int)]) -> (x: Int, y: Int)? {
                validMoves.first
            }
        }

        let fastController = ComputerPlayerController(strategy: FastStrategy())
        let expectation = XCTestExpectation(description: "completion呼び出し")
        let validMoves: [(x: Int, y: Int)] = [(0, 0)]
        let startTime = Date()
        var elapsed: TimeInterval = 0

        // Act
        fastController.playTurn(
            for: .dark,
            validMoves: validMoves,
            onThinkingStart: {},
            onThinkingEnd: {},
            completion: { _ in
                elapsed = Date().timeIntervalSince(startTime)
                expectation.fulfill()
            }
        )

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertLessThan(elapsed, 0.5, "思考時間は0.5秒未満")
        XCTAssertGreaterThan(elapsed, 0.05, "思考時間は0.05秒以上")
    }
}
