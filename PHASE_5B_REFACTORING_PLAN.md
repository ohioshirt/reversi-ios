# Phase 5B: ViewControllerリファクタリング計画書

**作成日**: 2025-11-20
**目標**: ViewController を 587行 → 150行に削減 (74%削減)

---

## 現状分析

### ViewControllerの責務内訳 (587行)

| 責務 | 推定行数 | 主要なメソッド/プロパティ | 問題点 |
|-----|----------|------------------------|--------|
| **1. UI状態管理** | ~150行 | IBOutlet, updateCountLabels, updateMessageViews, syncBoardViewWithState | ViewControllerの本来の責務 (残すべき) |
| **2. アニメーション制御** | ~200行 | animateSettingDisks, animateSettingDisksAsync, animationCanceller | **分離対象**: AnimationController へ |
| **3. Computer戦略** | ~100行 | playTurnOfComputer, playerCancellers, 遅延処理 | **分離対象**: ComputerPlayer へ |
| **4. ゲームフロー制御** | ~100行 | waitForPlayer, continueGameFlow | **分離対象**: GameViewModel へ |
| **5. ViewModelバインディング** | ~37行 | setupBindings, Combineバインディング | ViewControllerの責務 (残すべき) |

---

## リファクタリング戦略

### Step 1: AnimationController の抽出 (推定削減: ~180行)

**目的**: アニメーション処理をViewControllerから分離し、再利用可能なコンポーネントにする

**新規ファイル**: `Reversi/Presentation/AnimationController.swift`

**インターフェース設計**:
```swift
/// アニメーション制御を担当するクラス
class AnimationController {
    private weak var boardView: BoardView?
    private var animationCanceller: Canceller?

    var isAnimating: Bool { animationCanceller != nil }

    init(boardView: BoardView) {
        self.boardView = boardView
    }

    /// 指定された座標に順次アニメーションでディスクを配置
    func animateSettingDisks<C: Collection>(
        at coordinates: C,
        to disk: Disk,
        completion: @escaping (Bool) -> Void
    ) where C.Element == (Int, Int)

    /// async/await版のアニメーション
    func animateSettingDisks<C: Collection>(
        at coordinates: C,
        to disk: Disk
    ) async -> Bool where C.Element == (Int, Int)

    /// すべてのアニメーションをキャンセル
    func cancelAllAnimations()
}
```

**ViewControllerへの影響**:
- `animateSettingDisks` メソッドを削除 (2つのバリアント)
- `animationCanceller` プロパティを削除
- `isAnimating` computed property を削除
- AnimationController を初期化して利用

**削減見込み**: ~180行

**テスト追加**: `AnimationControllerTests.swift` (推定100行)

---

### Step 2: ComputerPlayer の抽出 (推定削減: ~80行)

**目的**: Computer戦略を独立したコンポーネントにし、将来的に複数の戦略を実装可能にする

**新規ファイル**: `Reversi/Application/ComputerPlayer.swift`

**インターフェース設計**:
```swift
/// プレイヤー戦略のプロトコル
protocol PlayerStrategy {
    /// 有効な手から次の手を選択
    func selectMove(from validMoves: [(x: Int, y: Int)]) -> (x: Int, y: Int)?

    /// 思考時間（秒）
    var thinkingDelay: TimeInterval { get }
}

/// ランダムに手を選ぶシンプルなComputer戦略
class RandomComputerPlayer: PlayerStrategy {
    let thinkingDelay: TimeInterval = 2.0

    func selectMove(from validMoves: [(x: Int, y: Int)]) -> (x: Int, y: Int)? {
        validMoves.randomElement()
    }
}

/// Computer プレイヤーの行動を管理するコントローラー
class ComputerPlayerController {
    private let strategy: PlayerStrategy
    private var playerCancellers: [Disk: Canceller] = [:]

    init(strategy: PlayerStrategy = RandomComputerPlayer()) {
        self.strategy = strategy
    }

    /// Computerのターンを実行（非同期）
    func playTurn(
        for disk: Disk,
        validMoves: [(x: Int, y: Int)],
        onThinkingStart: @escaping () -> Void,
        onThinkingEnd: @escaping () -> Void,
        completion: @escaping ((x: Int, y: Int)?) -> Void
    )

    /// Computerの思考をキャンセル
    func cancelTurn(for disk: Disk)
}
```

**ViewControllerへの影響**:
- `playTurnOfComputer` メソッドを削除
- `playerCancellers` プロパティを削除
- ComputerPlayerController を初期化して利用

**削減見込み**: ~80行

**テスト追加**: `ComputerPlayerTests.swift` (推定80行)

---

### Step 3: ゲームフロー制御のViewModel移譲 (推定削減: ~100行)

**目的**: ゲームフロー制御をViewModelに集約し、ViewControllerをシンプルなView層にする

**変更ファイル**: `Reversi/Application/GameViewModel.swift`

**GameViewModelへの追加機能**:
```swift
extension GameViewModel {
    /// プレイヤーの行動を待つ（Computer/Manual判定を含む）
    func waitForPlayer(
        disk: Disk,
        mode: PlayerMode,
        onComputerTurn: @escaping () -> Void
    ) async

    /// ゲームフローを続ける
    func continueGameFlow(
        currentPlayerMode: PlayerMode,
        onComputerTurn: @escaping () -> Void
    ) async
}
```

**ViewControllerへの影響**:
- `waitForPlayer` メソッドを削除
- `continueGameFlow` メソッドを削除
- ゲームフロー制御をViewModelに委譲

**削減見込み**: ~100行

**テスト追加**: GameViewModelTests.swift に追加 (推定30行)

---

### Step 4: ViewControllerの最終構成 (目標: 150行)

**残すべき責務**:
1. **IBOutlet/IBAction管理** (~50行)
   - boardView, messageDiskView, messageLabel, playerControls, countLabels, playerActivityIndicators

2. **UI更新** (~50行)
   - updateCountLabels
   - updateMessageViews
   - syncBoardViewWithState

3. **ViewModelバインディング** (~30行)
   - setupBindings
   - Combineバインディング

4. **ボード操作のデリゲート** (~20行)
   - boardView(_:didSelectCellAtX:y:)
   - BoardViewDelegate準拠

---

## 実装順序とタイムライン

### Phase 1: AnimationController の抽出 (推定2-3日)

1. **AnimationController.swift を作成** (1日)
   - インターフェース実装
   - 既存のアニメーション処理を移植
   - Canceller管理

2. **AnimationControllerTests.swift を作成** (0.5日)
   - 基本的なアニメーション動作テスト
   - キャンセル処理テスト

3. **ViewControllerをリファクタリング** (0.5日)
   - AnimationController を初期化
   - アニメーション処理をAnimationControllerに委譲
   - 既存のメソッドを削除

4. **既存テストの実行と確認** (0.5日)
   - すべてのテストがパスすることを確認
   - リグレッションテスト

### Phase 2: ComputerPlayer の抽出 (推定1-2日)

1. **ComputerPlayer.swift を作成** (0.5日)
   - PlayerStrategy プロトコル定義
   - RandomComputerPlayer 実装
   - ComputerPlayerController 実装

2. **ComputerPlayerTests.swift を作成** (0.5日)
   - 戦略テスト
   - キャンセル処理テスト

3. **ViewControllerをリファクタリング** (0.5日)
   - ComputerPlayerController を初期化
   - playTurnOfComputer を ComputerPlayerController に委譲
   - 既存のメソッドを削除

4. **既存テストの実行と確認** (0.5日)

### Phase 3: ゲームフロー制御のViewModel移譲 (推定1日)

1. **GameViewModel.swift を拡張** (0.5日)
   - waitForPlayer メソッド追加
   - continueGameFlow メソッド追加

2. **GameViewModelTests.swift にテスト追加** (0.3日)

3. **ViewControllerをリファクタリング** (0.2日)
   - ゲームフロー制御をViewModelに委譲

### Phase 4: 最終確認とドキュメント更新 (推定0.5日)

1. **ViewControllerの行数確認** (587行 → 150行達成確認)
2. **すべてのテストを実行**
3. **SWIFTUI_MIGRATION_ASSESSMENT.md を更新**
4. **DEVELOPMENT.md を更新**

**総所要時間**: 推定4-6日

---

## リスク管理

### 高リスク項目

1. **アニメーション処理の分離**
   - リスク: アニメーション動作が変わる可能性
   - 対策: 詳細なテストケースを追加、手動テストで動作確認

2. **Computer戦略の分離**
   - リスク: ゲームフロー制御との結合が強い
   - 対策: 段階的にリファクタリング、各ステップでテスト実行

3. **ViewModelへの責務移譲**
   - リスク: ViewModelが肥大化する可能性
   - 対策: ViewModel内部でさらにレイヤー分離を検討

### 低リスク項目

- UI状態管理: ViewControllerの本来の責務なので変更不要
- Combineバインディング: 既にテストされており安全

---

## 成功基準

1. ✅ **ViewControllerの行数が150行以下** (74%削減達成)
2. ✅ **すべてのテストがパス** (リグレッションなし)
3. ✅ **コードカバレッジが80%以上を維持**
4. ✅ **アニメーション動作が既存と同じ** (手動テストで確認)
5. ✅ **Computer戦略が既存と同じ** (手動テストで確認)

---

## Phase 5B完了後の状態

### プロジェクト構成

```
Reversi/
├── Domain/
│   ├── GameEngine.swift (129行)
│   ├── Board.swift (52行)
│   ├── Position.swift (13行)
│   ├── Disk.swift (26行)
│
├── Application/
│   ├── GameViewModel.swift (126行 + ~50行追加)
│   ├── GameState.swift (46行)
│   ├── ComputerPlayer.swift (新規 ~150行)
│
├── Repository/
│   ├── GameRepository.swift (78行)
│
├── Presentation/
│   ├── ViewController.swift (150行) ← 587行から削減
│   ├── AnimationController.swift (新規 ~200行)
│   ├── BoardView.swift (176行)
│   ├── CellView.swift (139行)
│   ├── DiskView.swift (66行)
```

### テスト構成

```
ReversiTests/
├── GameEngineTests.swift (502行)
├── GameViewModelTests.swift (434行 + ~30行追加)
├── GameRepositoryTests.swift (347行)
├── ModelTests.swift (466行)
├── AnimationControllerTests.swift (新規 ~100行)
├── ComputerPlayerTests.swift (新規 ~80行)
```

**総テスト行数**: 1,749行 → ~1,959行 (12%増加)

---

## Phase 6 (SwiftUI移行) への準備

Phase 5B完了後、以下の利点が得られる:

1. ✅ **ViewControllerがシンプルになり、SwiftUI移行が容易**
2. ✅ **AnimationControllerがSwiftUIでも再利用可能** (若干の修正が必要)
3. ✅ **ComputerPlayerがUI層から完全に独立** (SwiftUIでもそのまま利用可能)
4. ✅ **GameViewModelがゲームフロー制御を担当** (SwiftUIのView層がさらにシンプルに)

---

**承認者**: _____________________
**承認日**: _____________________
