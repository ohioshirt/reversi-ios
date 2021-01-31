
//  GameStateStore.swift
//  Reversi
//
//  Created by shigeo on 2021/01/30.
//  Copyright © 2021 Yuta Koshizawa. All rights reserved.
//

import Foundation

struct GameState {
    let diskTurn: Disk?
    let playerDarkPlayMode: Player
    let playerLightPlayMode: Player
    let disksOnBoard: [[Disk?]] // 行単位で持つ
}

protocol GameStore {
    static func save(_ state: GameState) throws
    static func load() throws -> GameState
}

struct GameStateStore: GameStore {
    
    private static var path: String {
        (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("Game")
    }
    
    static func save(_ state: GameState) throws {
        // (手番)(黒モード)(白モード)
        // １行目
        // ２行目（以下略）
        let output = """
\(state.diskTurn.symbol)\(state.playerDarkPlayMode.rawValue)\(state.playerLightPlayMode.rawValue)
\(state.disksOnBoard.map { $0.map { $0.symbol}.joined() }.joined(separator: "\n"))
"""

        do {
            try output.write(toFile: path, atomically: true, encoding: .utf8)
        } catch let error {
            throw FileIOError.read(path: path, cause: error)
        }
    }
    
    static func load() throws -> GameState {
        let input = try String(contentsOfFile: path, encoding: .utf8)
        var lines: ArraySlice<Substring> = input.split(separator: "\n")[...]
        // 復元するもの
        var turn: Disk? = .none
        var playerDark = Player.manual
        var playerLight = Player.manual
        var disks: [[Disk?]] = []
        
        guard var firstLine = lines.popFirst() else {
            throw FileIOError.read(path: path, cause: nil)
        }
        
        // turn of Disk
        do {
            guard
                let diskSymbol = firstLine.popFirst(),
                let disk = Optional<Disk>(symbol: diskSymbol.description)
            else {
                throw FileIOError.read(path: path, cause: nil)
            }
            turn = disk
        }

        // players mode
        let playerFromLine: (_ s: String?) -> Player? = { s in
            guard
                let symbol = s?.description,
                let playerNumber = Int(symbol),
                let player = Player(rawValue: playerNumber)
            else {
                return nil
            }
            return player
        }
        playerDark = playerFromLine(firstLine.popFirst()?.description) ?? .manual
        playerLight = playerFromLine(firstLine.popFirst()?.description) ?? .manual

        do { // board
            guard lines.count == Board.height else {
                throw FileIOError.read(path: path, cause: nil)
            }
            
            var y = 0
            while let line = lines.popFirst() {
                let disksOfLine = line.map { c in Disk?(symbol: "\(c)").flatMap { $0 } }
                guard disksOfLine.count == Board.width else {
                    throw FileIOError.read(path: path, cause: nil)
                }
                disks.append(disksOfLine)

                y += 1
            }
            // ファイルチェック
            guard y == Board.height else {
                throw FileIOError.read(path: path, cause: nil)
            }
        }
        
        return GameState(diskTurn: turn,
                         playerDarkPlayMode: playerDark,
                         playerLightPlayMode: playerLight,
                         disksOnBoard: disks)
    }
}

extension Optional where Wrapped == Disk {
    fileprivate init?<S: StringProtocol>(symbol: S) {
        switch symbol {
        case "x":
            self = .some(.dark)
        case "o":
            self = .some(.light)
        case "-":
            self = .none
        default:
            return nil
        }
    }

    fileprivate var symbol: String {
        switch self {
        case .some(.dark):
            return "x"
        case .some(.light):
            return "o"
        case .none:
            return "-"
        }
    }
}

enum FileIOError: Error {
    case write(path: String, cause: Error?)
    case read(path: String, cause: Error?)
}
