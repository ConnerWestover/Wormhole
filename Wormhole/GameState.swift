//
//  GameState.swift
//  HopTillYouDrop
//
//  Created by Student on 5/7/15.
//  Copyright (c) 2015 Student. All rights reserved.
//

import Foundation

class GameState {
    
    var score: Int
    var highScore: Int
    
    class var sharedInstance :GameState {
        struct Singleton {
            static let instance = GameState()
        }
        
        return Singleton.instance
    }
    
    init() {
        // Init
        score = 0
        highScore = 0
        
        // Load game state
        let defaults = UserDefaults.standard
        
        highScore = defaults.integer(forKey: "highScore")
    }
    
    func saveState() {
        // Update highScore if the current score is greater
        highScore = max(score, highScore)
        
        // Store in user defaults
        let defaults = UserDefaults.standard
        defaults.set(highScore, forKey: "highScore")
        UserDefaults.standard.synchronize()
    }
    
}
