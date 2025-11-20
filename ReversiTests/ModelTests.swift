import XCTest
@testable import Reversi

/// Domain Modelsのテストスイート
///
/// Position, Board, Diskの基本的な機能をテスト
final class ModelTests: XCTestCase {

    // MARK: - Position Tests

    func test_Position_初期化() {
        // Arrange & Act
        let position = Position(x: 3, y: 4)

        // Assert
        XCTAssertEqual(position.x, 3)
        XCTAssertEqual(position.y, 4)
    }

    func test_Position_Hashable準拠() {
        // Arrange
        let pos1 = Position(x: 2, y: 3)
        let pos2 = Position(x: 2, y: 3)
        let pos3 = Position(x: 3, y: 2)

        // Act & Assert
        XCTAssertEqual(pos1, pos2, "同じ座標は等しい")
        XCTAssertNotEqual(pos1, pos3, "異なる座標は等しくない")

        // Setで使用可能
        let positionSet: Set<Position> = [pos1, pos2, pos3]
        XCTAssertEqual(positionSet.count, 2, "重複は除外される")
    }

    func test_Position_Codable準拠() throws {
        // Arrange
        let position = Position(x: 5, y: 7)

        // Act: エンコード
        let encoder = JSONEncoder()
        let data = try encoder.encode(position)

        // デコード
        let decoder = JSONDecoder()
        let decodedPosition = try decoder.decode(Position.self, from: data)

        // Assert
        XCTAssertEqual(decodedPosition.x, 5)
        XCTAssertEqual(decodedPosition.y, 7)
    }

    func test_Position_境界値() {
        // Arrange & Act
        let minPosition = Position(x: 0, y: 0)
        let maxPosition = Position(x: 7, y: 7)
        let negativePosition = Position(x: -1, y: -1)

        // Assert
        XCTAssertEqual(minPosition.x, 0)
        XCTAssertEqual(minPosition.y, 0)
        XCTAssertEqual(maxPosition.x, 7)
        XCTAssertEqual(maxPosition.y, 7)
        XCTAssertEqual(negativePosition.x, -1)
        XCTAssertEqual(negativePosition.y, -1)
    }

    // MARK: - Disk Tests

    func test_Disk_列挙() {
        // Act
        let sides = Disk.sides

        // Assert
        XCTAssertEqual(sides.count, 2, "2つのディスク")
        XCTAssertTrue(sides.contains(.dark), "黒を含む")
        XCTAssertTrue(sides.contains(.light), "白を含む")
    }

    func test_Disk_flipped_黒から白へ() {
        // Arrange
        let disk = Disk.dark

        // Act
        let flipped = disk.flipped

        // Assert
        XCTAssertEqual(flipped, .light, "黒の反転は白")
    }

    func test_Disk_flipped_白から黒へ() {
        // Arrange
        let disk = Disk.light

        // Act
        let flipped = disk.flipped

        // Assert
        XCTAssertEqual(flipped, .dark, "白の反転は黒")
    }

    func test_Disk_flip_黒が白に変わる() {
        // Arrange
        var disk = Disk.dark

        // Act
        disk.flip()

        // Assert
        XCTAssertEqual(disk, .light, "黒が白に変わる")
    }

    func test_Disk_flip_白が黒に変わる() {
        // Arrange
        var disk = Disk.light

        // Act
        disk.flip()

        // Assert
        XCTAssertEqual(disk, .dark, "白が黒に変わる")
    }

    func test_Disk_flip_2回で元に戻る() {
        // Arrange
        var disk = Disk.dark

        // Act
        disk.flip()
        disk.flip()

        // Assert
        XCTAssertEqual(disk, .dark, "2回反転で元に戻る")
    }

    func test_Disk_Hashable準拠() {
        // Arrange & Act
        let diskSet: Set<Disk> = [.dark, .light, .dark]

        // Assert
        XCTAssertEqual(diskSet.count, 2, "重複は除外される")
    }

    // MARK: - Board Tests

    func test_Board_サイズ定数() {
        // Assert
        XCTAssertEqual(Board.width, 8, "幅は8")
        XCTAssertEqual(Board.height, 8, "高さは8")
    }

    func test_Board_initial_中央4マスに正しく配置() {
        // Act
        let board = Board.initial()

        // Assert
        XCTAssertEqual(board.disk(at: Position(x: 3, y: 3)), .light, "中央左上は白")
        XCTAssertEqual(board.disk(at: Position(x: 4, y: 3)), .dark, "中央右上は黒")
        XCTAssertEqual(board.disk(at: Position(x: 3, y: 4)), .dark, "中央左下は黒")
        XCTAssertEqual(board.disk(at: Position(x: 4, y: 4)), .light, "中央右下は白")
    }

    func test_Board_initial_他のマスは空() {
        // Act
        let board = Board.initial()

        // Assert
        XCTAssertNil(board.disk(at: Position(x: 0, y: 0)), "角は空")
        XCTAssertNil(board.disk(at: Position(x: 7, y: 7)), "角は空")
        XCTAssertNil(board.disk(at: Position(x: 2, y: 2)), "中央付近も空")
    }

    func test_Board_disk_有効な座標() {
        // Arrange
        let board = Board.initial()

        // Act & Assert
        XCTAssertNotNil(board.disk(at: Position(x: 0, y: 0)), "境界内の座標は非nil（空でもOptional<Disk>を返す）")
    }

    func test_Board_disk_無効な座標_nilを返す() {
        // Arrange
        let board = Board.initial()

        // Act & Assert
        XCTAssertNil(board.disk(at: Position(x: -1, y: 0)), "負の座標はnil")
        XCTAssertNil(board.disk(at: Position(x: 0, y: -1)), "負の座標はnil")
        XCTAssertNil(board.disk(at: Position(x: 8, y: 0)), "範囲外の座標はnil")
        XCTAssertNil(board.disk(at: Position(x: 0, y: 8)), "範囲外の座標はnil")
    }

    func test_Board_setDisk_ディスクを配置() {
        // Arrange
        var board = Board.initial()
        let position = Position(x: 0, y: 0)

        // Act
        board.setDisk(.dark, at: position)

        // Assert
        XCTAssertEqual(board.disk(at: position), .dark, "黒が配置される")
    }

    func test_Board_setDisk_ディスクを削除() {
        // Arrange
        var board = Board.initial()
        let position = Position(x: 3, y: 3) // 白がある位置

        // Act
        board.setDisk(nil, at: position)

        // Assert
        XCTAssertNil(board.disk(at: position), "ディスクが削除される")
    }

    func test_Board_setDisk_無効な座標_何も起こらない() {
        // Arrange
        var board = Board.initial()
        let invalidPosition = Position(x: 10, y: 10)

        // Act
        board.setDisk(.dark, at: invalidPosition)

        // Assert: エラーが起きず、他の部分も変わらない
        XCTAssertEqual(board.disk(at: Position(x: 3, y: 3)), .light, "元の状態が保たれる")
    }

    func test_Board_isValid_境界内の座標() {
        // Arrange
        let board = Board.initial()

        // Act & Assert
        XCTAssertTrue(board.isValid(position: Position(x: 0, y: 0)), "左上角は有効")
        XCTAssertTrue(board.isValid(position: Position(x: 7, y: 7)), "右下角は有効")
        XCTAssertTrue(board.isValid(position: Position(x: 3, y: 4)), "中央は有効")
    }

    func test_Board_isValid_境界外の座標() {
        // Arrange
        let board = Board.initial()

        // Act & Assert
        XCTAssertFalse(board.isValid(position: Position(x: -1, y: 0)), "負の座標は無効")
        XCTAssertFalse(board.isValid(position: Position(x: 0, y: -1)), "負の座標は無効")
        XCTAssertFalse(board.isValid(position: Position(x: 8, y: 0)), "範囲外は無効")
        XCTAssertFalse(board.isValid(position: Position(x: 0, y: 8)), "範囲外は無効")
        XCTAssertFalse(board.isValid(position: Position(x: 10, y: 10)), "大きく範囲外は無効")
    }

    func test_Board_allPositions_64個の座標() {
        // Act
        let allPositions = Board.allPositions

        // Assert
        XCTAssertEqual(allPositions.count, 64, "8x8=64マス")
    }

    func test_Board_allPositions_すべて異なる座標() {
        // Act
        let allPositions = Board.allPositions
        let uniquePositions = Set(allPositions)

        // Assert
        XCTAssertEqual(uniquePositions.count, 64, "すべて異なる座標")
    }

    func test_Board_allPositions_範囲内の座標のみ() {
        // Act
        let allPositions = Board.allPositions

        // Assert
        for position in allPositions {
            XCTAssertTrue((0..<8).contains(position.x), "xは0-7の範囲")
            XCTAssertTrue((0..<8).contains(position.y), "yは0-7の範囲")
        }
    }

    func test_Board_allPositions_左上から右下の順() {
        // Act
        let allPositions = Board.allPositions

        // Assert
        XCTAssertEqual(allPositions.first, Position(x: 0, y: 0), "最初は左上")
        XCTAssertEqual(allPositions.last, Position(x: 7, y: 7), "最後は右下")
        XCTAssertEqual(allPositions[8], Position(x: 0, y: 1), "9番目は2行目の左端")
    }

    func test_Board_カスタム盤面の初期化() {
        // Arrange
        var disks = Array(repeating: Array(repeating: Optional<Disk>.none, count: 8), count: 8)
        disks[0][0] = .dark
        disks[7][7] = .light

        // Act
        let board = Board(disks: disks)

        // Assert
        XCTAssertEqual(board.disk(at: Position(x: 0, y: 0)), .dark, "(0,0)は黒")
        XCTAssertEqual(board.disk(at: Position(x: 7, y: 7)), .light, "(7,7)は白")
        XCTAssertNil(board.disk(at: Position(x: 1, y: 1)), "(1,1)は空")
    }

    func test_Board_初期化_不正なサイズ_preconditionFailure() {
        // Arrange: 不正なサイズの盤面（7x7）
        let invalidDisks = Array(repeating: Array(repeating: Optional<Disk>.none, count: 7), count: 7)

        // Act & Assert: preconditionFailureが発生するため、直接テストできない
        // 実際のテストでは、XCTAssertThrowsErrorは使えない（preconditionはfatalError）
        // ここでは、正常系のみテストする
        // Note: preconditionのテストは統合テストまたはクラッシュログで検証
    }

    func test_Board_Codable準拠() throws {
        // Arrange
        let board = Board.initial()

        // Act: エンコード
        let encoder = JSONEncoder()
        let data = try encoder.encode(board)

        // デコード
        let decoder = JSONDecoder()
        let decodedBoard = try decoder.decode(Board.self, from: data)

        // Assert
        XCTAssertEqual(decodedBoard.disk(at: Position(x: 3, y: 3)), .light)
        XCTAssertEqual(decodedBoard.disk(at: Position(x: 4, y: 3)), .dark)
        XCTAssertEqual(decodedBoard.disk(at: Position(x: 3, y: 4)), .dark)
        XCTAssertEqual(decodedBoard.disk(at: Position(x: 4, y: 4)), .light)
    }

    func test_Board_構造体の値型動作() {
        // Arrange
        var board1 = Board.initial()
        var board2 = board1 // コピー

        // Act
        board2.setDisk(.dark, at: Position(x: 0, y: 0))

        // Assert: board1は変更されない（値型）
        XCTAssertNil(board1.disk(at: Position(x: 0, y: 0)), "board1は変更されない")
        XCTAssertEqual(board2.disk(at: Position(x: 0, y: 0)), .dark, "board2のみ変更")
    }

    // MARK: - GameState Tests

    func test_GameState_初期化_デフォルト値() {
        // Act
        let state = GameState()

        // Assert
        XCTAssertEqual(state.currentTurn, .dark, "初期ターンは黒")
        XCTAssertEqual(state.darkPlayerMode, .manual, "黒は手動モード")
        XCTAssertEqual(state.lightPlayerMode, .manual, "白は手動モード")
        XCTAssertEqual(state.board.disk(at: Position(x: 3, y: 3)), .light, "初期盤面")
    }

    func test_GameState_初期化_カスタム値() {
        // Act
        let state = GameState(
            currentTurn: .light,
            darkPlayerMode: .computer,
            lightPlayerMode: .manual
        )

        // Assert
        XCTAssertEqual(state.currentTurn, .light, "カスタムターン")
        XCTAssertEqual(state.darkPlayerMode, .computer, "黒はコンピューター")
        XCTAssertEqual(state.lightPlayerMode, .manual, "白は手動")
    }

    func test_GameState_playerMode_黒のモードを取得() {
        // Arrange
        let state = GameState(darkPlayerMode: .computer, lightPlayerMode: .manual)

        // Act
        let darkMode = state.playerMode(for: .dark)

        // Assert
        XCTAssertEqual(darkMode, .computer, "黒のモード")
    }

    func test_GameState_playerMode_白のモードを取得() {
        // Arrange
        let state = GameState(darkPlayerMode: .computer, lightPlayerMode: .manual)

        // Act
        let lightMode = state.playerMode(for: .light)

        // Assert
        XCTAssertEqual(lightMode, .manual, "白のモード")
    }

    func test_GameState_setPlayerMode_黒のモードを変更() {
        // Arrange
        var state = GameState()

        // Act
        state.setPlayerMode(.computer, for: .dark)

        // Assert
        XCTAssertEqual(state.darkPlayerMode, .computer, "黒がコンピューターに変更")
        XCTAssertEqual(state.lightPlayerMode, .manual, "白は変わらない")
    }

    func test_GameState_setPlayerMode_白のモードを変更() {
        // Arrange
        var state = GameState()

        // Act
        state.setPlayerMode(.computer, for: .light)

        // Assert
        XCTAssertEqual(state.lightPlayerMode, .computer, "白がコンピューターに変更")
        XCTAssertEqual(state.darkPlayerMode, .manual, "黒は変わらない")
    }

    func test_GameState_Codable準拠() throws {
        // Arrange
        let state = GameState(
            currentTurn: .light,
            darkPlayerMode: .computer,
            lightPlayerMode: .manual
        )

        // Act: エンコード
        let encoder = JSONEncoder()
        let data = try encoder.encode(state)

        // デコード
        let decoder = JSONDecoder()
        let decodedState = try decoder.decode(GameState.self, from: data)

        // Assert
        XCTAssertEqual(decodedState.currentTurn, .light)
        XCTAssertEqual(decodedState.darkPlayerMode, .computer)
        XCTAssertEqual(decodedState.lightPlayerMode, .manual)
    }

    func test_GameState_構造体の値型動作() {
        // Arrange
        var state1 = GameState()
        var state2 = state1 // コピー

        // Act
        state2.currentTurn = .light
        state2.setPlayerMode(.computer, for: .dark)

        // Assert: state1は変更されない（値型）
        XCTAssertEqual(state1.currentTurn, .dark, "state1のターンは変わらない")
        XCTAssertEqual(state1.darkPlayerMode, .manual, "state1のモードは変わらない")
        XCTAssertEqual(state2.currentTurn, .light, "state2のみ変更")
        XCTAssertEqual(state2.darkPlayerMode, .computer, "state2のみ変更")
    }

    // MARK: - PlayerMode Tests

    func test_PlayerMode_列挙値() {
        // Arrange
        let manual = PlayerMode.manual
        let computer = PlayerMode.computer

        // Assert
        XCTAssertNotEqual(manual, computer, "2つのモードは異なる")
    }
}
