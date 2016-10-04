//
//  GameOver.swift
//  Shooter
//
//  Created by student on 9/26/16.
//  Copyright © 2016 student. All rights reserved.
//

import SpriteKit
class GameOverScene: SKScene {
    // MARK: - ivars -
    let sceneManager:GameViewController
    
    // MARK: - initialization -
    init(size: CGSize, scaleMode:SKSceneScaleMode, sceneManager: GameViewController, score:Float){
        self.sceneManager = sceneManager
        super.init(size: size)
        self.scaleMode = scaleMode
    }
    
    required init(coder aDecoder: NSCoder){
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle -
    override func didMove(to view: SKView){
        backgroundColor = SKColor.black
        // Score
        let lblScore = SKLabelNode(fontNamed: "GurmukhiMN-Bold")
        lblScore.fontSize = 100
        lblScore.fontColor = SKColor.white
        lblScore.position = CGPoint(x: self.size.width / 2, y: size.height/2)
        lblScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        lblScore.text = String(format: "You Scored: %.2f", GameState.sharedInstance.score)
        addChild(lblScore)
        
        // High Score
        let lblHighScore = SKLabelNode(fontNamed: "GurmukhiMN-Bold")
        lblHighScore.fontSize = 50
        lblHighScore.fontColor = SKColor.cyan
        lblHighScore.position = CGPoint(x: self.size.width / 2, y: size.height/3)
        lblHighScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        lblHighScore.text = String(format: "High Score: %.2f", GameState.sharedInstance.highScore)
        addChild(lblHighScore)
        
        // Try again
        let lblTryAgain = SKLabelNode(fontNamed: "GurmukhiMN-Bold")
        lblTryAgain.fontSize = 50
        lblTryAgain.fontColor = SKColor.white
        lblTryAgain.position = CGPoint(x: self.size.width / 2, y: 50)
        lblTryAgain.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        lblTryAgain.text = "Tap To Return To Home"
        addChild(lblTryAgain)

        
        }
    
    // MARK: - Events -
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        sceneManager.loadHomeScene()
    }
}
