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
    static let Projectile       : UInt32 = 0b100
    static let EnemyProjectile  : UInt32 = 0b1000
    static let PowerUp          : UInt32 = 0b10000
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
    var fireRate:Float = 0.5{
        didSet{
            removeAction(forKey: "Firing")
            run(SKAction.repeatForever(SKAction.sequence([SKAction.run(createBullet), SKAction.wait(forDuration: TimeInterval(fireRate))])), withKey: "Firing")
        }
    }
    var playerFiring:Bool = false
    
    // Labels for health
    var playerHealth:Int = 3{
        didSet{
            lblHealth.text = "Health: \(playerHealth)"
        }
    }
    var lblHealth: SKLabelNode!

    var lblShield: SKLabelNode!
    
    var playerShield:Bool = false {
        didSet{
            if (playerShield){
                lblShield.text = "Shields: On"
            } else {
                lblShield.text = "Shields: Off"
            }
        }
    }
    
    var bulletNumber: Int = 1
    
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
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        let lbl1 = SKLabelNode(fontNamed: "GurmukhiMN-Bold")
        lbl1.fontSize = 60
        lbl1.fontColor = SKColor.white
        lbl1.position = CGPoint(x: self.size.width / 2, y: size.height/2 + 60)
        lbl1.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        lbl1.text = "Tilt Your Device To Move"
        addChild(lbl1)
        
        let lbl2 = SKLabelNode(fontNamed: "GurmukhiMN-Bold")
        lbl2.fontSize = 60
        lbl2.fontColor = SKColor.cyan
        lbl2.position = CGPoint(x: self.size.width / 2, y: size.height/2 - 60)
        lbl2.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        lbl2.text = "Hold Your Finger Down To Shoot"
        addChild(lbl2)
        
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            lbl1.fontSize = 40
            lbl2.fontSize = 40
        }
        
        let fade = SKAction.fadeOut(withDuration: 2.0)
        let wait = SKAction.wait(forDuration:3.0)
        
        lbl1.run(SKAction.sequence([wait,fade]))
        lbl2.run(SKAction.sequence([wait,fade]))
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
        self.starEmitter.advanceSimulationTime(5.0)
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
        
        lblHealth = SKLabelNode(fontNamed: "GurmukhiMN-Bold")
        lblHealth.fontSize = 30
        lblHealth.fontColor = SKColor.red
        lblHealth.position = CGPoint(x: 80, y: self.size.height / 20)
        lblHealth.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        lblHealth.text = "Health: 3"
        addChild(lblHealth)
        
        lblShield = SKLabelNode(fontNamed: "GurmukhiMN-Bold")
        lblShield.fontSize = 30
        lblShield.fontColor = SKColor.cyan
        lblShield.position = CGPoint(x: 80, y: self.size.height / 20 - 40)
        lblShield.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        lblShield.text = "Shields: Off"
        addChild(lblShield)
        
        // CoreMotion
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates()
        
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            lblShield.fontSize = 15
            lblShield.position.x = 40
            lblHealth.fontSize = 15
            lblHealth.position = CGPoint(x: 40, y: self.size.height / 20 - 20)
            lblScore.fontSize = 20
            pause.fontSize = 20
        }
    
        
    }
    
    //Creates the Player
    func createPlayer() -> SKNode {
        let playerNode = SKNode()
        playerNode.position = CGPoint(x: self.size.width / 2, y: self.size.height / 20)
        
        let sprite = SKSpriteNode(imageNamed: "Player")
        playerNode.name = "player"
        //sprite.xScale = 0.25
        //sprite.yScale = 0.25
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
            run(SKAction.playSoundFileNamed("bulletFire.mp3", waitForCompletion: false))
            if bulletNumber == 1 {
            
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
            else if bulletNumber == 2{
                
                let bullet1 = SKSpriteNode(imageNamed: "bullet")
                bullet1.position = player.position // aliens fire above their ship
                bullet1.position.x -= 30
                bullet1.zPosition = -4
                bullet1.xScale = 0.125
                bullet1.yScale = 0.125
                bullet1.physicsBody = SKPhysicsBody(circleOfRadius: bullet1.size.width/2)
                bullet1.physicsBody?.isDynamic = true
                bullet1.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
                bullet1.physicsBody?.contactTestBitMask = PhysicsCategory.Enemy
                bullet1.physicsBody?.collisionBitMask = PhysicsCategory.None
                bullet1.physicsBody?.usesPreciseCollisionDetection = true
                
                addChild(bullet1)
                
                let point = CGPoint(x: player.position.x - 30, y: self.size.height + 20)
                bullet1.name = "Projectile"
                let actionMove = SKAction.move(to: point, duration: 2.0)
                let actionMoveDone = SKAction.removeFromParent()
                bullet1.run(SKAction.sequence([actionMove, actionMoveDone]))
                
                let bullet2 = SKSpriteNode(imageNamed: "bullet")
                bullet2.position = player.position // aliens fire above their ship
                bullet2.position.x += 30
                bullet2.zPosition = -4
                bullet2.xScale = 0.125
                bullet2.yScale = 0.125
                bullet2.physicsBody = SKPhysicsBody(circleOfRadius: bullet2.size.width/2)
                bullet2.physicsBody?.isDynamic = true
                bullet2.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
                bullet2.physicsBody?.contactTestBitMask = PhysicsCategory.Enemy
                bullet2.physicsBody?.collisionBitMask = PhysicsCategory.None
                bullet2.physicsBody?.usesPreciseCollisionDetection = true
                
                addChild(bullet2)
                
                let point2 = CGPoint(x: player.position.x + 30, y: self.size.height + 20)
                bullet2.name = "Projectile"
                let actionMove2 = SKAction.move(to: point2, duration: 2.0)
                let actionMoveDone2 = SKAction.removeFromParent()
                bullet2.run(SKAction.sequence([actionMove2, actionMoveDone2]))
            }
            else if bulletNumber == 3{
                
                let bullet = SKSpriteNode(imageNamed: "bullet")
                bullet.position = player.position // aliens fire above their ship
                bullet.position.y += 20
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
                
                
                let bullet1 = SKSpriteNode(imageNamed: "bullet")
                bullet1.position = player.position // aliens fire above their ship
                bullet1.position.x -= 30
                bullet1.zPosition = -4
                bullet1.xScale = 0.125
                bullet1.yScale = 0.125
                bullet1.physicsBody = SKPhysicsBody(circleOfRadius: bullet1.size.width/2)
                bullet1.physicsBody?.isDynamic = true
                bullet1.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
                bullet1.physicsBody?.contactTestBitMask = PhysicsCategory.Enemy
                bullet1.physicsBody?.collisionBitMask = PhysicsCategory.None
                bullet1.physicsBody?.usesPreciseCollisionDetection = true
                
                addChild(bullet1)
                
                let point1 = CGPoint(x: player.position.x - 30, y: self.size.height + 20)
                bullet1.name = "Projectile"
                let actionMove1 = SKAction.move(to: point1, duration: 2.0)
                let actionMoveDone1 = SKAction.removeFromParent()
                bullet1.run(SKAction.sequence([actionMove1, actionMoveDone1]))
                
                let bullet2 = SKSpriteNode(imageNamed: "bullet")
                bullet2.position = player.position // aliens fire above their ship
                bullet2.position.x += 30
                bullet2.zPosition = -4
                bullet2.xScale = 0.125
                bullet2.yScale = 0.125
                bullet2.physicsBody = SKPhysicsBody(circleOfRadius: bullet2.size.width/2)
                bullet2.physicsBody?.isDynamic = true
                bullet2.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
                bullet2.physicsBody?.contactTestBitMask = PhysicsCategory.Enemy
                bullet2.physicsBody?.collisionBitMask = PhysicsCategory.None
                bullet2.physicsBody?.usesPreciseCollisionDetection = true
                
                addChild(bullet2)
                
                let point2 = CGPoint(x: player.position.x + 30, y: self.size.height + 20)
                bullet2.name = "Projectile"
                let actionMove2 = SKAction.move(to: point2, duration: 2.0)
                let actionMoveDone2 = SKAction.removeFromParent()
                bullet2.run(SKAction.sequence([actionMove2, actionMoveDone2]))
            }
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
    
    func addPowerUp(pos: CGPoint, maxLevelPowerUp: UInt32){
        if self.speed != 0{
            
            let x = arc4random_uniform(maxLevelPowerUp*5)
            var powerUp:SKSpriteNode
            switch x {
            case 0...4: // HealthKit
                powerUp = SKSpriteNode(imageNamed: "PowerUp_Health")
                powerUp.name = "Health"
                powerUp.alpha = 1
                break
            case 5...10: //FireRate
                powerUp = SKSpriteNode(imageNamed: "PowerUp_FireRate")
                powerUp.name = "FireRate"
                powerUp.alpha = 0.99
                break
            case 11...16: //Shields
                powerUp = SKSpriteNode(imageNamed: "PowerUp_Shield")
                powerUp.name = "Shield"
                powerUp.alpha = 0.98
                break
            case 17...23: //More Bullets
                powerUp = SKSpriteNode(imageNamed: "PowerUp_Bullet")
                powerUp.name = "MoreBullets"
                powerUp.alpha = 0.97
                break
            case 24...25: // Kill Screen
                powerUp = SKSpriteNode(imageNamed: "PowerUp_Nuke")
                powerUp.name = "Nuke"
                powerUp.alpha = 0.96
                break
            default:
                powerUp = SKSpriteNode(imageNamed: "PowerUp_Health")
                powerUp.name = "Health"
                powerUp.alpha = 1
                break
            }
            
            powerUp.position = pos
            
            powerUp.physicsBody = SKPhysicsBody(circleOfRadius: powerUp.size.width/2)
            powerUp.physicsBody?.isDynamic = true
            powerUp.physicsBody?.categoryBitMask = PhysicsCategory.PowerUp
            powerUp.physicsBody?.contactTestBitMask = PhysicsCategory.Player
            powerUp.physicsBody?.collisionBitMask = PhysicsCategory.None
            powerUp.physicsBody?.usesPreciseCollisionDetection = true
            
            addChild(powerUp)
            
            let point = CGPoint(x: powerUp.position.x, y: powerUp.position.y - self.size.height + 20)
            powerUp.name = "Projectile"
            let actionMove = SKAction.move(to: point, duration: 6.0)
            let actionMoveDone = SKAction.removeFromParent()
            powerUp.run(SKAction.sequence([actionMove, actionMoveDone]))
            
            
            
        }
    }
    
    // add asteroids
    func addAsteroid(){
      if self.speed != 0{
        let x = random(min: 1, max: 4)
        let asteroid = SKSpriteNode(imageNamed: "asteroid\(x)" )

        asteroid.zPosition = -4
        asteroid.name = "Asteroid"
        
        // Determine where to spawn the asteroid along the X axis
        let actualX = random(min: asteroid.size.width/2, max: size.width - asteroid.size.width/2)
        let endX = random(min: asteroid.size.width/2, max: size.width - asteroid.size.width/2)
        // Position the asteroid slightly off-screen,
        asteroid.position = CGPoint(x: actualX, y: size.height + asteroid.size.height/2)
        
        // Add the monster to the scene
        addChild(asteroid)
        
        asteroid.xScale = 0.25
        asteroid.yScale = 0.25
        
        // Determine speed of the monster
        let actualDuration = 10.0
        
        // Create the actions
        let actionMove = SKAction.move(to: CGPoint(x: endX, y: -asteroid.size.height), duration: TimeInterval(actualDuration))
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
        
        var z = 1
        
        if(score > 50){
            z = 2
        }else if score > 125{
            z = 3
        }else if score > 250{
            z = 4
        }
        
        let x = Int(arc4random_uniform(UInt32(z)))
        print(x)
        
        let alien = SKSpriteNode(imageNamed: "alien\(x)")
        
        if x == 0{
            alien.zPosition = 1
        }else if x == 1{
            alien.zPosition = 2
        }else if x == 2{
            alien.zPosition = 3
        }else if x == 3{
            alien.zPosition = 4
        }

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
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }

        
        if ((firstBody.categoryBitMask & PhysicsCategory.Enemy != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
            score += 3
            if firstBody.node?.name == "Alien"{
                firstBody.node?.zPosition -= 1
                if (firstBody.node?.zPosition)! <= CGFloat(0.0) {
                    projectileDidCollideWithMonster(firstBody.node as! SKSpriteNode, object: secondBody.node as! SKSpriteNode)
                } else {
                    secondBody.node?.removeFromParent()
                }
            }else if firstBody.node?.name == "Asteroid"{
                projectileDidCollideWithMonster(firstBody.node as! SKSpriteNode, object: secondBody.node as! SKSpriteNode)
            }
        }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.Player != 0) &&
            (secondBody.categoryBitMask == PhysicsCategory.Enemy)) {
            if !playerShield {
            playerHealth -= 1
            run(SKAction.playSoundFileNamed("damaged.mp3", waitForCompletion: false))
            secondBody.node?.removeFromParent()
            if playerHealth == 0{
                endGame()
            }
            } else {
                playerShield = false
            }
        }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.Player != 0) &&
            (secondBody.categoryBitMask == PhysicsCategory.EnemyProjectile)) {
            if(firstBody.categoryBitMask != PhysicsCategory.Projectile){
              if !playerShield {
                playerHealth -= 1
                run(SKAction.playSoundFileNamed("damaged.mp3", waitForCompletion: false))
                secondBody.node?.removeFromParent()
                if playerHealth == 0{
                    endGame()
                }
              } else {
                playerShield = false
              }
            }
        }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.Player != 0) &&
            (secondBody.categoryBitMask == PhysicsCategory.PowerUp)) {
            activatePowerUp(node: secondBody.node as! SKSpriteNode)
        }
    }
    
    func activatePowerUp(node:SKSpriteNode){
        run(SKAction.playSoundFileNamed("powerup.mp3", waitForCompletion: false))
        print(node.alpha)
        if node.alpha == 1{
            playerHealth += 1
            if playerHealth > 3{
                playerHealth = 3
            }
        }
        if node.alpha >= 0.99 && node.alpha < 1 {
            fireRate -= 0.05
            if fireRate < 0.05 {
                fireRate = 0.05
            }
        }
        if node.alpha >= 0.98 && node.alpha <= 0.99   {
            bulletNumber += 1
            if (bulletNumber > 3){
                bulletNumber = 3
            } else {
                fireRate += 0.3
            }
        }
        if node.alpha >= 0.97 && node.alpha <= 0.98  {
            playerShield = true
        }
        if node.alpha >= 0.96 && node.alpha <= 0.97  {
            self.enumerateChildNodes(withName: "Alien", using: {
                (node: SKNode!, stop: UnsafeMutablePointer <ObjCBool>) -> Void in
                node.removeFromParent()
                self.score += 2
            })
            self.enumerateChildNodes(withName: "Asteroid", using: {
                (node: SKNode!, stop: UnsafeMutablePointer <ObjCBool>) -> Void in
                node.removeFromParent()
                self.score += 2
            })
        }
        node.removeFromParent()
    }
    
    func projectileDidCollideWithMonster(_ projectile:SKSpriteNode, object:SKSpriteNode) {
        
        let node = SKEmitterNode(fileNamed: "Explosion")
        node?.position = object.position
        addChild(node!)
        projectile.removeFromParent()
        object.removeFromParent()
        score += 3
        
        if (arc4random_uniform(1) == 0){
            var powerUpLevel = 1
            if(score > 50) {powerUpLevel = 2;}
            if(score > 100) {powerUpLevel = 3;}
            if(score > 150) {powerUpLevel = 4;}
            if(score > 200) {powerUpLevel = 5;}
            addPowerUp(pos: (node?.position)!, maxLevelPowerUp: UInt32(powerUpLevel))
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
        run(SKAction.playSoundFileNamed("gameLost.mp3", waitForCompletion: false))
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

