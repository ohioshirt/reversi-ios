import SwiftUI

/// SwiftUI版のリバーシゲームのメインビュー
struct GameView: View {
    /// ゲームのViewModel
    @StateObject private var viewModel: GameViewModel

    /// リポジトリ
    private let repository: GameRepository

    /// アニメーションコントローラー
    @StateObject private var animationController: AnimationController

    /// コンピュータープレイヤーコントローラー
    @StateObject private var computerPlayerController: ComputerPlayerController

    /// パスアラートの表示状態
    @State private var showPassAlert = false
    @State private var passedPlayer: Disk?

    init(
        viewModel: GameViewModel? = nil,
        repository: GameRepository = FileGameRepository()
    ) {
        let vm = viewModel ?? GameViewModel(engine: GameEngine())
        _viewModel = StateObject(wrappedValue: vm)
        self.repository = repository

        // AnimationControllerの初期化
        _animationController = StateObject(wrappedValue: AnimationController())

        // ComputerPlayerControllerの初期化
        let strategy = RandomComputerPlayer()
        _computerPlayerController = StateObject(wrappedValue: ComputerPlayerController(strategy: strategy))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ゲーム状態表示エリア
                GameStatusView(viewModel: viewModel)
                    .padding(.vertical, 8)

                // ボード
                BoardGridView(
                    board: viewModel.state.board,
                    currentTurn: viewModel.state.currentTurn,
                    viewModel: viewModel,
                    animationController: animationController
                )
                .aspectRatio(1.0, contentMode: .fit)
                .padding()

                // コントロールエリア
                GameControlsView(
                    viewModel: viewModel,
                    repository: repository
                )
                .padding(.vertical, 8)
            }
            .navigationTitle("Reversi")
            .navigationBarTitleDisplayMode(.inline)
            .alert(
                passedPlayer == .dark ? "Black passed" : "White passed",
                isPresented: $showPassAlert
            ) {
                Button("Dismiss") {
                    showPassAlert = false
                }
            }
            .task {
                // パスイベントの監視
                for await passEvent in viewModel.passEvent.values {
                    passedPlayer = passEvent.passedPlayer
                    showPassAlert = true
                }
            }
            .task {
                // ゲームフローの管理
                await manageGameFlow()
            }
        }
        .navigationViewStyle(.stack)
    }

    /// ゲームフローを管理
    @MainActor
    private func manageGameFlow() async {
        while true {
            guard let currentTurn = viewModel.state.currentTurn else {
                // ゲーム終了
                await Task.yield()
                continue
            }

            let playerMode = viewModel.state.playerMode(for: currentTurn)

            if playerMode == .computer {
                // コンピューターのターン
                await playComputerTurn(for: currentTurn)
            }

            // 次のループまで待機
            await Task.yield()
        }
    }

    /// コンピューターのターンをプレイ
    @MainActor
    private func playComputerTurn(for disk: Disk) async {
        let validMoves = viewModel.validMoves(for: disk)
        guard !validMoves.isEmpty else { return }

        // コンピューターの手を選択
        guard let position = await computerPlayerController.selectMove(
            validMoves: validMoves,
            for: disk,
            on: viewModel.state.board
        ) else {
            return
        }

        // ディスクを配置
        let flippedPositions = viewModel.flippedDiskPositions(at: position, for: disk)

        // アニメーション付きで配置
        await animationController.animatePlacement(
            at: position,
            disk: disk,
            flippedPositions: flippedPositions
        ) {
            // 実際のディスク配置
            await viewModel.placeDisk(at: position)
        }
    }
}

// MARK: - Preview
#Preview("Initial State") {
    GameView()
}

#Preview("Dark Manual vs Light Computer") {
    let engine = GameEngine()
    var state = GameState()
    state.darkPlayerMode = .manual
    state.lightPlayerMode = .computer
    let viewModel = GameViewModel(engine: engine, initialState: state)
    return GameView(viewModel: viewModel)
}
