import XCTest
@testable import Reversi

/// GameStateのテスト
/// t-wadaスタイル: Given-When-Then パターンを使用
final class GameStateTests: XCTestCase {

    // MARK: - 初期化テスト

    func test_初期状態を作成_黒のターンで中央に4つのディスク() {
        // When: 初期状態を作成
        let state = GameState.initial()

        // Then: 黒のターンで初期配置
        XCTAssertEqual(state.currentTurn, .dark, "初期ターンは黒")
        XCTAssertEqual(state.board, Board.initial(), "初期盤面が設定される")
        XCTAssertEqual(state.darkPlayerMode, .manual, "黒はマニュアルモード")
        XCTAssertEqual(state.lightPlayerMode, .manual, "白はマニュアルモード")
    }

    func test_カスタム状態で初期化_指定した値が設定される() {
        // Given: カスタム盤面
        let board = BoardBuilder()
            .place(.dark, at: (0, 0))
            .build()

        // When: カスタム状態を作成
        let state = GameState(
            board: board,
            currentTurn: .light,
            darkPlayerMode: .computer,
            lightPlayerMode: .manual
        )

        // Then: 指定した値が設定される
        XCTAssertEqual(state.currentTurn, .light, "白のターン")
        XCTAssertEqual(state.board, board, "カスタム盤面")
        XCTAssertEqual(state.darkPlayerMode, .computer, "黒はコンピュータ")
        XCTAssertEqual(state.lightPlayerMode, .manual, "白はマニュアル")
    }

    // MARK: - Immutable更新テスト

    func test_プレイヤーモード変更_新しいインスタンスを返す() {
        // Given: 初期状態
        let state = GameState.initial()

        // When: 黒のモードを変更
        let newState = state.settingDarkPlayerMode(.computer)

        // Then: 新しいインスタンスが返される
        XCTAssertEqual(state.darkPlayerMode, .manual, "元の状態は変わらない")
        XCTAssertEqual(newState.darkPlayerMode, .computer, "新しい状態が返される")
        XCTAssertNotEqual(state, newState, "異なるインスタンス")
    }

    func test_ターン変更_新しいインスタンスを返す() {
        // Given: 黒のターン
        let state = GameState.initial()

        // When: 白のターンに変更
        let newState = state.settingCurrentTurn(.light)

        // Then: 新しいインスタンスが返される
        XCTAssertEqual(state.currentTurn, .dark, "元の状態は変わらない")
        XCTAssertEqual(newState.currentTurn, .light, "新しい状態が返される")
    }

    func test_盤面更新_新しいインスタンスを返す() {
        // Given: 初期状態
        let state = GameState.initial()
        var newBoard = state.board
        newBoard.setDisk(.dark, at: Position(x: 2, y: 3))

        // When: 盤面を更新
        let newState = state.settingBoard(newBoard)

        // Then: 新しいインスタンスが返される
        XCTAssertEqual(state.board, Board.initial(), "元の盤面は変わらない")
        XCTAssertEqual(newState.board, newBoard, "新しい盤面が設定される")
    }

    // MARK: - ゲーム終了判定テスト

    func test_ターンがnil_ゲーム終了と判定() {
        // Given: ターンがnilの状態
        let state = GameState(
            board: Board.initial(),
            currentTurn: nil,
            darkPlayerMode: .manual,
            lightPlayerMode: .manual
        )

        // When & Then: ゲームが終了している
        XCTAssertTrue(state.isGameOver, "ターンがnilならゲーム終了")
    }

    func test_ターンがある_ゲーム継続中と判定() {
        // Given: ターンがある状態
        let state = GameState.initial()

        // When & Then: ゲームが継続中
        XCTAssertFalse(state.isGameOver, "ターンがあればゲーム継続")
    }

    // MARK: - プレイヤーモード取得テスト

    func test_黒のモードを取得() {
        // Given: 黒がコンピュータの状態
        let state = GameState.initial().settingDarkPlayerMode(.computer)

        // When: 黒のモードを取得
        let mode = state.playerMode(for: .dark)

        // Then: コンピュータモード
        XCTAssertEqual(mode, .computer, "黒のモードが取得できる")
    }

    func test_白のモードを取得() {
        // Given: 白がコンピュータの状態
        let state = GameState.initial().settingLightPlayerMode(.computer)

        // When: 白のモードを取得
        let mode = state.playerMode(for: .light)

        // Then: コンピュータモード
        XCTAssertEqual(mode, .computer, "白のモードが取得できる")
    }

    // MARK: - Equatableテスト

    func test_同じ状態_等しいと判定される() {
        // Given: 同じ状態
        let state1 = GameState.initial()
        let state2 = GameState.initial()

        // When & Then: 等しい
        XCTAssertEqual(state1, state2, "同じ状態は等しい")
    }

    func test_異なるターン_等しくないと判定される() {
        // Given: 異なるターン
        let state1 = GameState.initial()
        let state2 = state1.settingCurrentTurn(.light)

        // When & Then: 等しくない
        XCTAssertNotEqual(state1, state2, "異なるターンは等しくない")
    }

    func test_異なるプレイヤーモード_等しくないと判定される() {
        // Given: 異なるプレイヤーモード
        let state1 = GameState.initial()
        let state2 = state1.settingDarkPlayerMode(.computer)

        // When & Then: 等しくない
        XCTAssertNotEqual(state1, state2, "異なるプレイヤーモードは等しくない")
    }
}
