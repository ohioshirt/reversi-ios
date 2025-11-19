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
            let documentDirectoryURL = (try? FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )) ?? FileManager.default.temporaryDirectory

            self.fileURL = documentDirectoryURL.appendingPathComponent("reversi.json")
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
