//
//  GameScene.swift
//  AAOSteroids
//
//  Created by Michael Johnson on 4/19/15.
//  Copyright (c) 2015 BobbingHeads. All rights reserved.
//

import SpriteKit
import AVFoundation

var backgroundMusicPlayer: AVAudioPlayer!

//Operator overrides
func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

//Music
func playBackgroundMusic(filename: String) {
    let url = NSBundle.mainBundle().URLForResource(
        filename, withExtension: nil)
    if (url == nil) {
        println("Could not find file: \(filename)")
        return
    }
    
    var error: NSError? = nil
    backgroundMusicPlayer =
        AVAudioPlayer(contentsOfURL: url, error: &error)
    if backgroundMusicPlayer == nil {
        println("Could not create audio player: \(error!)")
        return
    }
    
    backgroundMusicPlayer.numberOfLoops = -1
    backgroundMusicPlayer.prepareToPlay()
    backgroundMusicPlayer.play()
}

var score:Int = 0 //The variable holding the score.

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let player = SKSpriteNode(imageNamed: "ship")

    
    func updateScoreWithValue (value: Int) {
        var lblScore = self.childNodeWithName("scoreDisplayLabel") as! SKLabelNode;
        score += value
        lblScore.text = "SCORE: \(score)"
    }
    
    override func didMoveToView(view: SKView) {
        playBackgroundMusic("background-music-aac.caf")

        //set up Physics
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        
        backgroundColor = SKColor.blackColor()
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        
        //Set up the collision detection
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width/2) // 1
        player.physicsBody?.dynamic = false // 2
        player.physicsBody?.categoryBitMask = PhysicsCategory.Player // 3
        player.physicsBody?.contactTestBitMask = PhysicsCategory.Asteroid // 4
        player.physicsBody?.collisionBitMask = PhysicsCategory.None // 5
        
        addChild(player)
        
        //Here you run a sequence of actions to call a block of code (you can seamlessly pass in your addAsteroid() method here thanks to the power of Swift), and then wait for 1 second. You then repeat this sequence of actions endlessly.
        
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([
                SKAction.runBlock(addAsteroid),
                SKAction.waitForDuration(0.8)
                ])
            ))
    }
    
    struct PhysicsCategory {
        static let None      : UInt32 = 0
        static let All       : UInt32 = UInt32.max
        static let Asteroid   : UInt32 = 0b1       // 1
        static let EnergyBall: UInt32 = 0b10      // 2
        static let Player    : UInt32 = 0b100
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(#min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addAsteroid() {
        
        // Create sprite
        let asteroid = SKSpriteNode(imageNamed: "rocks")
        
        asteroid.physicsBody = SKPhysicsBody(circleOfRadius: asteroid.size.width/2) // 1
        asteroid.physicsBody?.dynamic = true // 2
        asteroid.physicsBody?.categoryBitMask = PhysicsCategory.Asteroid // 3
        asteroid.physicsBody?.contactTestBitMask = PhysicsCategory.EnergyBall // 4
        asteroid.physicsBody?.collisionBitMask = PhysicsCategory.None // 5
        asteroid.physicsBody?.friction = 0.5
        
        // Determine where to spawn the asteroid along the Y axis
        let actualY = random(min: asteroid.size.height/2, max: size.height - asteroid.size.height/2)
        
        // Position the asteroid slightly off-screen along the right edge,
        // and along a random position along the Y axis as calculated above
        asteroid.position = CGPoint(x: size.width + asteroid.size.width/2, y: actualY)
        
        // Add the asteroid to the scene
        addChild(asteroid)
        
        // Determine speed of the asteroid
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        // Create the actions
        //let actionMove = SKAction.moveTo(CGPoint(x: -asteroid.size.width/2, y: actualY), duration: NSTimeInterval(actualDuration))
        
        
        let actionMoveDone = SKAction.removeFromParent()
        asteroid.physicsBody!.applyImpulse(CGVectorMake(-actualDuration*10, 0))
        
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        runAction(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: true))
        // Choose one of the touches to work with
        let touch = touches.first as! UITouch
        let touchLocation = touch.locationInNode(self)
        
        // Set up initial location of energyBall
        let energyBall = SKSpriteNode(imageNamed: "energyBall")
        energyBall.position = player.position
        
        energyBall.physicsBody = SKPhysicsBody(circleOfRadius: energyBall.size.width/2)
        energyBall.physicsBody?.dynamic = false
        energyBall.physicsBody?.categoryBitMask = PhysicsCategory.EnergyBall
        energyBall.physicsBody?.contactTestBitMask = PhysicsCategory.Asteroid
        energyBall.physicsBody?.collisionBitMask = PhysicsCategory.None
        energyBall.physicsBody?.usesPreciseCollisionDetection = true
        
        // 3 - Determine offset of location to energyBall
        let offset = touchLocation - energyBall.position
        
        // 4 - Bail out if you are shooting down or backwards
        if (offset.x < 0) { return }
        
        // 5 - OK to add now - you've double checked position
        addChild(energyBall)
        
        // 6 - Get the direction of where to shoot
        let direction = offset.normalized()
        
        // 7 - Make it shoot far enough to be guaranteed off screen
        let shootAmount = direction * 1000
        
        // 8 - Add the shoot amount to the current position
        let realDest = shootAmount + energyBall.position
        
        // 9 - Create the actions
        let actionMove = SKAction.moveTo(realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        energyBall.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        
    }
    
    func energyBallDidCollideWithAsteroid(energyBall:SKSpriteNode, asteroid:SKSpriteNode) {
        println("Hit")
        updateScoreWithValue(1);
        energyBall.removeFromParent()
        asteroid.removeFromParent()
    }
    
    func energyBallDidCollideWithPlayer(energyBall:SKSpriteNode, player:SKSpriteNode){
        println("dead!")
        player.removeFromParent()
        
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        
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
        if ((firstBody.categoryBitMask & PhysicsCategory.Asteroid != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.EnergyBall != 0)) {
                energyBallDidCollideWithAsteroid(firstBody.node as! SKSpriteNode, asteroid: secondBody.node as! SKSpriteNode)
        }
        
        if((firstBody.categoryBitMask & PhysicsCategory.Asteroid != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Player != 0)) {
                energyBallDidCollideWithPlayer(firstBody.node as! SKSpriteNode, player: secondBody.node as! SKSpriteNode)
        }
        
        
        
    }   
}

