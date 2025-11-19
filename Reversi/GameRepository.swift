import Foundation
import os

/// ゲーム状態の永続化を担当するリポジトリプロトコル
public protocol GameRepository {
    /// ゲーム状態を保存
    func saveGame(_ state: GameState) throws

    /// ゲーム状態を読み込み
    func loadGame() throws -> GameState
}

/// ファイルベースのGameRepository実装
public class FileGameRepository: GameRepository {
    private let fileURL: URL
    private static let legacyFileName = "Game"
    private static let currentFileName = "reversi.json"
    private static let logger = Logger(subsystem: "com.example.reversi", category: "GameRepository")

    public init(fileURL: URL? = nil) {
        if let fileURL = fileURL {
            self.fileURL = fileURL
        } else {
            // デフォルトのファイルパス
            // ドキュメントディレクトリへのアクセスを試みる
            // 失敗した場合は一時ディレクトリを使用（サンドボックス制限等で失敗する可能性があるため）
            if let documentDirectoryURL = try? FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ) {
                self.fileURL = documentDirectoryURL.appendingPathComponent(Self.currentFileName)
                Self.logger.info("Using documents directory: \(self.fileURL.path)")

                // 後方互換性: 旧ファイル名からのマイグレーション
                Self.migrateLegacyFileIfNeeded(in: documentDirectoryURL)
            } else {
                // フォールバック: 一時ディレクトリを使用
                self.fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(Self.currentFileName)
                Self.logger.warning("Documents directory unavailable, falling back to temporary directory: \(self.fileURL.path)")
                Self.logger.info("Note: Saved games in temporary directory may be deleted by the system.")
            }
        }
    }

    /// 旧ファイル名("Game")から新ファイル名("reversi.json")へのマイグレーション
    private static func migrateLegacyFileIfNeeded(in directory: URL) {
        let legacyURL = directory.appendingPathComponent(legacyFileName)
        let currentURL = directory.appendingPathComponent(currentFileName)

        let fileManager = FileManager.default

        // 旧ファイルが存在し、新ファイルが存在しない場合のみマイグレーション
        if fileManager.fileExists(atPath: legacyURL.path) && !fileManager.fileExists(atPath: currentURL.path) {
            do {
                try fileManager.moveItem(at: legacyURL, to: currentURL)
                logger.info("Successfully migrated '\(legacyFileName)' to '\(currentFileName)'")
            } catch {
                logger.warning("Failed to migrate legacy file: \(error)")
            }
        }
    }

    public func saveGame(_ state: GameState) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(state)
        try data.write(to: fileURL, options: .atomic)
    }

    public func loadGame() throws -> GameState {
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        return try decoder.decode(GameState.self, from: data)
    }
}
