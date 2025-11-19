# Claude Code ガイドライン

このファイルは、Claude Codeがこのプロジェクトで作業する際の重要なルールと制約を定義します。

## 🚨 セキュリティルール（必須）

### 1. コミットメッセージでの @ 記号の禁止

**絶対にコミットメッセージ内で `@` 記号を使用しないでください。**

#### 理由
- GitHubでは `@` 記号がユーザーメンションとして解釈されます
- 無関係なユーザーに通知が送信される可能性があります
- これはセキュリティインシデントとみなされます

#### ❌ 禁止例
```
Bad commit message:
- "Add @Published property to ViewModel"
- "Implement @MainActor isolation"
- "Fix issue mentioned by @username"
- "@escaping クロージャを追加"
```

#### ✅ 正しい例
```
Good commit message:
- "Add Published property to ViewModel"
- "Implement MainActor isolation"
- "Add escaping closure"
- "[Published] プロパティをViewModelに追加"
```

#### 対処方法
Swift属性やアノテーションを記載する場合:
- `@Published` → `Published` または `[Published]`
- `@MainActor` → `MainActor` または `[MainActor]`
- `@State` → `State` または `[State]`
- `@Binding` → `Binding` または `[Binding]`
- `@escaping` → `escaping` または `[escaping]`

ユーザーメンションが必要な場合:
- コミットメッセージではなく、PRの本文やコメントで行う
- または、ユーザー名を引用符で囲む（例: "as suggested by 'username'"）

### 2. コミットメッセージの確認プロセス

コミット前に以下を確認:
1. `@` 記号が含まれていないか検索
2. Swift属性を記載する場合は代替表記を使用
3. 必要に応じて `git commit --amend` で修正

### 3. 過去のコミットの修正

もし `@` を含むコミットを作成してしまった場合:
```bash
# 最新のコミットを修正
git commit --amend -m "新しいメッセージ（@なし）"

# 強制プッシュ（まだプッシュしていない場合は不要）
git push --force-with-lease origin ブランチ名
```

---

## 📋 コミットメッセージ規約

### 一般的なルール
1. **簡潔で明確なタイトル**（50文字以内推奨）
2. **本文で詳細を説明**（72文字で改行）
3. **なぜ変更したか**を重視（何を変更したかは diff で分かるため）

### フォーマット
```
簡潔なタイトル

詳細な説明:
- 変更の理由
- 影響範囲
- 関連するissue番号

Generated with Claude Code (https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 日本語と英語
- タイトル: 英語を推奨（国際的なプロジェクトの場合）
- 本文: プロジェクトの主要言語に合わせる
- このプロジェクト: 日英混在可

---

## 🧪 テスト規約

### t-wada スタイル TDD
このプロジェクトは和田卓人氏のTDDスタイルに従います:

1. **AAA パターン必須**
   - Arrange (準備)
   - Act (実行)
   - Assert (検証)

2. **日本語テスト名を推奨**
   ```swift
   func test_初期盤面_黒の有効な手が4つ() {
       // テストコード
   }
   ```

3. **境界値テストを忘れずに**
   - 最小値、最大値
   - nil、空配列
   - エッジケース

---

## 📂 プロジェクト構成

### アーキテクチャ
- **MVVM + Repository パターン**
- **SwiftUI移行を目指す**

### レイヤー構成
```
Domain Layer (純粋なビジネスロジック)
├─ GameEngine.swift
├─ Board.swift
├─ Position.swift
└─ Disk.swift

Application Layer (状態管理)
├─ GameViewModel.swift
└─ GameState.swift

Repository Layer (永続化)
└─ GameRepository.swift

Presentation Layer (UI)
└─ ViewController.swift (UIKit) → SwiftUIへ移行予定
```

---

## 🚀 開発フロー

### Phase 5A: テスト整備 ✅ 完了
- 包括的なユニットテストスイート
- 1,745行、145+テストケース

### Phase 5B: ViewController リファクタリング（次のステップ）
- 587行 → 150行に削減
- アニメーション処理の分離
- Computer戦略の抽出

### Phase 6: SwiftUI 移行（最終目標）
- SwiftUI GameView の実装
- UIKit版との並行運用
- 完全移行

---

## ⚠️ 注意事項

### やってはいけないこと
1. ❌ コミットメッセージに `@` を使用
2. ❌ テストなしでの重要なリファクタリング
3. ❌ ドキュメントと実装の乖離を放置
4. ❌ UIKit依存コードをDomain層に混入

### やるべきこと
1. ✅ 変更前にテストを書く（TDD）
2. ✅ コミット前に `@` 記号をチェック
3. ✅ ドキュメントを常に最新に保つ
4. ✅ レイヤー分離を厳守

---

## 📞 問題が発生した場合

1. **セキュリティインシデント（@ メンション等）**
   - 即座にコミットを修正
   - force-with-lease で上書き
   - このドキュメントを参照

2. **テスト失敗**
   - CI/CDログを確認
   - ローカルで再現
   - 原因特定後に修正

3. **アーキテクチャ上の疑問**
   - DEVELOPMENT.md を参照
   - SWIFTUI_MIGRATION_ASSESSMENT.md を参照

---

**最終更新**: 2025-11-19
**作成者**: Claude (Sonnet 4.5)
**レビュー**: このドキュメントは人間のレビューを推奨
