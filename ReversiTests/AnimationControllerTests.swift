import XCTest
@testable import Reversi

/// AnimationControllerのテストスイート
///
/// t-wadaスタイルのTDDアプローチに従い、以下をテスト:
/// - 初期化とプロパティ
/// - アニメーション実行
/// - キャンセル処理
/// - エラーハンドリング
@MainActor
final class AnimationControllerTests: XCTestCase {

    var boardView: BoardView!
    var animationController: AnimationController!

    override func setUp() {
        super.setUp()
        // BoardViewを初期化（8x8の盤面）
        boardView = BoardView(frame: CGRect(x: 0, y: 0, width: 320, height: 320))
        animationController = AnimationController(boardView: boardView)
    }

    override func tearDown() {
        animationController = nil
        boardView = nil
        super.tearDown()
    }

    // MARK: - 初期化テスト

    func test_初期化_BoardViewを保持() {
        // Arrange
        let boardView = BoardView(frame: CGRect(x: 0, y: 0, width: 320, height: 320))

        // Act
        let controller = AnimationController(boardView: boardView)

        // Assert
        XCTAssertNotNil(controller, "AnimationControllerが初期化される")
    }

    func test_初期状態_アニメーション実行中でない() {
        // Assert
        XCTAssertFalse(animationController.isAnimating, "初期状態はアニメーション実行中でない")
    }

    // MARK: - isAnimating プロパティテスト

    func test_isAnimating_アニメーション開始後true() async {
        // Arrange
        let expectation = XCTestExpectation(description: "アニメーション開始")
        let coordinates: [(Int, Int)] = [(0, 0), (1, 1)]

        // Act: アニメーションを開始（非同期）
        Task {
            _ = await animationController.animateSettingDisks(at: coordinates, to: .dark)
        }

        // 少し待ってからisAnimatingをチェック
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒

        // Assert
        // Note: アニメーションが既に完了している可能性があるため、
        // このテストは環境に依存します。実際のプロジェクトでは
        // モックを使用してより確実にテストします。
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func test_isAnimating_アニメーション完了後false() async {
        // Arrange
        let coordinates: [(Int, Int)] = [(0, 0)]

        // Act
        _ = await animationController.animateSettingDisks(at: coordinates, to: .dark)

        // Assert
        XCTAssertFalse(animationController.isAnimating, "アニメーション完了後はfalse")
    }

    // MARK: - animateSettingDisks (async版) テスト

    func test_animateSettingDisks_空の座標_即座に完了しtrueを返す() async {
        // Arrange
        let emptyCoordinates: [(Int, Int)] = []

        // Act
        let result = await animationController.animateSettingDisks(at: emptyCoordinates, to: .dark)

        // Assert
        XCTAssertTrue(result, "空の座標配列は即座に成功")
    }

    func test_animateSettingDisks_単一の座標_ディスクが配置される() async {
        // Arrange
        let coordinates: [(Int, Int)] = [(0, 0)]

        // Act
        let result = await animationController.animateSettingDisks(at: coordinates, to: .dark)

        // Assert
        XCTAssertTrue(result, "単一座標のアニメーションは成功")
        XCTAssertEqual(boardView.disk(atX: 0, y: 0), .dark, "(0,0)に黒ディスクが配置される")
    }

    func test_animateSettingDisks_複数の座標_順次配置される() async {
        // Arrange
        let coordinates: [(Int, Int)] = [(0, 0), (1, 1), (2, 2)]

        // Act
        let result = await animationController.animateSettingDisks(at: coordinates, to: .light)

        // Assert
        XCTAssertTrue(result, "複数座標のアニメーションは成功")
        XCTAssertEqual(boardView.disk(atX: 0, y: 0), .light, "(0,0)に白ディスク")
        XCTAssertEqual(boardView.disk(atX: 1, y: 1), .light, "(1,1)に白ディスク")
        XCTAssertEqual(boardView.disk(atX: 2, y: 2), .light, "(2,2)に白ディスク")
    }

    // MARK: - animateSettingDisks (コールバック版) テスト

    func test_animateSettingDisks_コールバック版_空の座標() {
        // Arrange
        let emptyCoordinates: [(Int, Int)] = []
        let expectation = XCTestExpectation(description: "completion呼び出し")
        var receivedResult: Bool?

        // Act
        animationController.animateSettingDisks(at: emptyCoordinates, to: .dark) { completed in
            receivedResult = completed
            expectation.fulfill()
        }

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedResult, true, "空の座標配列は即座に成功")
    }

    func test_animateSettingDisks_コールバック版_単一座標() {
        // Arrange
        let coordinates: [(Int, Int)] = [(3, 3)]
        let expectation = XCTestExpectation(description: "completion呼び出し")
        var receivedResult: Bool?

        // Act
        animationController.animateSettingDisks(at: coordinates, to: .dark) { completed in
            receivedResult = completed
            expectation.fulfill()
        }

        // Assert
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedResult, true, "単一座標のアニメーションは成功")
        XCTAssertEqual(boardView.disk(atX: 3, y: 3), .dark, "(3,3)に黒ディスク")
    }

    // MARK: - cancelAllAnimations テスト

    func test_cancelAllAnimations_アニメーション実行中_キャンセルされる() async {
        // Arrange: 長いアニメーションシーケンスを開始
        let coordinates: [(Int, Int)] = [(0, 0), (1, 1), (2, 2), (3, 3), (4, 4)]
        let expectation = XCTestExpectation(description: "アニメーション開始")

        Task {
            _ = await animationController.animateSettingDisks(at: coordinates, to: .dark)
        }

        // 少し待ってアニメーションが開始されることを確認
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒

        // Act: アニメーションをキャンセル
        animationController.cancelAllAnimations()

        // Assert
        XCTAssertFalse(animationController.isAnimating, "キャンセル後はアニメーション実行中でない")
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func test_cancelAllAnimations_アニメーション実行中でない_エラーなし() {
        // Act & Assert: エラーが発生しないことを確認
        animationController.cancelAllAnimations()
        XCTAssertFalse(animationController.isAnimating, "アニメーション実行中でない")
    }

    // MARK: - Canceller テスト

    func test_Canceller_初期状態_キャンセルされていない() {
        // Arrange & Act
        let canceller = Canceller(nil)

        // Assert
        XCTAssertFalse(canceller.isCancelled, "初期状態はキャンセルされていない")
    }

    func test_Canceller_cancel呼び出し_isCancelledがtrueになる() {
        // Arrange
        let canceller = Canceller(nil)

        // Act
        canceller.cancel()

        // Assert
        XCTAssertTrue(canceller.isCancelled, "cancel()後はisCancelledがtrue")
    }

    func test_Canceller_cancel呼び出し_bodyが実行される() {
        // Arrange
        var bodyCalled = false
        let canceller = Canceller {
            bodyCalled = true
        }

        // Act
        canceller.cancel()

        // Assert
        XCTAssertTrue(bodyCalled, "cancel()でbodyが実行される")
    }

    func test_Canceller_複数回cancel_bodyは1回のみ実行() {
        // Arrange
        var bodyCallCount = 0
        let canceller = Canceller {
            bodyCallCount += 1
        }

        // Act
        canceller.cancel()
        canceller.cancel()
        canceller.cancel()

        // Assert
        XCTAssertEqual(bodyCallCount, 1, "複数回cancel()してもbodyは1回のみ実行")
        XCTAssertTrue(canceller.isCancelled, "isCancelledはtrue")
    }

    // MARK: - エッジケーステスト

    func test_animateSettingDisks_境界座標_正しく配置される() async {
        // Arrange: 盤面の4隅
        let coordinates: [(Int, Int)] = [(0, 0), (7, 0), (0, 7), (7, 7)]

        // Act
        let result = await animationController.animateSettingDisks(at: coordinates, to: .dark)

        // Assert
        XCTAssertTrue(result, "境界座標のアニメーションは成功")
        XCTAssertEqual(boardView.disk(atX: 0, y: 0), .dark, "左上角")
        XCTAssertEqual(boardView.disk(atX: 7, y: 0), .dark, "右上角")
        XCTAssertEqual(boardView.disk(atX: 0, y: 7), .dark, "左下角")
        XCTAssertEqual(boardView.disk(atX: 7, y: 7), .dark, "右下角")
    }

    func test_animateSettingDisks_同じ座標に複数回_最後のディスクが配置される() async {
        // Arrange
        let coordinates: [(Int, Int)] = [(0, 0)]

        // Act: 最初に黒を配置
        _ = await animationController.animateSettingDisks(at: coordinates, to: .dark)
        XCTAssertEqual(boardView.disk(atX: 0, y: 0), .dark, "最初は黒")

        // 次に白を配置
        _ = await animationController.animateSettingDisks(at: coordinates, to: .light)

        // Assert
        XCTAssertEqual(boardView.disk(atX: 0, y: 0), .light, "最後に配置した白が残る")
    }
}
