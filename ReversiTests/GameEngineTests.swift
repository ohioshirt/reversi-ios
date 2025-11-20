import XCTest
@testable import Reversi

/// GameEngineのテストスイート
///
/// t-wadaスタイルのTDDアプローチに従い、以下のパターンを適用:
/// - AAA (Arrange-Act-Assert) パターン
/// - 日本語テスト名による可読性向上
/// - 境界値テストとエッジケースの網羅
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

    // MARK: - 初期盤面テスト

    func test_初期盤面_中央4マスに正しくディスクが配置されている() {
        // Arrange
        let board = Board.initial()

        // Act & Assert
        XCTAssertEqual(board.disk(at: Position(x: 3, y: 3)), .light, "中央左上は白")
        XCTAssertEqual(board.disk(at: Position(x: 4, y: 3)), .dark, "中央右上は黒")
        XCTAssertEqual(board.disk(at: Position(x: 3, y: 4)), .dark, "中央左下は黒")
        XCTAssertEqual(board.disk(at: Position(x: 4, y: 4)), .light, "中央右下は白")
    }

    func test_初期盤面_黒の有効な手が4つ() {
        // Arrange
        let board = Board.initial()

        // Act
        let validMoves = engine.validMoves(for: .dark, in: board)

        // Assert
        XCTAssertEqual(validMoves.count, 4, "黒の有効な手は4つ")
        XCTAssertTrue(validMoves.contains(Position(x: 2, y: 3)), "(2,3)は有効")
        XCTAssertTrue(validMoves.contains(Position(x: 3, y: 2)), "(3,2)は有効")
        XCTAssertTrue(validMoves.contains(Position(x: 4, y: 5)), "(4,5)は有効")
        XCTAssertTrue(validMoves.contains(Position(x: 5, y: 4)), "(5,4)は有効")
    }

    func test_初期盤面_白の有効な手が4つ() {
        // Arrange
        let board = Board.initial()

        // Act
        let validMoves = engine.validMoves(for: .light, in: board)

        // Assert
        XCTAssertEqual(validMoves.count, 4, "白の有効な手は4つ")
        XCTAssertTrue(validMoves.contains(Position(x: 2, y: 4)), "(2,4)は有効")
        XCTAssertTrue(validMoves.contains(Position(x: 3, y: 5)), "(3,5)は有効")
        XCTAssertTrue(validMoves.contains(Position(x: 4, y: 2)), "(4,2)は有効")
        XCTAssertTrue(validMoves.contains(Position(x: 5, y: 3)), "(5,3)は有効")
    }

    // MARK: - ディスク配置テスト

    func test_初期盤面_黒が2_3に配置_1つのディスクが反転される() {
        // Arrange
        var board = Board.initial()
        let position = Position(x: 2, y: 3)

        // Act
        let flippedPositions = engine.placeDisk(at: position, for: .dark, on: &board)

        // Assert
        XCTAssertEqual(flippedPositions.count, 1, "1つのディスクが反転")
        XCTAssertTrue(flippedPositions.contains(Position(x: 3, y: 3)), "(3,3)が反転")
        XCTAssertEqual(board.disk(at: position), .dark, "配置位置は黒")
        XCTAssertEqual(board.disk(at: Position(x: 3, y: 3)), .dark, "(3,3)は黒に反転")
    }

    func test_既にディスクがある位置_配置失敗_空配列を返す() {
        // Arrange
        var board = Board.initial()
        let occupiedPosition = Position(x: 3, y: 3) // 白がある位置

        // Act
        let flippedPositions = engine.placeDisk(at: occupiedPosition, for: .dark, on: &board)

        // Assert
        XCTAssertEqual(flippedPositions.count, 0, "配置失敗で空配列")
        XCTAssertEqual(board.disk(at: occupiedPosition), .light, "元の白ディスクは変わらない")
    }

    func test_反転するディスクがない位置_配置失敗_空配列を返す() {
        // Arrange
        var board = Board.initial()
        let invalidPosition = Position(x: 0, y: 0) // 無効な手

        // Act
        let flippedPositions = engine.placeDisk(at: invalidPosition, for: .dark, on: &board)

        // Assert
        XCTAssertEqual(flippedPositions.count, 0, "配置失敗で空配列")
        XCTAssertNil(board.disk(at: invalidPosition), "ディスクは配置されない")
    }

    // MARK: - 8方向の反転テスト

    func test_8方向すべてに相手ディスクがある_全方向で反転される() {
        // Arrange: 中央に白を囲むように黒を配置
        var disks = Array(repeating: Array(repeating: Optional<Disk>.none, count: 8), count: 8)
        let center = Position(x: 4, y: 4)

        // 中央に白
        disks[4][4] = .light

        // 8方向すべてに黒-白のペアを配置
        disks[3][3] = .dark  // ↖
        disks[2][2] = .light
        disks[3][4] = .dark  // ←
        disks[2][4] = .light
        disks[3][5] = .dark  // ↙
        disks[2][6] = .light
        disks[4][5] = .dark  // ↓
        disks[4][6] = .light
        disks[5][5] = .dark  // ↘
        disks[6][6] = .light
        disks[5][4] = .dark  // →
        disks[6][4] = .light
        disks[5][3] = .dark  // ↗
        disks[6][2] = .light
        disks[4][3] = .dark  // ↑
        disks[4][2] = .light

        var board = Board(disks: disks)

        // Act
        let flippedPositions = engine.placeDisk(at: center, for: .dark, on: &board)

        // Assert
        XCTAssertEqual(flippedPositions.count, 8, "8方向すべてで1つずつ反転")
        XCTAssertEqual(board.disk(at: center), .dark, "中央は黒")
    }

    func test_縦方向_複数ディスクが反転される() {
        // Arrange
        var disks = Array(repeating: Array(repeating: Optional<Disk>.none, count: 8), count: 8)
        disks[0][4] = .dark  // 上端
        disks[1][4] = .light
        disks[2][4] = .light
        disks[3][4] = .light
        // disks[4][4] = 配置予定地

        var board = Board(disks: disks)
        let position = Position(x: 4, y: 4)

        // Act
        let flippedPositions = engine.placeDisk(at: position, for: .dark, on: &board)

        // Assert
        XCTAssertEqual(flippedPositions.count, 3, "3つの白ディスクが反転")
        XCTAssertTrue(flippedPositions.contains(Position(x: 4, y: 1)))
        XCTAssertTrue(flippedPositions.contains(Position(x: 4, y: 2)))
        XCTAssertTrue(flippedPositions.contains(Position(x: 4, y: 3)))
    }

    func test_横方向_複数ディスクが反転される() {
        // Arrange
        var disks = Array(repeating: Array(repeating: Optional<Disk>.none, count: 8), count: 8)
        disks[4][0] = .dark  // 左端
        disks[4][1] = .light
        disks[4][2] = .light
        disks[4][3] = .light
        // disks[4][4] = 配置予定地

        var board = Board(disks: disks)
        let position = Position(x: 4, y: 4)

        // Act
        let flippedPositions = engine.placeDisk(at: position, for: .dark, on: &board)

        // Assert
        XCTAssertEqual(flippedPositions.count, 3, "3つの白ディスクが反転")
        XCTAssertTrue(flippedPositions.contains(Position(x: 1, y: 4)))
        XCTAssertTrue(flippedPositions.contains(Position(x: 2, y: 4)))
        XCTAssertTrue(flippedPositions.contains(Position(x: 3, y: 4)))
    }

    func test_斜め方向_複数ディスクが反転される() {
        // Arrange
        var disks = Array(repeating: Array(repeating: Optional<Disk>.none, count: 8), count: 8)
        disks[0][0] = .dark  // 左上
        disks[1][1] = .light
        disks[2][2] = .light
        disks[3][3] = .light
        // disks[4][4] = 配置予定地

        var board = Board(disks: disks)
        let position = Position(x: 4, y: 4)

        // Act
        let flippedPositions = engine.placeDisk(at: position, for: .dark, on: &board)

        // Assert
        XCTAssertEqual(flippedPositions.count, 3, "3つの白ディスクが反転")
        XCTAssertTrue(flippedPositions.contains(Position(x: 1, y: 1)))
        XCTAssertTrue(flippedPositions.contains(Position(x: 2, y: 2)))
        XCTAssertTrue(flippedPositions.contains(Position(x: 3, y: 3)))
    }

    // MARK: - 角・辺のテスト

    func test_角_左上0_0_に配置可能な場合() {
        // Arrange
        var disks = Array(repeating: Array(repeating: Optional<Disk>.none, count: 8), count: 8)
        disks[0][1] = .light
        disks[0][2] = .dark

        var board = Board(disks: disks)
        let corner = Position(x: 0, y: 0)

        // Act
        let flippedPositions = engine.placeDisk(at: corner, for: .dark, on: &board)

        // Assert
        XCTAssertEqual(flippedPositions.count, 1, "1つ反転")
        XCTAssertTrue(flippedPositions.contains(Position(x: 1, y: 0)))
        XCTAssertEqual(board.disk(at: corner), .dark, "角に配置成功")
    }

    func test_角_右下7_7_に配置可能な場合() {
        // Arrange
        var disks = Array(repeating: Array(repeating: Optional<Disk>.none, count: 8), count: 8)
        disks[7][6] = .light
        disks[7][5] = .dark

        var board = Board(disks: disks)
        let corner = Position(x: 7, y: 7)

        // Act
        let flippedPositions = engine.placeDisk(at: corner, for: .dark, on: &board)

        // Assert
        XCTAssertEqual(flippedPositions.count, 1, "1つ反転")
        XCTAssertTrue(flippedPositions.contains(Position(x: 6, y: 7)))
        XCTAssertEqual(board.disk(at: corner), .dark, "角に配置成功")
    }

    // MARK: - canPlaceDisk テスト

    func test_canPlaceDisk_初期盤面_黒の有効な位置() {
        // Arrange
        let board = Board.initial()

        // Act & Assert
        XCTAssertTrue(engine.canPlaceDisk(at: Position(x: 2, y: 3), for: .dark, in: board))
        XCTAssertTrue(engine.canPlaceDisk(at: Position(x: 3, y: 2), for: .dark, in: board))
        XCTAssertTrue(engine.canPlaceDisk(at: Position(x: 4, y: 5), for: .dark, in: board))
        XCTAssertTrue(engine.canPlaceDisk(at: Position(x: 5, y: 4), for: .dark, in: board))
    }

    func test_canPlaceDisk_初期盤面_黒の無効な位置() {
        // Arrange
        let board = Board.initial()

        // Act & Assert
        XCTAssertFalse(engine.canPlaceDisk(at: Position(x: 0, y: 0), for: .dark, in: board), "角は無効")
        XCTAssertFalse(engine.canPlaceDisk(at: Position(x: 3, y: 3), for: .dark, in: board), "既にディスクがある")
        XCTAssertFalse(engine.canPlaceDisk(at: Position(x: 7, y: 7), for: .dark, in: board), "反転なし")
    }

    // MARK: - flippedDiskPositions テスト

    func test_flippedDiskPositions_配置前に反転座標を取得() {
        // Arrange
        let board = Board.initial()
        let position = Position(x: 2, y: 3)

        // Act
        let flippedPositions = engine.flippedDiskPositions(at: position, for: .dark, in: board)

        // Assert
        XCTAssertEqual(flippedPositions.count, 1, "1つ反転予定")
        XCTAssertTrue(flippedPositions.contains(Position(x: 3, y: 3)))
    }

    func test_flippedDiskPositions_既にディスクがある位置_空配列を返す() {
        // Arrange
        let board = Board.initial()
        let occupiedPosition = Position(x: 3, y: 3)

        // Act
        let flippedPositions = engine.flippedDiskPositions(at: occupiedPosition, for: .dark, in: board)

        // Assert
        XCTAssertEqual(flippedPositions.count, 0, "空配列")
    }

    func test_flippedDiskPositions_無効な手_空配列を返す() {
        // Arrange
        let board = Board.initial()
        let invalidPosition = Position(x: 0, y: 0)

        // Act
        let flippedPositions = engine.flippedDiskPositions(at: invalidPosition, for: .dark, in: board)

        // Assert
        XCTAssertEqual(flippedPositions.count, 0, "空配列")
    }

    // MARK: - diskCount テスト

    func test_diskCount_初期盤面_黒と白がそれぞれ2つ() {
        // Arrange
        let board = Board.initial()

        // Act
        let darkCount = engine.diskCount(for: .dark, in: board)
        let lightCount = engine.diskCount(for: .light, in: board)

        // Assert
        XCTAssertEqual(darkCount, 2, "黒は2つ")
        XCTAssertEqual(lightCount, 2, "白は2つ")
    }

    func test_diskCount_空の盤面_0を返す() {
        // Arrange
        let emptyDisks = Array(repeating: Array(repeating: Optional<Disk>.none, count: 8), count: 8)
        let board = Board(disks: emptyDisks)

        // Act
        let darkCount = engine.diskCount(for: .dark, in: board)
        let lightCount = engine.diskCount(for: .light, in: board)

        // Assert
        XCTAssertEqual(darkCount, 0, "黒は0つ")
        XCTAssertEqual(lightCount, 0, "白は0つ")
    }

    func test_diskCount_盤面が埋まっている_正しくカウント() {
        // Arrange: 盤面全体を黒で埋める（64マス）
        let fullDisks = Array(repeating: Array(repeating: Optional<Disk>.some(.dark), count: 8), count: 8)
        let board = Board(disks: fullDisks)

        // Act
        let darkCount = engine.diskCount(for: .dark, in: board)
        let lightCount = engine.diskCount(for: .light, in: board)

        // Assert
        XCTAssertEqual(darkCount, 64, "黒は64つ")
        XCTAssertEqual(lightCount, 0, "白は0つ")
    }

    // MARK: - winner テスト

    func test_winner_黒が多い_黒の勝利() {
        // Arrange
        var disks = Array(repeating: Array(repeating: Optional<Disk>.none, count: 8), count: 8)
        disks[0][0] = .dark
        disks[0][1] = .dark
        disks[0][2] = .dark
        disks[1][0] = .light
        disks[1][1] = .light
        let board = Board(disks: disks)

        // Act
        let winner = engine.winner(in: board)

        // Assert
        XCTAssertEqual(winner, .dark, "黒の勝利")
    }

    func test_winner_白が多い_白の勝利() {
        // Arrange
        var disks = Array(repeating: Array(repeating: Optional<Disk>.none, count: 8), count: 8)
        disks[0][0] = .light
        disks[0][1] = .light
        disks[0][2] = .light
        disks[1][0] = .dark
        disks[1][1] = .dark
        let board = Board(disks: disks)

        // Act
        let winner = engine.winner(in: board)

        // Assert
        XCTAssertEqual(winner, .light, "白の勝利")
    }

    func test_winner_同数_引き分け() {
        // Arrange
        var disks = Array(repeating: Array(repeating: Optional<Disk>.none, count: 8), count: 8)
        disks[0][0] = .dark
        disks[0][1] = .dark
        disks[1][0] = .light
        disks[1][1] = .light
        let board = Board(disks: disks)

        // Act
        let winner = engine.winner(in: board)

        // Assert
        XCTAssertNil(winner, "引き分け")
    }

    func test_winner_空の盤面_引き分け() {
        // Arrange
        let emptyDisks = Array(repeating: Array(repeating: Optional<Disk>.none, count: 8), count: 8)
        let board = Board(disks: emptyDisks)

        // Act
        let winner = engine.winner(in: board)

        // Assert
        XCTAssertNil(winner, "引き分け（両方0）")
    }

    // MARK: - validMoves エッジケーステスト

    func test_validMoves_有効な手が存在しない() {
        // Arrange: 黒のディスクのみで白の手がない
        var disks = Array(repeating: Array(repeating: Optional<Disk>.none, count: 8), count: 8)
        disks[0][0] = .dark
        disks[0][1] = .dark
        let board = Board(disks: disks)

        // Act
        let validMoves = engine.validMoves(for: .light, in: board)

        // Assert
        XCTAssertEqual(validMoves.count, 0, "有効な手なし")
    }

    func test_validMoves_盤面が埋まっている_有効な手なし() {
        // Arrange
        let fullDisks = Array(repeating: Array(repeating: Optional<Disk>.some(.dark), count: 8), count: 8)
        let board = Board(disks: fullDisks)

        // Act
        let validMoves = engine.validMoves(for: .light, in: board)

        // Assert
        XCTAssertEqual(validMoves.count, 0, "盤面が埋まっているので有効な手なし")
    }

    // MARK: - 複雑なシナリオテスト

    func test_複数ターン_ゲーム進行() {
        // Arrange
        var board = Board.initial()

        // Act: 複数ターンのゲーム進行をシミュレート
        // Turn 1: 黒 (2,3)
        let flipped1 = engine.placeDisk(at: Position(x: 2, y: 3), for: .dark, on: &board)
        XCTAssertEqual(flipped1.count, 1)
        XCTAssertEqual(engine.diskCount(for: .dark, in: board), 4)
        XCTAssertEqual(engine.diskCount(for: .light, in: board), 1)

        // Turn 2: 白 (2,2)
        let flipped2 = engine.placeDisk(at: Position(x: 2, y: 2), for: .light, on: &board)
        XCTAssertEqual(flipped2.count, 1)
        XCTAssertEqual(engine.diskCount(for: .dark, in: board), 3)
        XCTAssertEqual(engine.diskCount(for: .light, in: board), 3)

        // Turn 3: 黒 (2,4)
        let flipped3 = engine.placeDisk(at: Position(x: 2, y: 4), for: .dark, on: &board)
        XCTAssertGreaterThan(flipped3.count, 0)

        // Assert: ゲームが正常に進行している
        let totalDisks = engine.diskCount(for: .dark, in: board) + engine.diskCount(for: .light, in: board)
        XCTAssertEqual(totalDisks, 7, "3ターン後に7つのディスク")
    }

    func test_連鎖反転_複数方向に同時反転() {
        // Arrange: 十字に配置して中央に置くと複数方向に反転
        var disks = Array(repeating: Array(repeating: Optional<Disk>.none, count: 8), count: 8)
        let center = Position(x: 4, y: 4)

        // 上下左右に白-黒のペアを配置
        disks[4][2] = .dark  // 左
        disks[4][3] = .light
        disks[4][5] = .light // 右
        disks[4][6] = .dark
        disks[2][4] = .dark  // 上
        disks[3][4] = .light
        disks[5][4] = .light // 下
        disks[6][4] = .dark

        var board = Board(disks: disks)

        // Act
        let flippedPositions = engine.placeDisk(at: center, for: .dark, on: &board)

        // Assert
        XCTAssertEqual(flippedPositions.count, 4, "4方向で4つ反転")
        XCTAssertEqual(engine.diskCount(for: .dark, in: board), 9, "黒は9つ（元4+中央1+反転4）")
    }
}
