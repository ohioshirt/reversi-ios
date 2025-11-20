import UIKit

/// アニメーションのキャンセル処理を管理するクラス
final class Canceller {
    private(set) var isCancelled: Bool = false
    private let body: (() -> Void)?

    init(_ body: (() -> Void)?) {
        self.body = body
    }

    func cancel() {
        if isCancelled { return }
        isCancelled = true
        body?()
    }
}

/// アニメーション制御を担当するクラス
///
/// ViewControllerからアニメーション処理を分離し、
/// 再利用可能なコンポーネントとして提供します。
///
/// 主な責務:
/// - BoardViewへのディスク配置アニメーション
/// - アニメーションのキャンセル管理
/// - 複数ディスクの順次アニメーション
@MainActor
class AnimationController {
    // MARK: - Properties

    /// アニメーション対象のBoardView（weak参照でメモリリークを防ぐ）
    private weak var boardView: BoardView?

    /// 現在実行中のアニメーションのキャンセラー
    private var animationCanceller: Canceller?

    /// アニメーションが実行中かどうか
    var isAnimating: Bool {
        animationCanceller != nil
    }

    // MARK: - Initialization

    /// AnimationControllerを初期化します
    ///
    /// - Parameter boardView: アニメーション対象のBoardView
    init(boardView: BoardView) {
        self.boardView = boardView
    }

    // MARK: - Public Methods

    /// 指定された座標に順次アニメーションでディスクを配置（async/await版）
    ///
    /// このメソッドは `animateSettingDisks(completion:)` のasyncラッパーで、
    /// コールバックベースのAPIをasync/awaitスタイルに変換します。
    ///
    /// - Parameters:
    ///   - coordinates: ディスクを置くセルの座標のコレクション
    ///   - disk: 配置するディスク
    /// - Returns: すべてのアニメーションが正常に完了した場合は `true`、キャンセルされた場合は `false`
    func animateSettingDisks<C: Collection>(
        at coordinates: C,
        to disk: Disk
    ) async -> Bool where C.Element == (Int, Int) {
        await withCheckedContinuation { continuation in
            animateSettingDisks(at: coordinates, to: disk) { completed in
                continuation.resume(returning: completed)
            }
        }
    }

    /// 指定された座標に順次アニメーションでディスクを配置（コールバック版）
    ///
    /// `coordinates` から先頭の座標を取得してそのセルに `disk` を置き、
    /// 残りの座標についてこのメソッドを再帰呼び出しすることで処理が行われます。
    /// すべてのセルに `disk` が置けたら `completion` ハンドラーが呼び出されます。
    ///
    /// - Parameters:
    ///   - coordinates: ディスクを置くセルの座標のコレクション
    ///   - disk: 配置するディスク
    ///   - completion: アニメーション完了時に呼ばれるハンドラー。
    ///                 すべてのアニメーションが完了した場合は `true`、
    ///                 途中でキャンセルまたは失敗した場合は `false` が渡されます。
    func animateSettingDisks<C: Collection>(
        at coordinates: C,
        to disk: Disk,
        completion: @escaping (Bool) -> Void
    ) where C.Element == (Int, Int) {
        // 既にアニメーションが実行中の場合は、新しいCancellerを作成
        let cleanUp: () -> Void = { [weak self] in
            self?.animationCanceller = nil
        }
        animationCanceller = Canceller(cleanUp)

        // 実際のアニメーション処理を開始
        performAnimation(at: coordinates, to: disk, completion: completion)
    }

    /// すべてのアニメーションをキャンセルします
    ///
    /// 実行中のアニメーションがある場合、それをキャンセルし、
    /// 関連するリソースをクリーンアップします。
    func cancelAllAnimations() {
        animationCanceller?.cancel()
        animationCanceller = nil
    }

    // MARK: - Private Methods

    /// アニメーションの実際の実行処理（再帰的に呼び出される）
    ///
    /// - Parameters:
    ///   - coordinates: ディスクを置くセルの座標のコレクション
    ///   - disk: 配置するディスク
    ///   - completion: アニメーション完了時に呼ばれるハンドラー
    private func performAnimation<C: Collection>(
        at coordinates: C,
        to disk: Disk,
        completion: @escaping (Bool) -> Void
    ) where C.Element == (Int, Int) {
        // 座標が空の場合は成功として完了
        guard let (x, y) = coordinates.first else {
            completion(true)
            return
        }

        // BoardViewが解放されている場合は失敗として完了
        guard let boardView = boardView else {
            completion(false)
            return
        }

        // アニメーションがキャンセルされていないかチェック
        guard let animationCanceller = animationCanceller else {
            completion(false)
            return
        }

        // BoardViewにディスクを配置（アニメーション付き）
        boardView.setDisk(disk, atX: x, y: y, animated: true) { [weak self] isFinished in
            guard let self = self else { return }

            // キャンセルチェック
            if animationCanceller.isCancelled { return }

            if isFinished {
                // 次の座標へ再帰的にアニメーション
                self.performAnimation(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                // アニメーションが中断された場合、残りのディスクを即座に配置
                for (x, y) in coordinates {
                    boardView.setDisk(disk, atX: x, y: y, animated: false)
                }
                completion(false)
            }
        }
    }
}
