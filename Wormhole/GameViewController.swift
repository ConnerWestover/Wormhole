//
//  GameViewController.swift
//  Wormhole
//
//  Created by Conner on 9/26/16.
//  Copyright © 2016 Bugz 4 Dayz. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    //MARK: - ivars -
    var gameScene: GameScene?
    var skView:SKView!
    let showDebugData = true
    let screenSize = CGSize(width: 1080, height: 1920)
    let scaleMode = SKSceneScaleMode.aspectFill
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        skView = self.view as! SKView
        loadHomeScene()
        
        //debug stuff
        skView.ignoresSiblingOrder = true
        skView.showsFPS = showDebugData
        skView.showsNodeCount = showDebugData
    }
    
    //MARK: - Scene Management -
    func loadHomeScene(){
        let scene = HomeScene(size: screenSize, scaleMode:scaleMode, sceneManager: self)
        let reveal = SKTransition.crossFade(withDuration: 1)
        skView.presentScene(scene, transition:reveal)
    }
    
    func loadGameScene(levelNum: Int, totalScore: Int){
        gameScene = GameScene(size: screenSize, scaleMode: scaleMode, sceneManager: self)
        
        // let reveal = SKTransition.flipHorizontal(withDuration: 1.0)
        let reveal = SKTransition.doorsOpenHorizontal(withDuration: 1)
        // let reveal = SKTransition.crossFade(withDuration: 1)
        skView?.presentScene(gameScene!, transition: reveal)
    }

    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

