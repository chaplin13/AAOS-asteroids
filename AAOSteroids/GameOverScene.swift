//
//  GameOverScene.swift
//  AAOSteroids
//
//  Created by Michael Johnson on 4/23/15.
//  Copyright (c) 2015 BobbingHeads. All rights reserved.
//

import Foundation
import SpriteKit

class GameOverScene: SKScene {
    
    init(size: CGSize, score: Int) {
        
        super.init(size: size)
        
        // 1
        backgroundColor = SKColor.blackColor()
        
        let message = "Your Final Score: \(score)"
        
        // 3
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        label.text = message
        label.fontSize = 40
        label.fontColor = SKColor.whiteColor()
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        
        let button: SKButton = SKButton(defaultButtonImage: "continueButton", activeButtonImage: "continueButton_active", buttonAction: goToGame)
        button.position = CGPointMake(label.position.x, label.position.y - label.frame.height * 1.5)
        addChild(button)
        
    }

    func goToGame() {
        runAction(SKAction.sequence([
            SKAction.runBlock() {
                // 5
                let reveal = SKTransition.flipHorizontalWithDuration(0.5)
                if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
                    self.view?.presentScene(scene, transition:reveal)
                }
            }
            ]))
    }

    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}