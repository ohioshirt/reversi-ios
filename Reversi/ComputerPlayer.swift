import Foundation

/// プレイヤー戦略のプロトコル
///
/// Computer プレイヤーの思考アルゴリズムを定義します。
/// 異なる戦略を実装することで、難易度の異なるComputer プレイヤーを作成できます。
protocol PlayerStrategy {
    /// 有効な手から次の手を選択します
    ///
    /// - Parameter validMoves: 有効な手の座標配列
    /// - Returns: 選択された手の座標。有効な手がない場合は `nil`
    func selectMove(from validMoves: [(x: Int, y: Int)]) -> (x: Int, y: Int)?

    /// Computerの思考時間（秒）
    var thinkingDelay: TimeInterval { get }
}

/// ランダムに手を選ぶシンプルなComputer戦略
///
/// 有効な手の中からランダムに1つを選択します。
/// これは最も単純な戦略で、初心者向けの難易度に適しています。
struct RandomComputerPlayer: PlayerStrategy {
    /// 思考時間は2秒
    let thinkingDelay: TimeInterval = 2.0

    /// 有効な手からランダムに1つを選択
    ///
    /// - Parameter validMoves: 有効な手の座標配列
    /// - Returns: ランダムに選択された座標。有効な手がない場合は `nil`
    func selectMove(from validMoves: [(x: Int, y: Int)]) -> (x: Int, y: Int)? {
        validMoves.randomElement()
    }
}

/// Computerプレイヤーの行動を管理するコントローラー
///
/// Computerプレイヤーの思考、手の選択、UI更新を管理します。
/// ViewControllerから分離することで、テスタビリティと再利用性を向上させます。
@MainActor
class ComputerPlayerController {
    // MARK: - Properties

    /// Computer戦略
    private let strategy: PlayerStrategy

    /// 各プレイヤーのキャンセラー（思考をキャンセルするため）
    private var playerCancellers: [Disk: Canceller] = [:]

    // MARK: - Initialization

    /// ComputerPlayerControllerを初期化します
    ///
    /// - Parameter strategy: 使用するComputer戦略（デフォルトはRandomComputerPlayer）
    init(strategy: PlayerStrategy = RandomComputerPlayer()) {
        self.strategy = strategy
    }

    // MARK: - Public Methods

    /// Computerのターンを実行（非同期）
    ///
    /// このメソッドは以下の処理を行います:
    /// 1. 思考開始のコールバックを実行（UI更新用）
    /// 2. 戦略に従って思考時間だけ待機
    /// 3. 戦略に従って手を選択
    /// 4. 思考終了のコールバックを実行（UI更新用）
    /// 5. 選択された手をcompletionに渡す
    ///
    /// - Parameters:
    ///   - disk: Computerが操作するディスク（黒または白）
    ///   - validMoves: 有効な手の座標配列
    ///   - onThinkingStart: 思考開始時に呼ばれるコールバック（UI更新用）
    ///   - onThinkingEnd: 思考終了時に呼ばれるコールバック（UI更新用）
    ///   - completion: 手の選択が完了した時に呼ばれるコールバック。
    ///                 選択された座標が渡されます。キャンセルされた場合は `nil`
    func playTurn(
        for disk: Disk,
        validMoves: [(x: Int, y: Int)],
        onThinkingStart: @escaping () -> Void,
        onThinkingEnd: @escaping () -> Void,
        completion: @escaping ((x: Int, y: Int)?) -> Void
    ) {
        // 戦略から手を選択
        guard let selectedMove = strategy.selectMove(from: validMoves) else {
            // 有効な手がない場合（通常は発生しないはず）
            completion(nil)
            return
        }

        // 思考開始（UI更新）
        onThinkingStart()

        // クリーンアップ処理
        let cleanUp: () -> Void = {
            onThinkingEnd()
            self.playerCancellers[disk] = nil
        }

        // Cancellerを作成
        let canceller = Canceller(cleanUp)
        playerCancellers[disk] = canceller

        // 思考時間だけ待機してから手を選択
        DispatchQueue.main.asyncAfter(deadline: .now() + strategy.thinkingDelay) {
            // キャンセルチェック
            if canceller.isCancelled {
                completion(nil)
                return
            }

            // クリーンアップ
            cleanUp()

            // 選択された手を返す
            completion(selectedMove)
        }
    }

    /// Computerの思考をキャンセルします
    ///
    /// 指定されたディスクのComputerプレイヤーの思考処理をキャンセルし、
    /// 関連するリソースをクリーンアップします。
    ///
    /// - Parameter disk: キャンセル対象のディスク（黒または白）
    func cancelTurn(for disk: Disk) {
        playerCancellers[disk]?.cancel()
        playerCancellers[disk] = nil
    }

    /// すべてのComputerプレイヤーの思考をキャンセルします
    ///
    /// 黒と白の両方のComputerプレイヤーの思考処理をキャンセルし、
    /// すべてのリソースをクリーンアップします。
    func cancelAllTurns() {
        for disk in Disk.sides {
            cancelTurn(for: disk)
        }
    }
}
