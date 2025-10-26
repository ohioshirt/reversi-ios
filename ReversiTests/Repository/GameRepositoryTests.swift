import XCTest
@testable import Reversi

/// GameRepositoryのテスト
/// t-wadaスタイル: Given-When-Then パターンを使用
final class GameRepositoryTests: XCTestCase {

    var repository: FileGameRepository!
    var testFilePath: String!

    override func setUp() {
        super.setUp()

        // テスト用の一時ファイルパスを生成
        let tempDir = NSTemporaryDirectory()
        testFilePath = (tempDir as NSString).appendingPathComponent("TestGame_\(UUID().uuidString)")
        repository = FileGameRepository(filePath: testFilePath)
    }

    override func tearDown() {
        // テストファイルを削除
        try? FileManager.default.removeItem(atPath: testFilePath)
        testFilePath = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - 保存テスト

    func test_初期状態を保存_ファイルが作成される() throws {
        // Given: 初期状態
        let state = GameState.initial()

        // When: 保存
        try repository.saveGame(state)

        // Then: ファイルが存在する
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFilePath), "ファイルが作成される")
    }

    func test_初期状態を保存_正しいフォーマットで保存される() throws {
        // Given: 初期状態
        let state = GameState.initial()

        // When: 保存
        try repository.saveGame(state)

        // Then: ファイル内容が期待通り
        let content = try String(contentsOfFile: testFilePath, encoding: .utf8)
        let lines = content.split(separator: "\n")

        XCTAssertEqual(lines.count, 9, "ヘッダー1行 + 盤面8行")
        XCTAssertEqual(lines[0], "x00", "黒のターン、両方マニュアル")
    }

    func test_カスタム状態を保存_プレイヤーモードが正しく保存される() throws {
        // Given: 白のターン、黒がコンピュータ
        let state = GameState(
            board: Board.initial(),
            currentTurn: .light,
            darkPlayerMode: .computer,
            lightPlayerMode: .manual
        )

        // When: 保存
        try repository.saveGame(state)

        // Then: ファイル内容が期待通り
        let content = try String(contentsOfFile: testFilePath, encoding: .utf8)
        let lines = content.split(separator: "\n")

        XCTAssertEqual(lines[0], "o10", "白のターン、黒がコンピュータ、白がマニュアル")
    }

    func test_ゲーム終了状態を保存_ターンなしで保存される() throws {
        // Given: ゲーム終了状態（ターンがnil）
        let state = GameState(
            board: Board.initial(),
            currentTurn: nil,
            darkPlayerMode: .manual,
            lightPlayerMode: .computer
        )

        // When: 保存
        try repository.saveGame(state)

        // Then: ファイル内容が期待通り
        let content = try String(contentsOfFile: testFilePath, encoding: .utf8)
        let lines = content.split(separator: "\n")

        XCTAssertEqual(lines[0], "-01", "ターンなし、白がコンピュータ")
    }

    func test_カスタム盤面を保存_盤面が正しく保存される() throws {
        // Given: カスタム盤面
        let board = BoardBuilder()
            .place(.dark, at: (0, 0))
            .place(.light, at: (0, 1))
            .build()
        let state = GameState(
            board: board,
            currentTurn: .dark,
            darkPlayerMode: .manual,
            lightPlayerMode: .manual
        )

        // When: 保存
        try repository.saveGame(state)

        // Then: 盤面が正しく保存される
        let content = try String(contentsOfFile: testFilePath, encoding: .utf8)
        let lines = content.split(separator: "\n")

        XCTAssertEqual(lines[1].prefix(1), "x", "0,0に黒")
        XCTAssertEqual(lines[2].prefix(1), "o", "0,1に白")
    }

    // MARK: - 読み込みテスト

    func test_保存したファイルを読み込み_同じ状態が復元される() throws {
        // Given: 保存済みの状態
        let originalState = GameState.initial()
        try repository.saveGame(originalState)

        // When: 読み込み
        let loadedState = try repository.loadGame()

        // Then: 同じ状態が復元される
        XCTAssertEqual(loadedState, originalState, "同じ状態が復元される")
    }

    func test_カスタム状態を保存して読み込み_同じ状態が復元される() throws {
        // Given: カスタム状態
        let originalState = GameState(
            board: Board.initial(),
            currentTurn: .light,
            darkPlayerMode: .computer,
            lightPlayerMode: .manual
        )
        try repository.saveGame(originalState)

        // When: 読み込み
        let loadedState = try repository.loadGame()

        // Then: 同じ状態が復元される
        XCTAssertEqual(loadedState, originalState, "カスタム状態が復元される")
    }

    func test_ゲーム終了状態を保存して読み込み_同じ状態が復元される() throws {
        // Given: ゲーム終了状態
        let originalState = GameState(
            board: Board.initial(),
            currentTurn: nil,
            darkPlayerMode: .manual,
            lightPlayerMode: .computer
        )
        try repository.saveGame(originalState)

        // When: 読み込み
        let loadedState = try repository.loadGame()

        // Then: 同じ状態が復元される
        XCTAssertEqual(loadedState, originalState, "ゲーム終了状態が復元される")
    }

    func test_複雑な盤面を保存して読み込み_盤面が正しく復元される() throws {
        // Given: 複雑な盤面
        let board = BoardBuilder()
            .place(.dark, at: (0, 0))
            .place(.dark, at: (1, 1))
            .place(.dark, at: (2, 2))
            .place(.light, at: (0, 1))
            .place(.light, at: (1, 0))
            .build()
        let originalState = GameState(
            board: board,
            currentTurn: .dark,
            darkPlayerMode: .computer,
            lightPlayerMode: .computer
        )
        try repository.saveGame(originalState)

        // When: 読み込み
        let loadedState = try repository.loadGame()

        // Then: 盤面が正しく復元される
        XCTAssertEqual(loadedState.board, board, "盤面が正しく復元される")
        XCTAssertEqual(loadedState.currentTurn, .dark, "ターンが正しい")
        XCTAssertEqual(loadedState.darkPlayerMode, .computer, "黒のモードが正しい")
        XCTAssertEqual(loadedState.lightPlayerMode, .computer, "白のモードが正しい")
    }

    // MARK: - エラーハンドリングテスト

    func test_ファイルが存在しない_読み込みエラー() {
        // Given: ファイルが存在しない

        // When & Then: 読み込みエラー
        XCTAssertThrowsError(try repository.loadGame(), "ファイルが存在しない場合はエラー") { error in
            XCTAssertTrue(error is GameRepositoryError, "GameRepositoryErrorがスローされる")
        }
    }

    func test_不正なフォーマット_読み込みエラー() throws {
        // Given: 不正なフォーマットのファイル
        try "invalid".write(toFile: testFilePath, atomically: true, encoding: .utf8)

        // When & Then: 読み込みエラー
        XCTAssertThrowsError(try repository.loadGame(), "不正なフォーマットはエラー") { error in
            XCTAssertTrue(error is GameRepositoryError, "GameRepositoryErrorがスローされる")
        }
    }

    func test_空のファイル_読み込みエラー() throws {
        // Given: 空のファイル
        try "".write(toFile: testFilePath, atomically: true, encoding: .utf8)

        // When & Then: 読み込みエラー
        XCTAssertThrowsError(try repository.loadGame(), "空のファイルはエラー") { error in
            XCTAssertTrue(error is GameRepositoryError, "GameRepositoryErrorがスローされる")
        }
    }

    func test_盤面サイズ不正_読み込みエラー() throws {
        // Given: 盤面サイズが不正なファイル
        let content = """
        x00
        xxx
        ooo
        """
        try content.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        // When & Then: 読み込みエラー
        XCTAssertThrowsError(try repository.loadGame(), "盤面サイズ不正はエラー") { error in
            XCTAssertTrue(error is GameRepositoryError, "GameRepositoryErrorがスローされる")
        }
    }

    // MARK: - 既存フォーマット互換性テスト

    func test_既存フォーマットのファイルを読み込み_正しく解析される() throws {
        // Given: 既存フォーマットのファイル（ViewControllerと同じフォーマット）
        let content = """
        x00
        --------
        --------
        --------
        ---ox---
        ---xo---
        --------
        --------
        --------
        """
        try content.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        // When: 読み込み
        let state = try repository.loadGame()

        // Then: 正しく解析される
        XCTAssertEqual(state.currentTurn, .dark, "黒のターン")
        XCTAssertEqual(state.darkPlayerMode, .manual, "黒はマニュアル")
        XCTAssertEqual(state.lightPlayerMode, .manual, "白はマニュアル")
        XCTAssertEqual(state.board, Board.initial(), "初期盤面")
    }
}
