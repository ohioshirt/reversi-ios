import SwiftUI

/// リバーシの盤面を表示するビュー
struct BoardGridView: View {
    let board: Board
    let currentTurn: Disk?

    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var animationController: AnimationController

    /// アニメーション中のディスク配置位置
    @State private var animatingPosition: Position?

    /// アニメーション中の反転位置
    @State private var flippingPositions: Set<Position> = []

    var body: some View {
        GeometryReader { geometry in
            let cellSize = geometry.size.width / 8

            ZStack {
                // 背景（緑色の盤面）
                Color(red: 0.0, green: 0.5, blue: 0.25)

                // グリッド線
                GridLines(cellSize: cellSize)

                // セルとディスク
                ForEach(0..<8, id: \.self) { y in
                    ForEach(0..<8, id: \.self) { x in
                        let position = Position(x: x, y: y)
                        CellContentView(
                            position: position,
                            disk: board.disk(at: position),
                            isValidMove: isValidMove(at: position),
                            isAnimating: animatingPosition == position,
                            isFlipping: flippingPositions.contains(position),
                            cellSize: cellSize,
                            onTap: {
                                handleTap(at: position)
                            }
                        )
                        .frame(width: cellSize, height: cellSize)
                        .position(
                            x: CGFloat(x) * cellSize + cellSize / 2,
                            y: CGFloat(y) * cellSize + cellSize / 2
                        )
                    }
                }
            }
        }
    }

    /// 指定位置が有効な手かどうか
    private func isValidMove(at position: Position) -> Bool {
        guard let current = currentTurn else { return false }
        let playerMode = viewModel.state.playerMode(for: current)
        guard playerMode == .manual else { return false }

        let validMoves = viewModel.validMoves(for: current)
        return validMoves.contains(position)
    }

    /// セルがタップされたときの処理
    private func handleTap(at position: Position) {
        guard let current = currentTurn else { return }
        guard isValidMove(at: position) else { return }

        Task {
            let flippedPositions = viewModel.flippedDiskPositions(at: position, for: current)

            // アニメーション状態を更新
            animatingPosition = position
            self.flippingPositions = Set(flippedPositions)

            // アニメーション付きでディスクを配置
            await animationController.animatePlacement(
                at: position,
                disk: current,
                flippedPositions: flippedPositions
            ) {
                await viewModel.placeDisk(at: position)
            }

            // アニメーション状態をクリア
            animatingPosition = nil
            self.flippingPositions = []
        }
    }
}

/// グリッド線を描画するビュー
struct GridLines: View {
    let cellSize: CGFloat

    var body: some View {
        Canvas { context, size in
            // 縦線
            for i in 0...8 {
                let x = CGFloat(i) * cellSize
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(
                    path,
                    with: .color(.black),
                    lineWidth: 2
                )
            }

            // 横線
            for i in 0...8 {
                let y = CGFloat(i) * cellSize
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(
                    path,
                    with: .color(.black),
                    lineWidth: 2
                )
            }
        }
    }
}

/// セルの内容（ディスクまたは有効な手のマーカー）を表示するビュー
struct CellContentView: View {
    let position: Position
    let disk: Disk?
    let isValidMove: Bool
    let isAnimating: Bool
    let isFlipping: Bool
    let cellSize: CGFloat
    let onTap: () -> Void

    var body: some View {
        ZStack {
            // タップ可能な透明なエリア
            Color.clear

            // 有効な手のマーカー
            if isValidMove && disk == nil {
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: cellSize * 0.3, height: cellSize * 0.3)
            }

            // ディスク
            if let disk = disk {
                DiskShape(
                    disk: disk,
                    isAnimating: isAnimating,
                    isFlipping: isFlipping,
                    size: cellSize * 0.8
                )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

/// ディスクの形状を表示するビュー
struct DiskShape: View {
    let disk: Disk
    let isAnimating: Bool
    let isFlipping: Bool
    let size: CGFloat

    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .fill(disk == .dark ? Color.black : Color.white)
            .overlay(
                Circle()
                    .stroke(Color.gray, lineWidth: 1)
            )
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: 0, y: 1, z: 0)
            )
            .onAppear {
                if isAnimating {
                    // 配置アニメーション
                    scale = 0.0
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        scale = 1.0
                    }
                }
            }
            .onChange(of: isFlipping) { _, newValue in
                if newValue {
                    // 反転アニメーション
                    withAnimation(.easeInOut(duration: 0.3)) {
                        rotation = 180
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        rotation = 0
                    }
                }
            }
    }
}

// MARK: - Preview
#Preview("Initial Board") {
    let engine = GameEngine()
    let viewModel = GameViewModel(engine: engine)
    let animationController = AnimationController()

    return BoardGridView(
        board: viewModel.state.board,
        currentTurn: viewModel.state.currentTurn,
        viewModel: viewModel,
        animationController: animationController
    )
    .aspectRatio(1.0, contentMode: .fit)
    .padding()
}

#Preview("Dark's Turn") {
    let engine = GameEngine()
    var state = GameState()
    state.currentTurn = .dark
    let viewModel = GameViewModel(engine: engine, initialState: state)
    let animationController = AnimationController()

    return BoardGridView(
        board: viewModel.state.board,
        currentTurn: viewModel.state.currentTurn,
        viewModel: viewModel,
        animationController: animationController
    )
    .aspectRatio(1.0, contentMode: .fit)
    .padding()
}
