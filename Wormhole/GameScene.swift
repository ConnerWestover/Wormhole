//
//  GameScene.swift
//  Wormhole
//
//  Created by Conner on 9/26/16.
//  Copyright © 2016 Bugz 4 Dayz. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //# MARK: - Variables
    
    // Layered Nodes
    var foregroundNode: SKNode!
    var hudNode: SKNode!
    var starEmitter:SKEmitterNode!
    // Player
    var player: SKNode!
    
    var pauseScreen: SKLabelNode!
    
    var stop: Bool = false
    
    var sceneManager:GameViewController!
    
    // Motion manager for accelerometer
    let motionManager = CMMotionManager()
    
    // Acceleration value from accelerometer
    var xAcceleration: CGFloat = 0.0
    
    // Labels for score
    var lblScore: SKLabelNode!
    
    // Game over dude!
    var gameOver = false
    
    var pause:SKLabelNode!
    
    // To Accommodate iPhone 6
    var scaleFactor: CGFloat!
    
    // screen size holder
    var screenSize: CGFloat!
    var screenWidth: CGFloat!
    
    //# MARK: - Startup functions
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(size: CGSize , scaleMode: SKSceneScaleMode, sceneManager: GameViewController) {
        self.sceneManager = sceneManager
        super.init(size:size)
        self.scaleMode = scaleMode
        
        backgroundColor = SKColor.black
        scaleFactor = self.size.width / 320.0
        
        // Reset
        GameState.sharedInstance.score = 0
        gameOver = false
        
        // Create the game nodes
        // Background
        self.starEmitter  = SKEmitterNode(fileNamed: "Stars2")!
        self.starEmitter.position = CGPoint(x:self.size.width/2.0, y:self.size.height)
        self.starEmitter.particlePositionRange.dx = self.size.width
        self.starEmitter.zPosition = -5
        addChild(self.starEmitter)
        
        // Set contact delegate
        physicsWorld.contactDelegate = self
        
        // Foreground
        foregroundNode = SKNode()
        addChild(foregroundNode)
        
        // HUD
        hudNode = SKNode()
        addChild(hudNode)
        
        //Screen Size
        screenSize = size.height
        screenWidth = size.width
        
        // Add the player
        player = createPlayer()
        foregroundNode.addChild(player)
    
        
        // Build the HUD
        pause = SKLabelNode(fontNamed: "GurmukhiMN-Bold")
        pause.fontSize = 30
        pause.fontColor = SKColor.cyan
        pause.position = CGPoint(x: self.size.width * 3.0/4.0, y: self.size.height)
        pause.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        pause.text = "pause"
        hudNode.addChild(pause)
        
        pauseScreen = SKLabelNode(fontNamed: "GurmukhiMN-Bold")
        pauseScreen.fontSize = 60
        pauseScreen.fontColor = SKColor.cyan
        pauseScreen.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        pauseScreen.position = CGPoint(x: screenWidth/2, y: screenSize/2)
        pauseScreen.text = "PAUSED"
        
        // Score
        lblScore = SKLabelNode(fontNamed: "GurmukhiMN-Bold")
        lblScore.fontSize = 30
        lblScore.fontColor = SKColor.cyan
        lblScore.position = CGPoint(x: self.size.width, y: 200)
        lblScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        lblScore.text = "0"
        hudNode.addChild(lblScore)
        
        // CoreMotion
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates()
        
    }
    
    //Creates the Player
    func createPlayer() -> SKNode {
        let playerNode = SKNode()
        playerNode.position = CGPoint(x: self.size.width / 2, y: 400.0)
        
        let sprite = SKSpriteNode(imageNamed: "Spaceship")
        sprite.xScale = 0.5
        sprite.yScale = 0.5
        playerNode.addChild(sprite)
        
        //Setup Physics for Player
        playerNode.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
        playerNode.physicsBody?.isDynamic = true
        playerNode.physicsBody?.allowsRotation = false
        playerNode.physicsBody?.restitution = 1.0
        playerNode.physicsBody?.friction = 0.0
        playerNode.physicsBody?.angularDamping = 0.0
        playerNode.physicsBody?.linearDamping = 0.0
        playerNode.physicsBody?.affectedByGravity = false
        
        playerNode.physicsBody?.usesPreciseCollisionDetection = true
        playerNode.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Player
        playerNode.physicsBody?.collisionBitMask = 0
        playerNode.physicsBody?.contactTestBitMask = CollisionCategoryBitmask.Enemy
        
        return playerNode
    }
    
    //# MARK: - Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        var touch = touches.first
        var point = touch?.location(in: self.view)
        
        //Did mean to Pause?
        if (point?.y)! < CGFloat(50.0) {
            pauseMe()
        }
        
        //TODO: Fire Bullets
    }
    
    //# MARK: - Pause
    func pauseMe(){
        //if paused start, remove PAUSED label
        if physicsWorld.speed == 0 {
            physicsWorld.speed = 1
            pauseScreen.removeFromParent()
            starEmitter.isPaused = false
        } else {
            //Pause, Add Paused Label
            physicsWorld.speed = 0
            hudNode.addChild(pauseScreen)
            starEmitter.isPaused = true
        }
    }
    
    //# MARK: - Updates and Loading
    override func update(_ currentTime: TimeInterval) {
        //Game over?
        if gameOver {
            return
        }
        
        //update accelerometer
        
        if let accelerometerData = motionManager.accelerometerData {
            self.xAcceleration = CGFloat(accelerometerData.acceleration.x * 0.75) + (self.xAcceleration * 0.25)
        }
        
        // Remove game objects that have passed by
        foregroundNode.enumerateChildNodes(withName: "NODE_ASTEROID", using: {
            (node, stop) in
            let asteroid = node as! Asteroid
            asteroid.checkNodeRemoval()
        })
        
    }
    
    //# MARK: - Physics
    func didBeginContact(contact: SKPhysicsContact) {
        var updateHUD = false
        //Get gameObjectNode
        let whichNode = (contact.bodyA.node != player) ? contact.bodyA.node : contact.bodyB.node
        let other = whichNode as! GameObjectNode
        
        // Update the HUD if necessary
        if updateHUD  {
            lblScore.text = String(format: "%d", GameState.sharedInstance.score)
        }
    }
    
    override func didSimulatePhysics() {
        // Set velocity based on x-axis acceleration
        player.physicsBody?.velocity = CGVector(dx: xAcceleration * 400.0, dy: player.physicsBody!.velocity.dy)
        // Check x bounds
        if player.position.x < 20.0 {
            player.position = CGPoint(x: 20.0, y: player.position.y)
        } else if (player.position.x > self.size.width - 20.0) {
            player.position = CGPoint(x: self.size.width - 20.0, y: player.position.y)
        }
    }
    
    
    //# MARK: - EndGame
    func endGame() {
        gameOver = true
        
        // Save stars and high score
        GameState.sharedInstance.saveState()
        //Add HighScore
        let reveal = SKTransition.fade(withDuration: 0.5)
        let endGameScene = GameOverScene(size: self.size, scaleMode: self.scaleMode, sceneManager: self.sceneManager)
        self.view!.presentScene(endGameScene, transition: reveal)
    }
    
}

