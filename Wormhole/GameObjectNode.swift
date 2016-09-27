//
//  GameObjectNode.swift
//  HopTillYouDrop
//
//  Created by Student on 5/7/15.
//  Copyright (c) 2015 Student. All rights reserved.
//

import SpriteKit

struct CollisionCategoryBitmask {
    static let Player: UInt32 = 0x0
    static let Enemy: UInt32 = 0x1
    static let Bullet: UInt32 = 0x1 << 1
}

enum EnemyType: Int {
    case Alien = 0
    case Asteroid
    case Boss
}


class GameObjectNode: SKNode {
    
    //function to be overridden
    func collisionWithPlayer(player: SKNode) -> Bool {
        return false
    }
    
    func checkNodeRemoval() {
        if self.position.y < 0.0 {
            self.removeFromParent()
        }
    }
}

class Alien: GameObjectNode {
    var type: EnemyType = EnemyType.Alien
    
    override func collisionWithPlayer(player: SKNode) -> Bool {
        //TODO: Kill Player
        return false
    }
}

class Asteroid: GameObjectNode {
    var type: EnemyType = EnemyType.Asteroid
    
    override func collisionWithPlayer(player: SKNode) -> Bool {
        //TODO: Kill Player
        return false
    }
}

class Bullet: GameObjectNode {

    override func collisionWithPlayer(player: SKNode) -> Bool {
        //TODO: Kill Aliens and Asteroids
        return false
    }
}


