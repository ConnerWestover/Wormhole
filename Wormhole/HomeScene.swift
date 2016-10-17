//
//  HomeScene.swift
//  Shooter
//
//  Created by student on 9/22/16.
//  Copyright © 2016 student. All rights reserved.
//

import SpriteKit

class HomeScene: SKScene {
    //MARK: - ivars -
    let sceneManager:GameViewController
    let button:SKLabelNode = SKLabelNode(fontNamed: "GurmukhiMN-Bold")
    
    //MARK: - Initialization - 
    init(size: CGSize, scaleMode: SKSceneScaleMode, sceneManager: GameViewController){
        self.sceneManager = sceneManager
        super.init(size:size)
        self.scaleMode = scaleMode
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        
        let starEmitter  = SKEmitterNode(fileNamed: "Stars2")!
        starEmitter.position = CGPoint(x:self.size.width/2.0, y:self.size.height)
        starEmitter.particlePositionRange.dx = self.size.width
        starEmitter.zPosition = -5
        starEmitter.advanceSimulationTime(5.0)
        addChild(starEmitter)
        
        let label = SKLabelNode(fontNamed: "Zapfino")
        
        label.text = "Wormhole"
        
        label.fontSize = 150
        
        label.position = CGPoint(x:size.width/2, y:size.height/2 + 400)
        
        label.zPosition = 1
        addChild(label)
        
        let label4 = SKLabelNode(fontNamed: "GurmukhiMN-Bold")
        label4.text = "Tap to continue"
        label4.fontColor = UIColor.red
        label4.fontSize = 70
        label4.position = CGPoint(x:size.width/2, y:size.height/2 - 400)
        addChild(label4)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        sceneManager.loadGameScene(levelNum: 1, totalScore: 0)
    }
}
