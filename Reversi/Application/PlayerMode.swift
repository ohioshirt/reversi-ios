import Foundation

/// プレイヤーのモード
public enum PlayerMode: String, Codable, Equatable {
    /// 手動操作（ユーザーが操作）
    case manual

    /// コンピュータ（AIが自動操作）
    case computer
}
