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

## 🎯 目標アーキテクチャ: MVVM + Repository パターン

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

### レイヤーの責任

#### View Layer
- ユーザーインタラクションの受付
- ViewModelから受け取った状態の表示
- アニメーションの実装（表示のみ）

#### ViewModel Layer
- View用の状態管理
- ユーザーアクションの処理
- Domainレイヤーとの橋渡し
- UIロジック（アニメーション制御など）

#### Domain Layer
- ゲームのコアロジック（ビジネスルール）
- 純粋なSwiftコード（UIKit非依存）
- 完全にテスト可能

#### Repository Layer
- データの永続化・読み込み
- ファイルI/O、将来的にはCloudKit対応も可能

---

## 📝 リファクタリングステップ

### Phase 1: ドメインモデルの抽出 (テスト可能な基盤)

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

### Phase 5: 品質向上

#### Step 5.1: 統合テストの追加
- [ ] ゲームフロー全体のテスト
- [ ] UIテスト（XCUITest）の検討

#### Step 5.2: コードレビュー・最適化
- [ ] エッジケースの確認
- [ ] パフォーマンスチェック
- [ ] コードスタイルの統一

#### Step 5.3: ドキュメント更新
- [ ] README更新
- [ ] アーキテクチャドキュメント追加

---

## 📊 期待される効果

| 項目 | 現状 | 改善後 |
|------|------|--------|
| ViewController行数 | 573行 | ~150行 |
| テストカバレッジ | 0% | 80%以上 |
| ゲームロジックの再利用 | 不可 | 可能 |
| 新機能追加の容易性 | 困難 | 容易 |
| UIフレームワーク変更 | 不可能 | 可能（SwiftUI移行など） |

---

## 🔧 技術的な判断事項

### 使用する技術スタック

#### 状態管理
- **オプション1**: Combine フレームワーク
  - iOS 13+で標準
  - Reactiveなバインディング

- **オプション2**: クロージャベース（現状維持）
  - 依存なし
  - シンプル

→ **判断**: まずクロージャベースで実装、後でCombineへ移行可能な設計

#### 非同期処理
- **オプション1**: async/await (Swift 5.5+)
  - モダン、読みやすい

- **オプション2**: Completion handlers（現状維持）
  - 既存コードと一貫性

→ **判断**: async/awaitを採用（Computer思考処理に最適）

#### 依存性注入
- フレームワーク不使用
- シンプルなコンストラクタインジェクション

---

## 📅 実装の優先順位

### High Priority（コア機能）
1. Domain層の実装（GameEngine, Board）
2. ユニットテストの追加
3. GameViewModelの作成
4. ViewControllerのリファクタリング

### Medium Priority（品質向上）
5. Repositoryの分離
6. PlayerStrategyパターンの実装
7. 統合テスト

### Low Priority（将来的な拡張）
8. SwiftUI対応の検討
9. CloudKit対応
10. AI強化（Minimax法など）

---

## ✅ 成功基準

1. **すべてのユニットテストが成功**
2. **既存の機能がすべて動作**（リグレッションなし）
3. **ViewController が200行以下**
4. **テストカバレッジ 80%以上**
5. **新しいアーキテクチャがREADMEに文書化されている**

---

## 🚀 開始手順

```bash
# 1. 新しいブランチで作業開始
git checkout -b claude/refactor-architecture-plan-011CUQT6CpMfJG2179JYBc46

# 2. Phase 1 から順次実装
# - Domain/Models/ ディレクトリ作成
# - Domain/GameEngine.swift 作成
# - Tests/ にユニットテスト追加

# 3. 各Phaseごとにコミット
# 小さく確実に進める
```

---

作成日: 2025-10-23
対象プロジェクト: reversi-ios
対象ブランチ: claude/refactor-architecture-plan-011CUQT6CpMfJG2179JYBc46
