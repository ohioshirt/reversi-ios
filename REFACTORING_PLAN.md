# リファクタリング計画

## 📋 現状の問題点

### ViewController.swift (573行) の問題

1. **Fat View Controller**: すべてのロジックが1つのファイルに集約
   - ゲームルール、UI更新、アニメーション、保存処理が混在
   - テストが困難（UIと密結合）

2. **責任の分離不足**:
   - ビジネスロジック ↔ プレゼンテーション層が分離されていない
   - 状態管理が分散（`turn`, `isAnimating`, `playerCancellers`）

3. **再利用性の低さ**:
   - ゲームロジックの再利用不可
   - UIに依存したコード設計

4. **テストカバレッジ**: ユニットテストが実装されていない

---

## 🎯 目標アーキテクチャ: MVVM + Repository パターン → SwiftUI移行

### 中間目標: UIKit + MVVM
```
┌─────────────────────────────────────────┐
│          View Layer (UIKit)             │
│  ViewController, BoardView, CellView    │
└────────────┬────────────────────────────┘
             │ Binding
┌────────────▼────────────────────────────┐
│         ViewModel Layer                 │
│  GameViewModel (状態管理・UIロジック)    │
└────────────┬────────────────────────────┘
             │ Use Cases
┌────────────▼────────────────────────────┐
│        Domain Layer                     │
│  GameEngine (ゲームロジック・ルール)     │
│  Player, Board, GameState               │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│       Repository Layer                  │
│  GameRepository (保存・読み込み)         │
└─────────────────────────────────────────┘
```

### 最終目標: SwiftUI + MVVM
```
┌─────────────────────────────────────────┐
│       View Layer (SwiftUI)              │
│  GameView, BoardView, CellView          │
│  (Declarative UI with Previews)         │
└────────────┬────────────────────────────┘
             │ @Published / ObservableObject
┌────────────▼────────────────────────────┐
│   ViewModel Layer (ObservableObject)    │
│  GameViewModel (状態管理・UIロジック)    │
│  @Published properties                  │
└────────────┬────────────────────────────┘
             │ Use Cases
┌────────────▼────────────────────────────┐
│        Domain Layer                     │
│  GameEngine (ゲームロジック・ルール)     │
│  Player, Board, GameState               │
│  ※ UIKit版と同一コード                  │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│       Repository Layer                  │
│  GameRepository (保存・読み込み)         │
│  ※ UIKit版と同一コード                  │
└─────────────────────────────────────────┘
```

### レイヤーの責任

#### View Layer
- **UIKit版**: ユーザーインタラクションの受付、ViewModelから受け取った状態の表示、アニメーションの実装
- **SwiftUI版**: 宣言的UI、ViewModelの@Published監視、自動UI更新、Previewsによる開発効率向上

#### ViewModel Layer
- View用の状態管理（UIKit: クロージャ/Combine、SwiftUI: ObservableObject + @Published）
- ユーザーアクションの処理
- Domainレイヤーとの橋渡し
- UIロジック（アニメーション制御など）
- **重要**: UIフレームワーク非依存（UIKit/SwiftUI両対応）

#### Domain Layer
- ゲームのコアロジック（ビジネスルール）
- 純粋なSwiftコード（UIKit/SwiftUI非依存）
- 完全にテスト可能
- **UIKit版とSwiftUI版で100%共有**

#### Repository Layer
- データの永続化・読み込み
- ファイルI/O、将来的にはCloudKit対応も可能
- **UIKit版とSwiftUI版で100%共有**

---

## 🧪 テスト戦略（t-wadaスタイル）

### テスト設計原則

本リファクタリングでは、和田卓人氏（@t_wada）が推奨するテスト駆動開発のベストプラクティスに従います。

#### 1. テストケースの構造: AAA パターン

```swift
func test_特定の状態での動作を検証() {
    // Arrange (準備): テストに必要な前提条件を整える
    let board = Board()
    let engine = GameEngine(board: board)

    // Act (実行): テスト対象の動作を実行
    let result = engine.canPlaceDisk(at: Position(x: 2, y: 3), for: .dark)

    // Assert (検証): 期待する結果を確認
    XCTAssertTrue(result, "初期配置から1手目は(2,3)に置ける")
}
```

#### 2. Given-When-Then による可読性向上

```swift
func test_角にディスクを置いた場合_反転されるディスクが正しく計算される() {
    // Given: 特定の盤面状態
    let board = BoardBuilder()
        .place(.dark, at: (0, 0))
        .place(.light, at: (1, 0))
        .place(.light, at: (2, 0))
        .build()

    // When: 角の隣にディスクを置く
    let flipped = engine.placeDisk(at: Position(x: 3, y: 0), for: .dark)

    // Then: 挟まれたディスクが反転される
    XCTAssertEqual(flipped.count, 2)
    XCTAssertTrue(flipped.contains(Position(x: 1, y: 0)))
    XCTAssertTrue(flipped.contains(Position(x: 2, y: 0)))
}
```

#### 3. テストケース命名規則

- **動作を明確に表現**: `test_[状態]_[動作]_[期待結果]()`
- **日本語も許容**: 可読性が向上する場合は積極的に使用
- **例**:
  - `test_空の盤面_初期配置_中央に4つのディスクが配置される()`
  - `test_有効な手がない場合_ターンスキップ_次のプレイヤーに移る()`
  - `test_両プレイヤーとも手がない場合_ゲーム終了_勝者が決定される()`

#### 4. 1テストケース1アサーション（柔軟適用）

- **基本**: 1つのテストで1つの概念を検証
- **例外**: 関連する複数のアサーションは許容（同じ関心事の場合）

```swift
// 良い例: 初期状態の検証（関連するアサーション）
func test_ゲーム開始時の初期状態() {
    let state = GameState.initial()

    XCTAssertEqual(state.currentTurn, .dark, "先手は黒")
    XCTAssertEqual(state.darkDiskCount, 2, "黒は2個")
    XCTAssertEqual(state.lightDiskCount, 2, "白は2個")
}

// 悪い例: 異なる関心事を1つのテストに詰め込む（分割すべき）
func test_ゲーム全体の動作() { // ❌
    // ゲーム開始 + ディスク配置 + 勝敗判定を1つのテストで
}
```

#### 5. テストデータビルダーパターン

複雑な盤面状態を簡潔に構築するため、Builderパターンを活用：

```swift
final class BoardBuilder {
    private var disks: [Position: Disk] = [:]

    func place(_ disk: Disk, at position: (Int, Int)) -> BoardBuilder {
        disks[Position(x: position.0, y: position.1)] = disk
        return self
    }

    func withInitialSetup() -> BoardBuilder {
        return self
            .place(.light, at: (3, 3))
            .place(.dark, at: (4, 3))
            .place(.dark, at: (3, 4))
            .place(.light, at: (4, 4))
    }

    func build() -> Board {
        var board = Board()
        for (position, disk) in disks {
            board.setDisk(disk, at: position)
        }
        return board
    }
}

// 使用例
let board = BoardBuilder()
    .withInitialSetup()
    .place(.dark, at: (2, 3))
    .build()
```

#### 6. テストの独立性

- 各テストは他のテストに依存しない
- `setUp()` / `tearDown()` で共通の前処理・後処理
- テスト実行順序に依存しない設計

```swift
final class GameEngineTests: XCTestCase {
    var engine: GameEngine!
    var board: Board!

    override func setUp() {
        super.setUp()
        board = Board()
        engine = GameEngine(board: board)
    }

    override func tearDown() {
        engine = nil
        board = nil
        super.tearDown()
    }

    func test_各テストは独立して実行可能() {
        // このテストは他のテストの影響を受けない
    }
}
```

#### 7. エッジケースの網羅

リバーシ特有のエッジケースを必ずテスト：

- **角の配置**: (0,0), (0,7), (7,0), (7,7)
- **端の配置**: x=0, x=7, y=0, y=7
- **8方向すべての反転**: 上下左右、斜め4方向
- **反転なし**: 挟めないケース
- **複数方向同時反転**: 1手で複数方向にディスクを挟む
- **パス**: 有効な手がない場合
- **ゲーム終了**: 両者とも手がない、または盤面が埋まる

#### 8. テストカバレッジ目標

- **Domain Layer**: 100%（ビジネスロジックは完全カバー）
- **ViewModel Layer**: 90%以上
- **Repository Layer**: 90%以上
- **View Layer**: UIテストで主要フローをカバー

---

## 📝 リファクタリングステップ

### Phase 1: ドメインモデルの抽出 (TDD: Test-Driven Development)

#### Step 1.1: 基本モデルの作成
- [ ] `Position` struct の作成（x, y座標の型安全性）
- [ ] `Board` モデルの作成
  - 8x8盤面の状態管理
  - `getDisk(at:)`, `setDisk(_:at:)` メソッド
  - Equatable, Codable 対応

#### Step 1.2: GameEngine の作成
- [ ] `GameEngine` クラスの実装
  - `canPlaceDisk(at:for:) -> Bool`
  - `validMoves(for:) -> [Position]`
  - `placeDisk(at:for:) -> [Position]` (反転座標を返す)
  - `countDisks(of:) -> Int`
  - `winner() -> Disk?`

#### Step 1.3: ユニットテストの追加
- [ ] GameEngineのテスト
  - 各方向の反転ロジック検証
  - エッジケース（角、端）の検証
  - 無効な手の検証
- [ ] Boardのテスト

---

### Phase 2: アプリケーション層の作成

#### Step 2.1: GameState の定義
- [ ] `GameState` struct の作成
  - 現在のターン（`Disk?`）
  - プレイヤーモード（Manual/Computer）
  - 盤面状態（`Board`）
  - Immutable設計

#### Step 2.2: PlayerStrategy パターンの導入
- [ ] `PlayerStrategy` protocol の定義
  - `func selectMove(in board: Board, for side: Disk) async -> Position?`
- [ ] `ManualStrategy` の実装（UI入力待ち）
- [ ] `ComputerStrategy` の実装（AIロジック）

#### Step 2.3: GameViewModel の作成
- [ ] `GameViewModel` クラスの実装
  - Observable プロパティ（Combine or Closure-based）
  - `placeDisk(at:)`, `reset()`, `togglePlayerMode()` アクション
  - アニメーション制御の集約
  - 非同期処理の管理（Computer思考中など）

#### Step 2.4: ViewModelのテスト
- [ ] GameViewModelのユニットテスト
  - 状態遷移のテスト
  - プレイヤーモード切り替えのテスト

---

### Phase 3: 永続化層の分離

#### Step 3.1: GameRepository の作成
- [ ] `GameRepository` protocol の定義
- [ ] `FileGameRepository` の実装
  - `saveGame(_ state: GameState) throws`
  - `loadGame() throws -> GameState`
  - 既存のファイルフォーマット互換性維持

#### Step 3.2: Repositoryのテスト
- [ ] 保存・読み込みのテスト
- [ ] エラーハンドリングのテスト

---

### Phase 4: View層のリファクタリング

#### Step 4.1: ViewControllerのスリム化
- [ ] ViewModelへの依存注入
- [ ] ビジネスロジックをViewModelへ移動
- [ ] UIイベントハンドリングのみに集中
- [ ] 目標: 573行 → ~150行

#### Step 4.2: バインディング実装
- [ ] GameViewModel ↔ ViewController の接続
- [ ] 状態変更の自動UI反映
- [ ] KVO or Combine or クロージャベース

#### Step 4.3: 既存Viewコンポーネントの活用
- [ ] BoardView, CellView, DiskView はそのまま活用
- [ ] 必要に応じて軽微なリファクタリング

---

### Phase 5: 品質向上（UIKit版の完成）

#### Step 5.1: 統合テストの追加
- [ ] ゲームフロー全体のテスト
- [ ] UIテスト（XCUITest）の検討

#### Step 5.2: コードレビュー・最適化
- [ ] エッジケースの確認
- [ ] パフォーマンスチェック
- [ ] コードスタイルの統一

#### Step 5.3: ドキュメント更新
- [ ] README更新（UIKit版アーキテクチャ）
- [ ] アーキテクチャドキュメント追加

---

### Phase 6: SwiftUI移行（最終目標）

#### Step 6.1: ViewModelのSwiftUI対応

- [ ] `GameViewModel` を `ObservableObject` に準拠
  ```swift
  final class GameViewModel: ObservableObject {
      @Published var board: Board
      @Published var currentTurn: Disk?
      @Published var darkDiskCount: Int
      @Published var lightDiskCount: Int
      @Published var isAnimating: Bool
      @Published var playerModes: [Disk: PlayerMode]

      // Domain/Repositoryレイヤーは変更なし
      private let engine: GameEngine
      private let repository: GameRepository
  }
  ```

- [ ] Combineを使った非同期処理の整理
  - `async/await` → `@MainActor` での状態更新
  - Computer思考処理のPublisher化

#### Step 6.2: SwiftUI View の作成

- [ ] `GameView` (メイン画面)
  ```swift
  struct GameView: View {
      @StateObject var viewModel: GameViewModel

      var body: some View {
          VStack {
              BoardView(board: viewModel.board,
                       onCellTap: viewModel.placeDisk)
              StatusView(turn: viewModel.currentTurn,
                        darkCount: viewModel.darkDiskCount,
                        lightCount: viewModel.lightDiskCount)
              PlayerControlsView(modes: viewModel.playerModes,
                                onModeChange: viewModel.togglePlayerMode)
          }
      }
  }
  ```

- [ ] `BoardView` (SwiftUI版)
  ```swift
  struct BoardView: View {
      let board: Board
      let onCellTap: (Position) -> Void

      var body: some View {
          LazyVGrid(columns: Array(repeating: GridItem(), count: 8)) {
              ForEach(0..<64) { index in
                  CellView(disk: board[index],
                          position: Position(index: index),
                          onTap: onCellTap)
              }
          }
      }
  }
  ```

- [ ] `CellView` (SwiftUI版)
  ```swift
  struct CellView: View {
      let disk: Disk?
      let position: Position
      let onTap: (Position) -> Void

      var body: some View {
          ZStack {
              Rectangle()
                  .fill(Color.cellColor)
              if let disk = disk {
                  DiskView(disk: disk)
                      .transition(.scale.combined(with: .opacity))
              }
          }
          .onTapGesture { onTap(position) }
      }
  }
  ```

- [ ] `DiskView` (SwiftUI版)
  ```swift
  struct DiskView: View {
      let disk: Disk

      var body: some View {
          Circle()
              .fill(disk == .dark ? Color.darkColor : Color.lightColor)
              .padding(4)
      }
  }
  ```

#### Step 6.3: アニメーションの実装

- [ ] SwiftUIのアニメーション機能を活用
  ```swift
  // ViewModelで状態変更時にアニメーション
  func placeDisk(at position: Position) {
      withAnimation(.easeInOut(duration: 0.25)) {
          // ディスク配置とフリップ
          board.setDisk(currentTurn, at: position)
          // 反転処理
          let flipped = engine.placeDisk(at: position, for: currentTurn!)
          for pos in flipped {
              board.flipDisk(at: pos)
          }
      }
  }
  ```

- [ ] カスタムトランジション
  - ディスク出現: `.scale` + `.opacity`
  - ディスク反転: `.rotation3D` 効果

#### Step 6.4: SwiftUI Previews の活用

- [ ] 各Viewに `PreviewProvider` を実装
  ```swift
  struct BoardView_Previews: PreviewProvider {
      static var previews: some View {
          Group {
              // 初期状態
              BoardView(board: Board.initial(), onCellTap: { _ in })
                  .previewDisplayName("初期状態")

              // ゲーム途中
              BoardView(board: BoardBuilder()
                  .withInitialSetup()
                  .place(.dark, at: (2, 3))
                  .build(),
                  onCellTap: { _ in })
                  .previewDisplayName("ゲーム途中")

              // ダークモード
              BoardView(board: Board.initial(), onCellTap: { _ in })
                  .preferredColorScheme(.dark)
                  .previewDisplayName("ダークモード")
          }
      }
  }
  ```

- [ ] ViewModelのPreview用モック
  ```swift
  extension GameViewModel {
      static var preview: GameViewModel {
          let vm = GameViewModel(
              engine: GameEngine(),
              repository: InMemoryGameRepository()
          )
          return vm
      }
  }
  ```

#### Step 6.5: UIKitとSwiftUIの共存期間

- [ ] `UIHostingController` でSwiftUI Viewを埋め込み
  ```swift
  // 段階的移行: 一部の画面だけSwiftUI化
  let swiftUIView = GameView(viewModel: viewModel)
  let hostingController = UIHostingController(rootView: swiftUIView)
  ```

- [ ] フィーチャーフラグでUIKit/SwiftUIを切り替え
  ```swift
  enum UIFramework {
      case uikit, swiftui
  }

  let currentFramework: UIFramework = .swiftui // 切り替え可能
  ```

#### Step 6.6: SwiftUI版のテスト

- [ ] ViewModelのテスト（UIKit版と同じテストが流用可能）
- [ ] SwiftUI PreviewSnapshotテスト（オプション）
  - `swift-snapshot-testing` ライブラリの検討

#### Step 6.7: 最終移行とUIKit版の削除

- [ ] すべての画面をSwiftUI化
- [ ] UIKit版のViewController, Storyboard削除
- [ ] SceneDelegate の簡素化
  ```swift
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
      guard let windowScene = (scene as? UIWindowScene) else { return }

      let viewModel = GameViewModel(
          engine: GameEngine(),
          repository: FileGameRepository()
      )

      let contentView = GameView(viewModel: viewModel)
      let window = UIWindow(windowScene: windowScene)
      window.rootViewController = UIHostingController(rootView: contentView)
      self.window = window
      window.makeKeyAndVisible()
  }
  ```

- [ ] iOS Deployment Target の見直し（SwiftUIの最小要件確認）

---

## 📊 期待される効果

### Phase 5完了時点（UIKit + MVVM）

| 項目 | 現状 | Phase 5完了後 |
|------|------|---------------|
| ViewController行数 | 573行 | ~150行（74%削減） |
| テストカバレッジ | 0% | 80%以上 |
| ゲームロジックの再利用 | 不可 | 可能 |
| 新機能追加の容易性 | 困難 | 容易 |
| UIフレームワーク変更 | 不可能 | 可能 |

### Phase 6完了時点（SwiftUI + MVVM）

| 項目 | Phase 5完了後 | Phase 6完了後（最終） |
|------|--------------|----------------------|
| View層のコード量 | ~150行 | ~100行（SwiftUIの宣言的記述） |
| UI開発効率 | 標準 | 大幅向上（Previewsで即座に確認） |
| アニメーション実装 | UIKit API | SwiftUI宣言的アニメーション |
| ダークモード対応 | 手動実装 | 自動対応（@Environment） |
| Storyboard | あり | 不要（コードベースUI） |
| UI保守性 | 改善 | 大幅改善（型安全、コンパイル時チェック） |
| 開発体験 | 良い | 最高（Hot Reload、Live Preview） |

---

## 🔧 技術的な判断事項

### 使用する技術スタック

#### 状態管理
- **Phase 1-4（UIKit版）**: Combineフレームワーク
  - iOS 13+で標準
  - SwiftUI移行を見据えた設計
  - `@Published` を使ったリアクティブな状態管理

- **Phase 6（SwiftUI版）**: Combine + SwiftUI
  - `ObservableObject` + `@Published`
  - UIKit版のViewModelをそのまま活用可能

→ **判断**: 最初からCombineを採用し、SwiftUI移行をスムーズに

#### 非同期処理
- **async/await (Swift 5.5+)**
  - モダンで読みやすい
  - Computer思考処理に最適
  - `@MainActor` でUI更新を安全に

→ **判断**: async/awaitを全面採用

#### UIフレームワーク移行戦略
- **Phase 1-5**: UIKit + Storyboard
  - 既存コードベースを活かす
  - 段階的リファクタリング

- **Phase 6**: SwiftUI
  - Domain/ViewModel/Repositoryレイヤーは変更なし
  - View層のみ差し替え
  - UIKitと一時的に共存可能

→ **判断**: UIKit版完成後、SwiftUIへ段階的移行

#### 依存性注入
- フレームワーク不使用
- シンプルなコンストラクタインジェクション
- Protocol-oriented design でテスタビリティ確保

---

## 📅 実装の優先順位とロードマップ

### 🎯 Phase 1-5: UIKit版リファクタリング（必須）

#### Phase 1: Domain層（High Priority）
1. Position, Board, GameEngine の実装
2. ユニットテストの充実（TDD）
3. テストカバレッジ 100%達成

#### Phase 2: Application層（High Priority）
4. GameViewModel の作成（Combine使用）
5. PlayerStrategy パターンの実装
6. ViewModelのテスト

#### Phase 3: Repository層（Medium Priority）
7. GameRepository の分離
8. ファイルI/O処理の抽出

#### Phase 4: View層リファクタリング（High Priority）
9. ViewController のスリム化（573→150行）
10. Combineバインディングの実装

#### Phase 5: 品質向上（Medium Priority）
11. 統合テストの追加
12. コードレビュー・最適化
13. ドキュメント整備

### 🚀 Phase 6: SwiftUI移行（最終目標・High Priority）

14. ViewModelのObservableObject対応
15. SwiftUI View の実装
16. SwiftUI Previews の活用
17. UIKitとの共存期間
18. 完全移行とUIKit版削除

### 🔮 将来的な拡張（Low Priority）

- CloudKit対応（オンライン対戦）
- AI強化（Minimax法、アルファベータ枝刈り）
- マルチプレイヤー対応
- リプレイ機能
- 棋譜保存・読み込み

---

## ✅ 成功基準

### Phase 5完了時点（UIKit版）

1. **すべてのユニットテストが成功**（グリーン）
2. **既存の機能がすべて動作**（リグレッションなし）
3. **ViewController が200行以下**（目標: 150行）
4. **テストカバレッジ 80%以上**
   - Domain Layer: 100%
   - ViewModel Layer: 90%以上
   - Repository Layer: 90%以上
5. **新しいアーキテクチャがREADMEに文書化されている**

### Phase 6完了時点（SwiftUI版・最終）

6. **SwiftUI版がUIKit版と完全に同じ動作をする**
7. **SwiftUI Previews がすべてのViewで動作**
8. **Domain/ViewModel/Repositoryレイヤーのコードが変更されていない**（View層のみ差し替え）
9. **Storyboardが削除されている**（完全なコードベースUI）
10. **アニメーションが自然で美しい**（SwiftUI標準のトランジション活用）
11. **ダークモード対応が完了**（SwiftUI標準で自動対応）
12. **ViewModelのテストがすべて成功**（UIKit版のテストをそのまま流用）

---

## 🚀 開始手順

```bash
# 1. ブランチ確認
git branch  # claude/refactor-architecture-plan-011CUQT6CpMfJG2179JYBc46 で作業

# 2. Phase 1 から順次実装（TDD: テストファースト）
# Step 1: テストを書く
mkdir -p ReversiTests/Domain
# Step 2: テストが失敗することを確認（Red）
# Step 3: 最小限の実装でテストを通す（Green）
# Step 4: リファクタリング（Refactor）

# 3. 各Phaseごとにコミット
# 小さく確実に進める（Git Atomic Commits）

# 4. Phase 6でSwiftUI移行
# UIKitとSwiftUIを共存させながら段階的移行
```

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

## 📝 メタデータ

- **作成日**: 2025-10-24
- **最終更新**: 2025-10-24
- **対象プロジェクト**: reversi-ios
- **対象ブランチ**: `claude/refactor-architecture-plan-011CUQT6CpMfJG2179JYBc46`
- **最終目標**: **UIKit → MVVM → SwiftUI への完全移行**
- **テスト戦略**: **t-wadaスタイル（AAA、Given-When-Then、TDD）**
