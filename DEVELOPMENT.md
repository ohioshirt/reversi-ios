# 開発ガイド

## 🏗️ アーキテクチャ

本プロジェクトは、**MVVM + Repository パターン**を採用し、最終的に**SwiftUI**への移行を目指しています。

詳細な計画は [REFACTORING_PLAN.md](REFACTORING_PLAN.md) を参照してください。

### 現在の実装状況

#### ✅ Phase 1 完了: Domain層の抽出（TDD）

**実装済みのコンポーネント:**

- **Domain/Models/**
  - `Position.swift` - 盤面座標の型安全な表現
  - `Board.swift` - 8x8盤面の状態管理

- **Domain/**
  - `GameEngine.swift` - リバーシのコアロジック
    - `validMoves(for:in:)` - 有効な手の検出
    - `canPlaceDisk(at:for:in:)` - 手の有効性チェック
    - `placeDisk(at:for:on:)` - ディスク配置と反転
    - `winner(in:)` - 勝者判定

**テストカバレッジ:**
- Domain Layer: **100%** (推定)
- テストコード: ~750行
- プロダクションコード: ~317行

---

## 🧪 テスト

### ローカルでのテスト実行

```bash
# すべてのテストを実行
xcodebuild test \
  -project Reversi.xcodeproj \
  -scheme Reversi \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# カバレッジ付きでテスト実行
xcodebuild test \
  -project Reversi.xcodeproj \
  -scheme Reversi \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES
```

### テスト戦略（t-wadaスタイル）

本プロジェクトは、和田卓人氏（@t_wada）が推奨するTDDベストプラクティスに従っています：

#### 1. AAA パターン (Arrange-Act-Assert)

```swift
func test_初期盤面_黒の有効な手が4つ() {
    // Arrange: テストに必要な前提条件を整える
    let board = Board.initial()

    // Act: テスト対象の動作を実行
    let validMoves = engine.validMoves(for: .dark, in: board)

    // Assert: 期待する結果を確認
    XCTAssertEqual(validMoves.count, 4, "黒の有効な手は4つ")
}
```

#### 2. Given-When-Then パターン

```swift
func test_角にディスクを配置_複数のディスクが反転される() {
    // Given: 特定の盤面状態
    var board = BoardBuilder()
        .place(.light, at: (1, 0))
        .place(.dark, at: (3, 0))
        .build()

    // When: ディスクを配置
    let flipped = engine.placeDisk(at: Position(x: 0, y: 0), for: .dark, on: &board)

    // Then: 期待する結果を確認
    XCTAssertEqual(flipped.count, 2, "2つのディスクが反転")
}
```

#### 3. テストケース命名規則

- **日本語テスト名を積極的に使用**（可読性向上）
- パターン: `test_[状態]_[動作]_[期待結果]()`
- 例:
  - `test_初期盤面_黒の有効な手が4つ()`
  - `test_角にディスクを配置_複数のディスクが反転される()`

#### 4. テストデータビルダーパターン

複雑な盤面を簡潔に構築するため、`BoardBuilder`を使用：

```swift
let board = BoardBuilder()
    .withInitialSetup()
    .place(.dark, at: (2, 3))
    .place(.light, at: (2, 4))
    .build()
```

#### 5. テストの独立性

```swift
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
}
```

---

## 🔄 CI/CD

### GitHub Actions

プッシュとプルリクエストごとに自動テストが実行されます。

**トリガー:**
- `main`ブランチへのプッシュ
- `claude/**`ブランチへのプッシュ
- `main`ブランチへのプルリクエスト

**実行内容:**
1. macOS 14 ランナーでXcodeビルド
2. iOSシミュレーター（iPhone 15）でテスト実行
3. コードカバレッジ計測
4. テスト結果とカバレッジレポートをアーティファクトとして保存

**ステータスバッジ:**

[![Tests](https://github.com/ohioshirt/reversi-ios/actions/workflows/test.yml/badge.svg)](https://github.com/ohioshirt/reversi-ios/actions/workflows/test.yml)

### カバレッジレポート

GitHub Actionsの各ジョブの「Summary」タブでカバレッジレポートを確認できます。

---

## 📝 コミット規約

### コミットメッセージのパターン

本プロジェクトでは、**TDDサイクル**に従ったコミットを推奨しています：

#### Red-Green-Refactor サイクル

1. **Red phase**: テストを先に書く
   ```
   Add [Feature] tests (Red phase)

   - Test case descriptions
   - Following t-wada TDD style
   - Tests currently fail as [Feature] is not yet implemented
   ```

2. **Green phase**: 最小限の実装でテストを通す
   ```
   Implement [Feature] (Green phase)

   - Implementation details
   - This implementation satisfies all tests
   - Next: [Next step]
   ```

3. **Refactor phase**: 必要に応じてリファクタリング
   ```
   Refactor [Component] for better [aspect]

   - Refactoring details
   - All tests still pass
   ```

### 例

```
Add Position struct tests (Red phase)

Following t-wada TDD style:
- AAA (Arrange-Act-Assert) pattern
- Japanese test names for clarity
- Comprehensive test coverage

Tests currently fail as Position is not yet implemented.
Next: Implement Position struct (Green phase)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## 🚀 次のステップ

### Phase 2: Application層の作成

- [ ] `GameState` struct の実装
- [ ] `PlayerStrategy` protocol の定義
- [ ] `GameViewModel` の作成（Combine使用）
- [ ] ViewModelのテスト

詳細は [REFACTORING_PLAN.md](REFACTORING_PLAN.md) を参照してください。

---

## 📚 参考資料

### アーキテクチャ
- Clean Architecture (Robert C. Martin)
- MVVM Pattern in iOS
- Protocol-Oriented Programming in Swift

### テスト
- テスト駆動開発（Kent Beck、和田卓人訳）
- 和田卓人氏のテスト設計手法
- XCTest Best Practices

### SwiftUI
- Apple SwiftUI Tutorials
- SwiftUI by Example (Paul Hudson)
- Thinking in SwiftUI (objc.io)

---

作成日: 2025-10-24
最終更新: 2025-10-24
