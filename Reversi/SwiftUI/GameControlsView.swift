import SwiftUI

/// ゲームコントロールを表示するビュー
struct GameControlsView: View {
    @ObservedObject var viewModel: GameViewModel
    let repository: GameRepository

    /// アラート表示状態
    @State private var showResetAlert = false
    @State private var showSaveSuccess = false
    @State private var showLoadError = false

    var body: some View {
        VStack(spacing: 16) {
            // プレイヤーモードコントロール
            HStack(spacing: 20) {
                // 黒のプレイヤーモード
                PlayerModeControl(
                    disk: .dark,
                    playerMode: viewModel.state.playerMode(for: .dark),
                    onToggle: {
                        viewModel.togglePlayerMode(for: .dark)
                    }
                )

                // 白のプレイヤーモード
                PlayerModeControl(
                    disk: .light,
                    playerMode: viewModel.state.playerMode(for: .light),
                    onToggle: {
                        viewModel.togglePlayerMode(for: .light)
                    }
                )
            }

            // ゲームコントロールボタン
            HStack(spacing: 12) {
                // リセットボタン
                Button(action: {
                    showResetAlert = true
                }) {
                    Text("Reset")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .alert("Reset Game", isPresented: $showResetAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reset", role: .destructive) {
                        viewModel.newGame()
                    }
                } message: {
                    Text("Are you sure you want to reset the game?")
                }

                // 保存ボタン
                Button(action: {
                    Task {
                        do {
                            try await repository.save(viewModel.state)
                            showSaveSuccess = true
                        } catch {
                            // エラー処理（必要に応じて実装）
                        }
                    }
                }) {
                    Text("Save")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .alert("Game Saved", isPresented: $showSaveSuccess) {
                    Button("OK") {}
                } message: {
                    Text("Your game has been saved successfully.")
                }

                // 読み込みボタン
                Button(action: {
                    Task {
                        do {
                            if let loadedState = try await repository.load() {
                                viewModel.state = loadedState
                            }
                        } catch {
                            showLoadError = true
                        }
                    }
                }) {
                    Text("Load")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .alert("Load Failed", isPresented: $showLoadError) {
                    Button("OK") {}
                } message: {
                    Text("Failed to load saved game.")
                }
            }
        }
        .padding(.horizontal)
    }
}

/// プレイヤーモードコントロール
struct PlayerModeControl: View {
    let disk: Disk
    let playerMode: PlayerMode
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // ディスクアイコン
            Circle()
                .fill(disk == .dark ? Color.black : Color.white)
                .overlay(
                    Circle()
                        .stroke(Color.gray, lineWidth: 1)
                )
                .frame(width: 32, height: 32)

            // セグメントコントロール風のボタン
            HStack(spacing: 0) {
                ModeButton(
                    title: "Manual",
                    isSelected: playerMode == .manual,
                    position: .leading,
                    action: {
                        if playerMode != .manual {
                            onToggle()
                        }
                    }
                )

                ModeButton(
                    title: "Computer",
                    isSelected: playerMode == .computer,
                    position: .trailing,
                    action: {
                        if playerMode != .computer {
                            onToggle()
                        }
                    }
                )
            }
            .frame(height: 32)
        }
    }
}

/// モード選択ボタン
struct ModeButton: View {
    let title: String
    let isSelected: Bool
    let position: Position
    let action: () -> Void

    enum Position {
        case leading, trailing
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                .clipShape(
                    position == .leading
                        ? AnyShape(UnevenRoundedRectangle(
                            topLeadingRadius: 8,
                            bottomLeadingRadius: 8,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 0
                        ))
                        : AnyShape(UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 8,
                            topTrailingRadius: 8
                        ))
                )
        }
        .buttonStyle(.plain)
    }
}

/// 型消去されたShape
struct AnyShape: Shape {
    private let _path: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - Preview
#Preview("Default State") {
    let engine = GameEngine()
    let viewModel = GameViewModel(engine: engine)
    let repository = FileGameRepository()

    return GameControlsView(
        viewModel: viewModel,
        repository: repository
    )
    .previewLayout(.sizeThatFits)
}

#Preview("Dark Computer vs Light Manual") {
    let engine = GameEngine()
    var state = GameState()
    state.darkPlayerMode = .computer
    state.lightPlayerMode = .manual
    let viewModel = GameViewModel(engine: engine, initialState: state)
    let repository = FileGameRepository()

    return GameControlsView(
        viewModel: viewModel,
        repository: repository
    )
    .previewLayout(.sizeThatFits)
}
