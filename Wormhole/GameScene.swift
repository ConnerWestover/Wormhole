//
//  GameScene.swift
//  Wormhole
//
//  Created by Conner on 9/26/16.
//  Copyright © 2016 Bugz 4 Dayz. All rights reserved.
//

import SpriteKit
import CoreMotion

struct PhysicsCategory {
    static let None             : UInt32 = 0
    static let All              : UInt32 = UInt32.max
    static let Player           : UInt32 = 0b1
    static let Enemy            : UInt32 = 0b10
    static let Projectile       : UInt32 = 0b11
    static let EnemyProjectile  : UInt32 = 0b100
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //# MARK: - Variables
    
    // Layered Nodes
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
    var score:Float = 0{
        didSet{
            lblScore.text = "Score: " + String(format: "%.2f", score)
            GameState.sharedInstance.score = score
        }
    }
    var lblScore: SKLabelNode!
    
    // Game over dude!
    var gameOver = false
    
    var pause:SKLabelNode!
    
    //Player Firing
    var fireRate:Float!{
        didSet{
            removeAction(forKey: "Firing")
            run(SKAction.repeatForever(SKAction.sequence([SKAction.run(createBullet), SKAction.wait(forDuration: TimeInterval(fireRate))])), withKey: "Firing")
        }
    }
    var playerFiring:Bool = false
    
    // To Accommodate iPhone 6
    var scaleFactor: CGFloat!
    
    // screen size holder
    var screenSize: CGFloat!
    var screenWidth: CGFloat!
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
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
        
        fireRate = 0.5
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run(createBullet), SKAction.wait(forDuration: TimeInterval(fireRate))])), withKey: "Firing")
        
        // Create the game nodes
        // Background
        self.starEmitter  = SKEmitterNode(fileNamed: "Stars2")!
        self.starEmitter.position = CGPoint(x:self.size.width/2.0, y:self.size.height)
        self.starEmitter.particlePositionRange.dx = self.size.width
        self.starEmitter.zPosition = -5
        addChild(self.starEmitter)
        
        // Set contact delegate
        physicsWorld.contactDelegate = self
        
        //Screen Size
        screenSize = size.height
        screenWidth = size.width
        
        // Add the player
        player = createPlayer()
        addChild(player)
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addAsteroid),
                SKAction.wait(forDuration: 3.0)
                ])
        ))
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addAliens),
                SKAction.wait(forDuration: 8.0)
                ])
        ))
    
        
        // Build the HUD
        pause = SKLabelNode(fontNamed: "GurmukhiMN-Bold")
        pause.fontSize = 30
        pause.fontColor = SKColor.cyan
        pause.position = CGPoint(x: screenWidth - 40, y: screenSize*19/20)
        pause.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        pause.text = "||"
        addChild(pause)
        
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
        lblScore.position = CGPoint(x: 40, y: self.size.height * 19 / 20)
        lblScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        lblScore.text = "0"
        addChild(lblScore)
        
        // CoreMotion
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates()
        
    }
    
    //Creates the Player
    func createPlayer() -> SKNode {
        let playerNode = SKNode()
        playerNode.position = CGPoint(x: self.size.width / 2, y: 400.0)
        
        let sprite = SKSpriteNode(imageNamed: "Spaceship")
        playerNode.name = "player"
        sprite.xScale = 0.25
        sprite.yScale = 0.25
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
        playerNode.physicsBody?.categoryBitMask = PhysicsCategory.Player
        playerNode.physicsBody?.collisionBitMask = 0
        playerNode.physicsBody?.contactTestBitMask = PhysicsCategory.Enemy
        
        return playerNode
    }
    
    
    //MARK: Object Creation Methods
    // Create Bullet
    func createBullet(){
        if self.speed != 0 && playerFiring{
            let bullet = SKSpriteNode(imageNamed: "bullet")
            bullet.position = player.position // aliens fire above their ship
            bullet.zPosition = -4
            bullet.xScale = 0.125
            bullet.yScale = 0.125
            bullet.physicsBody = SKPhysicsBody(circleOfRadius: bullet.size.width/2)
            bullet.physicsBody?.isDynamic = true
            bullet.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
            bullet.physicsBody?.contactTestBitMask = PhysicsCategory.Enemy
            bullet.physicsBody?.collisionBitMask = PhysicsCategory.None
            bullet.physicsBody?.usesPreciseCollisionDetection = true
            
            addChild(bullet)
            
            let point = CGPoint(x: player.position.x, y: self.size.height + 20)
            bullet.name = "Projectile"
            let actionMove = SKAction.move(to: point, duration: 2.0)
            let actionMoveDone = SKAction.removeFromParent()
            bullet.run(SKAction.sequence([actionMove, actionMoveDone]))
        }
    }
    
    func createEnemyBullet(node: SKNode){
        if self.speed != 0{
            let bullet = SKSpriteNode(imageNamed: "bullet")
            
            bullet.position = node.position
            bullet.position.y = bullet.position.y - 200
            bullet.zPosition = -4
            bullet.xScale = 0.125
            bullet.yScale = -0.125
            bullet.physicsBody = SKPhysicsBody(circleOfRadius: bullet.size.width/2)
            
            bullet.physicsBody?.isDynamic = true
            bullet.physicsBody?.categoryBitMask = PhysicsCategory.EnemyProjectile
            bullet.physicsBody?.contactTestBitMask = PhysicsCategory.Player
            bullet.physicsBody?.collisionBitMask = PhysicsCategory.None
            bullet.physicsBody?.usesPreciseCollisionDetection = true
                
            addChild(bullet)
            
            let point = CGPoint(x: node.position.x, y: node.position.x - self.size.height)
            bullet.name = "EnemyProjectile"
            let actionMove = SKAction.move(to: point, duration: 2.0)
            let actionMoveDone = SKAction.removeFromParent()
            bullet.run(SKAction.sequence([actionMove, actionMoveDone]))
        }
    }
    
    // add asteroids
    func addAsteroid(){
      if self.speed != 0{
        let asteroid = SKSpriteNode(imageNamed: "asteroidSmall")

        asteroid.zPosition = -4
        asteroid.name = "Asteroid"
        
        // Determine where to spawn the asteroid along the X axis
        let actualX = random(min: asteroid.size.width/2, max: size.width - asteroid.size.width/2)
        
        // Position the asteroid slightly off-screen,
        asteroid.position = CGPoint(x: actualX, y: size.height + asteroid.size.height/2)
        
        // Add the monster to the scene
        addChild(asteroid)
        
        // Determine speed of the monster
        let actualDuration = 10.0
        
        // Create the actions
        let actionMove = SKAction.move(to: CGPoint(x: actualX, y: -asteroid.size.height), duration: TimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        
        asteroid.run(SKAction.sequence([actionMove, actionMoveDone]))
        
        asteroid.physicsBody = SKPhysicsBody(rectangleOf: asteroid.size) // 1
        asteroid.physicsBody?.isDynamic = false // 2
        asteroid.physicsBody?.categoryBitMask = PhysicsCategory.Enemy // 3
        asteroid.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile // 4
        asteroid.physicsBody?.collisionBitMask = PhysicsCategory.None // 5
      }
    }
    
    // add aliens
    func addAliens(){
      if self.speed != 0{
        let alien = SKSpriteNode(imageNamed: "spaceshipSmall")
        
        alien.xScale = 0.5
        alien.yScale = 0.5
        
        alien.zPosition = -4
        alien.name = "Alien"
        
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size) // 1
        alien.physicsBody?.isDynamic = false // 2
        alien.physicsBody?.categoryBitMask = PhysicsCategory.Enemy // 3
        alien.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile // 4
        alien.physicsBody?.collisionBitMask = PhysicsCategory.None // 5
        
        // Determine where to spawn the monster along the X axis
        let actualX = random(min: alien.size.width/2, max: size.width - alien.size.width/2)
        
        // Position the monster slightly off-screen along the right edge,
        // and along a random position along the Y axis as calculated above
        alien.position = CGPoint(x: actualX, y: size.height + alien.size.height)
        
        // Add the monster to the scene
        addChild(alien)
        
        // Determine speed of the monster
        
        
        // Create the actions
        let actualDuration = 4
        
        let actionShoot = SKAction.run {
            self.createEnemyBullet(node: alien)
        }
        let actionMoveOne = SKAction.move(to: CGPoint(x: random(min: 0, max: size.width), y: size.height/3 * 2), duration: TimeInterval(actualDuration))
        let actionMoveTwo = SKAction.move(to: CGPoint(x: random(min: 0, max: size.width), y: size.height/3), duration: TimeInterval(actualDuration))
        let actionMoveThree = SKAction.move(to: CGPoint(x: random(min: 0, max: size.width), y: -alien.size.height), duration: TimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        alien.run(SKAction.group([SKAction.sequence([actionMoveOne, actionMoveTwo, actionMoveThree, actionMoveDone]), SKAction.repeatForever( SKAction.sequence([actionShoot, SKAction.wait(forDuration: 2.0)]))]))
        }
    }
    
    //# MARK: - Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touch = touches.first
        let point = touch?.location(in: self.view)
        
        //Did mean to Pause?
        if (point?.y)! < CGFloat(50.0) {
            pauseMe()
        }
        playerFiring = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        playerFiring = false
    }
    
    //# MARK: - Pause
    func pauseMe(){
        //if paused start, remove PAUSED label
        if self.speed == 0 {
            physicsWorld.speed = 1
            pauseScreen.removeFromParent()
            starEmitter.isPaused = false
            self.speed = 1
        } else {
            self.speed = 0
            //Pause, Add Paused Label
            physicsWorld.speed = 0
            addChild(pauseScreen)
            starEmitter.isPaused = true
        }
    }
    
    //# MARK: - Updates and Loading
    override func update(_ currentTime: TimeInterval) {
        //Game over?
        if gameOver {
            return
        }
        
        if self.speed != 0{
            score = score + 0.01
        }
        //update accelerometer
        
        if let accelerometerData = motionManager.accelerometerData {
            var acceleration = accelerometerData.acceleration.x
            acceleration = acceleration < -0.2 ? -0.2 : acceleration
            acceleration = acceleration > 0.2 ? 0.2 : acceleration
            
            acceleration = acceleration * 5
            
            if (abs(acceleration) < 0.1){
                acceleration = 0
            }
            
            self.xAcceleration = CGFloat(acceleration) + (self.xAcceleration * 0.25)
        }
        
        // spawn gameObjects on screen
        
    }
    
    //# MARK: - Physics
    func didBegin(_ contact: SKPhysicsContact) {
        
        // 1
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }

        // 2
        if ((firstBody.categoryBitMask & PhysicsCategory.Enemy != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
            projectileDidCollideWithMonster(firstBody.node as! SKSpriteNode, object: secondBody.node as! SKSpriteNode)
        }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.Player != 0) &&
            (secondBody.categoryBitMask == PhysicsCategory.Enemy)) {
            endGame()
        }

        if ((firstBody.categoryBitMask & PhysicsCategory.Player != 0) &&
            (secondBody.categoryBitMask == PhysicsCategory.EnemyProjectile)) {
            endGame()
        }
        
    }
    
    func projectileDidCollideWithMonster(_ projectile:SKSpriteNode, object:SKSpriteNode) {
        projectile.removeFromParent()
        object.removeFromParent()
        score += 3
        
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
        GameState.sharedInstance.score = score
        // Save high score
        GameState.sharedInstance.saveState()
        //Add HighScore
        let reveal = SKTransition.fade(withDuration: 0.5)
        let endGameScene = GameOverScene(size: self.size, scaleMode: self.scaleMode, sceneManager: self.sceneManager, score: score)
        self.view!.presentScene(endGameScene, transition: reveal)
    }
    
}

