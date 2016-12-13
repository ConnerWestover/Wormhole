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
import AVFoundation

class GameViewController: UIViewController {
    
    //MARK: - ivars -
    var gameScene: GameScene?
    var skView:SKView!
    let showDebugData = false
    var screenSize = CGSize(width: 1080, height: 1920)
    let scaleMode = SKSceneScaleMode.aspectFill
    var player: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = Bundle.main.url(forResource: "background", withExtension: "mp3")
        
        do {
            player = try AVAudioPlayer(contentsOf: url!)
            guard let player = player else {return}
            
            player.prepareToPlay()
            player.play()
        } catch let error as Error {
            print(error)
        }
        
        skView = self.view as! SKView
        loadHomeScene()
        
        //debug stuff
        skView.ignoresSiblingOrder = true
        skView.showsFPS = showDebugData
        skView.showsNodeCount = showDebugData
        
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            screenSize = UIScreen.main.bounds.size
        }
    }
    
    //MARK: - Scene Management -
    func loadHomeScene(){
        let scene = HomeScene(size: CGSize(width: 1080, height: 1920), scaleMode:scaleMode, sceneManager: self)
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

