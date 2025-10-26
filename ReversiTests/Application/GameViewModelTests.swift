import XCTest
import Combine
@testable import Reversi

/// GameViewModelのテスト
/// t-wadaスタイル: Given-When-Then パターンを使用
final class GameViewModelTests: XCTestCase {

    var viewModel: GameViewModel!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        let engine = GameEngine()
        viewModel = GameViewModel(engine: engine)
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        viewModel = nil
        super.tearDown()
    }

    // MARK: - 初期化テスト

    func test_初期化_初期状態が設定される() {
        // When: ViewModelを初期化（setUpで実行済み）

        // Then: 初期状態が設定される
        XCTAssertEqual(viewModel.state, GameState.initial(), "初期状態")
        XCTAssertFalse(viewModel.isAnimating, "アニメーション停止中")
    }

    // MARK: - 新しいゲーム開始テスト

    func test_新しいゲーム開始_初期状態にリセットされる() {
        // Given: ゲーム途中の状態
        var board = Board.initial()
        _ = viewModel.engine.placeDisk(at: Position(x: 2, y: 3), for: .dark, on: &board)
        viewModel.state = viewModel.state.settingBoard(board).settingCurrentTurn(.light)

        // When: 新しいゲームを開始
        viewModel.newGame()

        // Then: 初期状態に戻る
        XCTAssertEqual(viewModel.state, GameState.initial(), "初期状態にリセット")
    }

    // MARK: - ディスク配置テスト

    func test_有効な位置にディスク配置_盤面が更新される() async {
        // Given: 初期状態
        let position = Position(x: 2, y: 3)

        // When: ディスクを配置
        let result = await viewModel.placeDisk(at: position)

        // Then: 配置成功
        XCTAssertTrue(result, "配置成功")
        XCTAssertNotNil(viewModel.state.board.disk(at: position), "ディスクが配置される")
    }

    func test_無効な位置にディスク配置_配置失敗() async {
        // Given: 初期状態
        let position = Position(x: 0, y: 0) // 置けない位置

        // When: ディスクを配置
        let result = await viewModel.placeDisk(at: position)

        // Then: 配置失敗
        XCTAssertFalse(result, "配置失敗")
        XCTAssertNil(viewModel.state.board.disk(at: position), "ディスクは配置されない")
    }

    // MARK: - プレイヤーモード変更テスト

    func test_黒のプレイヤーモード変更_状態が更新される() {
        // Given: 初期状態（両方マニュアル）

        // When: 黒をコンピュータに変更
        viewModel.togglePlayerMode(for: .dark)

        // Then: 黒がコンピュータモードになる
        XCTAssertEqual(viewModel.state.playerMode(for: .dark), .computer, "黒がコンピュータ")
        XCTAssertEqual(viewModel.state.playerMode(for: .light), .manual, "白はマニュアル")
    }

    func test_白のプレイヤーモード変更_状態が更新される() {
        // Given: 初期状態

        // When: 白をコンピュータに変更
        viewModel.togglePlayerMode(for: .light)

        // Then: 白がコンピュータモードになる
        XCTAssertEqual(viewModel.state.playerMode(for: .dark), .manual, "黒はマニュアル")
        XCTAssertEqual(viewModel.state.playerMode(for: .light), .computer, "白がコンピュータ")
    }

    // MARK: - 有効な手の取得テスト

    func test_初期状態_黒の有効な手が取得できる() {
        // Given: 初期状態

        // When: 有効な手を取得
        let validMoves = viewModel.validMovesForCurrentPlayer()

        // Then: 4つの有効な手
        XCTAssertEqual(validMoves.count, 4, "黒の有効な手は4つ")
    }

    // MARK: - Publisherテスト

    func test_状態変更_Publisherが発火する() {
        // Given: Publisherを監視
        let expectation = XCTestExpectation(description: "State published")
        var publishedStates: [GameState] = []

        viewModel.$state
            .dropFirst() // 初期値をスキップ
            .sink { state in
                publishedStates.append(state)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When: 状態を変更
        viewModel.state = viewModel.state.settingCurrentTurn(.light)

        // Then: Publisherが発火
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(publishedStates.count, 1, "1回発火")
        XCTAssertEqual(publishedStates.first?.currentTurn, .light, "新しい状態が発行される")
    }
}
