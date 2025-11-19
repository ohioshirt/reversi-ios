import Foundation

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
                self.fileURL = documentDirectoryURL.appendingPathComponent("reversi.json")
                print("[GameRepository] Using documents directory: \(self.fileURL.path)")
            } else {
                // フォールバック: 一時ディレクトリを使用
                self.fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("reversi.json")
                print("[GameRepository] WARNING: Documents directory unavailable, falling back to temporary directory: \(self.fileURL.path)")
                print("[GameRepository] NOTE: Saved games in temporary directory may be deleted by the system.")
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
