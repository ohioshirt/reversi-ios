//
//  GameStateStore.swift
//  Reversi
//
//  Created by shigeo on 2021/01/30.
//  Copyright © 2021 Yuta Koshizawa. All rights reserved.
//

import Foundation

struct GameState {
    let player: Player?
    let playerDarkMode: String
    let playerLightMode: String
    let disksOnBoard: [Disk]
}

protocol GameStore {
    func save(_ state: GameState) throws
    func load() throws -> GameState
}

struct GameStateStore: GameStore {
    private var path: String {
        (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("Game")
    }
    
    func save(_ state: GameState) throws {
        
    }
    
    func load() throws -> GameState {
        return GameState(player: nil,
                         playerDarkMode: "",
                         playerLightMode: "",
                         disksOnBoard: [])
    }
}
