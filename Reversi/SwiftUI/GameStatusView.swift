import SwiftUI

/// ゲームステータスを表示するビュー
struct GameStatusView: View {
    /// ゲームのViewModel
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 8) {
            // スコア表示
            HStack(spacing: 40) {
                // 黒のスコア
                ScoreView(
                    disk: .dark,
                    count: viewModel.diskCount(for: .dark),
                    isCurrentTurn: viewModel.state.currentTurn == .dark
                )

                // 白のスコア
                ScoreView(
                    disk: .light,
                    count: viewModel.diskCount(for: .light),
                    isCurrentTurn: viewModel.state.currentTurn == .light
                )
            }

            // メッセージ表示
            MessageView(viewModel: viewModel)
        }
        .padding(.horizontal)
    }
}

/// 個別のスコア表示
struct ScoreView: View {
    let disk: Disk
    let count: Int
    let isCurrentTurn: Bool

    var body: some View {
        HStack(spacing: 8) {
            // ディスクの色
            Circle()
                .fill(disk == .dark ? Color.black : Color.white)
                .overlay(
                    Circle()
                        .stroke(Color.gray, lineWidth: 1)
                )
                .frame(width: 24, height: 24)

            // カウント
            Text("\(count)")
                .font(.system(size: 20, weight: isCurrentTurn ? .bold : .regular))
                .foregroundColor(isCurrentTurn ? .primary : .secondary)
        }
        .opacity(isCurrentTurn ? 1.0 : 0.6)
    }
}

/// メッセージ表示
struct MessageView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        Text(messageText)
            .font(.system(size: 16))
            .foregroundColor(.secondary)
    }

    private var messageText: String {
        if let winner = viewModel.winner() {
            return winner == .dark ? "Black won" : "White won"
        } else if let current = viewModel.state.currentTurn {
            return current == .dark ? "Black's turn" : "White's turn"
        } else {
            return "Tie"
        }
    }
}

// MARK: - Preview
#Preview("Initial State") {
    let engine = GameEngine()
    let viewModel = GameViewModel(engine: engine)
    return GameStatusView(viewModel: viewModel)
        .previewLayout(.sizeThatFits)
}

#Preview("Dark's Turn") {
    let engine = GameEngine()
    var state = GameState()
    state.currentTurn = .dark
    let viewModel = GameViewModel(engine: engine, initialState: state)
    return GameStatusView(viewModel: viewModel)
        .previewLayout(.sizeThatFits)
}

#Preview("Light's Turn") {
    let engine = GameEngine()
    var state = GameState()
    state.currentTurn = .light
    let viewModel = GameViewModel(engine: engine, initialState: state)
    return GameStatusView(viewModel: viewModel)
        .previewLayout(.sizeThatFits)
}
