import Foundation

// MARK: - GameRepositoryError

/// ゲームリポジトリで発生するエラー
public enum GameRepositoryError: Error {
    /// ファイルの読み込みに失敗
    case loadFailed(path: String, cause: Error?)

    /// ファイルの書き込みに失敗
    case saveFailed(path: String, cause: Error?)

    /// ファイルフォーマットが不正
    case invalidFormat(path: String)
}

// MARK: - GameRepository Protocol

/// ゲーム状態の永続化を担当するリポジトリ
public protocol GameRepository {
    /// ゲーム状態を保存
    /// - Parameter state: 保存するゲーム状態
    /// - Throws: 保存に失敗した場合
    func saveGame(_ state: GameState) throws

    /// ゲーム状態を読み込み
    /// - Returns: 読み込んだゲーム状態
    /// - Throws: 読み込みに失敗した場合
    func loadGame() throws -> GameState
}

// MARK: - FileGameRepository

/// ファイルベースのゲームリポジトリ実装
/// 既存のViewControllerと同じファイルフォーマットを使用
public final class FileGameRepository: GameRepository {

    // MARK: - Properties

    /// ゲームファイルのパス
    private let filePath: String

    // MARK: - Initialization

    /// 初期化
    /// - Parameter filePath: ゲームファイルのパス。nilの場合はデフォルトパスを使用
    public init(filePath: String? = nil) {
        if let filePath = filePath {
            self.filePath = filePath
        } else {
            // デフォルトパス: Library/Game
            let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
            self.filePath = (libraryPath as NSString).appendingPathComponent("Game")
        }
    }

    // MARK: - GameRepository

    /// ゲーム状態を保存
    /// - Parameter state: 保存するゲーム状態
    /// - Throws: 保存に失敗した場合
    public func saveGame(_ state: GameState) throws {
        var output = ""

        // ヘッダー行: ターン + プレイヤーモード
        output += state.currentTurn?.symbol ?? "-"
        output += state.darkPlayerMode == .manual ? "0" : "1"
        output += state.lightPlayerMode == .manual ? "0" : "1"
        output += "\n"

        // 盤面: 8x8の文字列
        for y in 0..<8 {
            for x in 0..<8 {
                let position = Position(x: x, y: y)
                let disk = state.board.disk(at: position)
                output += disk?.symbol ?? "-"
            }
            output += "\n"
        }

        // ファイルに書き込み
        do {
            try output.write(toFile: filePath, atomically: true, encoding: .utf8)
        } catch {
            throw GameRepositoryError.saveFailed(path: filePath, cause: error)
        }
    }

    /// ゲーム状態を読み込み
    /// - Returns: 読み込んだゲーム状態
    /// - Throws: 読み込みに失敗した場合
    public func loadGame() throws -> GameState {
        // ファイルから読み込み
        let content: String
        do {
            content = try String(contentsOfFile: filePath, encoding: .utf8)
        } catch {
            throw GameRepositoryError.loadFailed(path: filePath, cause: error)
        }

        // 行に分割
        var lines = content.split(separator: "\n").map { String($0) }

        // 最低限9行（ヘッダー + 盤面8行）必要
        guard lines.count >= 9 else {
            throw GameRepositoryError.invalidFormat(path: filePath)
        }

        // ヘッダー行を解析
        guard let headerLine = lines.first else {
            throw GameRepositoryError.invalidFormat(path: filePath)
        }
        lines.removeFirst()

        // ターンを解析
        guard let turnSymbol = headerLine.first else {
            throw GameRepositoryError.invalidFormat(path: filePath)
        }
        guard let currentTurn = Disk?(symbol: String(turnSymbol)) else {
            throw GameRepositoryError.invalidFormat(path: filePath)
        }

        // プレイヤーモードを解析
        let headerChars = Array(headerLine)
        guard headerChars.count >= 3 else {
            throw GameRepositoryError.invalidFormat(path: filePath)
        }

        let darkPlayerMode: PlayerMode
        let lightPlayerMode: PlayerMode

        if headerChars[1] == "0" {
            darkPlayerMode = .manual
        } else if headerChars[1] == "1" {
            darkPlayerMode = .computer
        } else {
            throw GameRepositoryError.invalidFormat(path: filePath)
        }

        if headerChars[2] == "0" {
            lightPlayerMode = .manual
        } else if headerChars[2] == "1" {
            lightPlayerMode = .computer
        } else {
            throw GameRepositoryError.invalidFormat(path: filePath)
        }

        // 盤面を解析
        guard lines.count == 8 else {
            throw GameRepositoryError.invalidFormat(path: filePath)
        }

        var board = Board()
        for y in 0..<8 {
            let line = lines[y]
            guard line.count == 8 else {
                throw GameRepositoryError.invalidFormat(path: filePath)
            }

            for (x, char) in line.enumerated() {
                let position = Position(x: x, y: y)
                guard let disk = Disk?(symbol: String(char)) else {
                    throw GameRepositoryError.invalidFormat(path: filePath)
                }
                board.setDisk(disk, at: position)
            }
        }

        // GameStateを構築
        return GameState(
            board: board,
            currentTurn: currentTurn,
            darkPlayerMode: darkPlayerMode,
            lightPlayerMode: lightPlayerMode
        )
    }
}
