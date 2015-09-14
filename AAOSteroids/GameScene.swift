//
//  GameScene.swift
//  AAOSteroids
//
//  Created by Michael Johnson on 4/19/15.
//  Copyright (c) 2015 BobbingHeads. All rights reserved.
//

import SpriteKit
import SceneKit
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
    if backgroundMusicPlayer == nil{
        let url = NSBundle.mainBundle().URLForResource(
            filename, withExtension: nil)
        if (url == nil) {
            print("Could not find file: \(filename)")
            return
        }
        
        var error: NSError? = nil
        do {
            backgroundMusicPlayer =
                try AVAudioPlayer(contentsOfURL: url!)
        } catch let error1 as NSError {
            error = error1
            backgroundMusicPlayer = nil
        }
        backgroundMusicPlayer.volume = 0.3
        if backgroundMusicPlayer == nil {
            print("Could not create audio player: \(error!)")
            return
        }
        
        backgroundMusicPlayer.numberOfLoops = -1
        backgroundMusicPlayer.prepareToPlay()
        backgroundMusicPlayer.play()
    }
}

var score:Int = 0 //The variable holding the score.
var waitTime:Double = 1.5 //var for holding the wait between asteroids
var playerLocation:CGFloat = 0
var playerMoving:Bool = false
var constantStreamOfBall:Bool = true;

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let player = SKSpriteNode(imageNamed: "ship")

    
    func updateScoreWithValue (value: Int) {
        let lblScore = self.childNodeWithName("scoreDisplayLabel") as! SKLabelNode;
        score += value
        lblScore.text = "SCORE: \(score)"
    }
    
    override func didMoveToView(view: SKView) {
        score = 0
        //addStarfield()
        playBackgroundMusic("background-mj.caf")
        
        //set up Physics
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        
        backgroundColor = SKColor.blackColor()
        addShip()
        
        checkScore()
    }
    
    struct PhysicsCategory {
        static let None      : UInt32 = 0
        static let All       : UInt32 = UInt32.max
        static let Asteroid  : UInt32 = 0b1       // 1
        static let EnergyBall: UInt32 = 0b10      // 2
        static let Player    : UInt32 = 0b100
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func checkScore(){
        
        let mod = score>10 ? score % 10 : 1
        if (mod == 0){
            waitTime = waitTime - 0.1
            self.removeActionForKey("asteroid")
            
        }
        self.runAction(SKAction.repeatActionForever(
            SKAction.sequence([
                SKAction.waitForDuration(waitTime),
                SKAction.runBlock(addAsteroid),
                SKAction.runBlock(checkScore)
                ])
            ), withKey:"asteroid")
        
        if (waitTime <= 0.1){
            gameOver()
        }
    }
 
    //MARK: Ship functions
    func destroyShip(){
        shipExplosion(player.position)
        player.removeFromParent()
    }
    
    func addShip(){
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        player.name = "player";
        //Set up the collision detection
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width/2) // 1
        player.physicsBody?.dynamic = false // 2
        player.physicsBody?.categoryBitMask = PhysicsCategory.Player // 3
        player.physicsBody?.contactTestBitMask = PhysicsCategory.Asteroid // 4
        player.physicsBody?.collisionBitMask = PhysicsCategory.None // 5
        
        addChild(player)
    }
    
    override func update(currentTime: NSTimeInterval) {
        if (playerMoving){
            player.position.y = playerLocation
        }
    }
   
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // Choose one of the touches to work with
       
        for touch: AnyObject in touches {
            let touchLocation = (touch as! UITouch).locationInNode(self)
            
            let thePlayer = self.nodeAtPoint(touchLocation)
            if thePlayer.name == "player" {
                //playerMoving = true
                //playerLocation = touchLocation.y
                player.position.y = touchLocation.y
            }
        }
        
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        // Choose one of the touches to work with
        let touch = touches.first!
        let touchLocation = touch.locationInNode(self)
        
        // Set up initial location of energyBall
        let energyBall = SKSpriteNode(imageNamed: "energyBall")
        energyBall.name = "ball"
        energyBall.position = player.position
        energyBall.position.x = energyBall.position.x + 20
        
        energyBall.physicsBody = SKPhysicsBody(circleOfRadius: energyBall.size.width/2)
        energyBall.physicsBody?.dynamic = false
        energyBall.physicsBody?.categoryBitMask = PhysicsCategory.EnergyBall
        energyBall.physicsBody?.contactTestBitMask = PhysicsCategory.Asteroid
        energyBall.physicsBody?.collisionBitMask = PhysicsCategory.None
        energyBall.physicsBody?.usesPreciseCollisionDetection = true
        
        // Determine offset of location to energyBall
        let offset = touchLocation - energyBall.position
        
        // Move Ship if touched beyond the player
        if (offset.x <= 0) {
            return
        }
        
        if (childNodeWithName("ball") == nil || constantStreamOfBall == true){
            runAction(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
            addChild(energyBall)
            
        }
        
        // 6 - Get the direction of where to shoot
        let direction = offset.normalized()
        
        // 7 - Make it shoot far enough to be guaranteed off screen
        let shootAmount = direction * 1000
        
        // 8 - Add the shoot amount to the current position
        let realDest = shootAmount + energyBall.position
        
        // 9 - Create the actions
        let actionMove = SKAction.moveTo(realDest, duration: 1)
        let actionMoveDone = SKAction.removeFromParent()
        
        energyBall.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        
    }
    
    func energyBallDidCollideWithAsteroid(energyBall:SKSpriteNode, asteroid:SKSpriteNode) {
        
        updateScoreWithValue(1);
        energyBall.removeFromParent()
        asteroid.removeFromParent()
        asteroidExplosion(asteroid.position)
        
    }
    
    //MARK: Asteroid functions
    func addAsteroid() {
        
        // Create sprite
        let asteroid = SKSpriteNode(imageNamed: "rocks")
        
        asteroid.physicsBody = SKPhysicsBody(circleOfRadius: asteroid.size.width/2) // 1
        asteroid.physicsBody?.dynamic = true // 2
        asteroid.physicsBody?.categoryBitMask = PhysicsCategory.Asteroid // 3
        asteroid.physicsBody?.contactTestBitMask = PhysicsCategory.EnergyBall // 4
        asteroid.physicsBody?.collisionBitMask = PhysicsCategory.Asteroid // 5
        asteroid.physicsBody?.friction = 0.02
        
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
        let actionMove = SKAction.moveTo(CGPoint(x: -asteroid.size.width/2, y: actualY), duration: NSTimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        
        //let actionMoveDone = SKAction.removeFromParent()
        //let actionMove = SKAction.runBlock({
            asteroid.physicsBody!.applyImpulse(CGVectorMake(0, speed))
        //})
        let loseAction = SKAction.runBlock({self.updateScoreWithValue(-1)})
        
        asteroid.runAction(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
        
    }
    

    
    func asteroidDidCollideWithPlayer(asteroid:SKSpriteNode, player:SKSpriteNode){
        
        runAction(SKAction.sequence([
                SKAction.runBlock(destroyShip),
                SKAction.waitForDuration(2.0),
                SKAction.runBlock(gameOver)
                ]))
    }
    
    
    //MARK: Collision Detection
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
                asteroidDidCollideWithPlayer(firstBody.node as! SKSpriteNode, player: secondBody.node as! SKSpriteNode)
        }
    }
   
    // MARK: Particle Functions
    
    func shipExplosion(pos: CGPoint) {
        let emitterNode = SKEmitterNode(fileNamed: "ExplosionParticle.sks")
        emitterNode!.particlePosition = pos
        self.addChild(emitterNode!)
        runAction(SKAction.playSoundFileNamed("blowdup.caf", waitForCompletion: true))
        // Don't forget to remove the emitter node after the explosion
        self.runAction(SKAction.waitForDuration(2.5), completion: { emitterNode!.removeFromParent() })
        
    }
    func asteroidExplosion(pos: CGPoint) {
        runAction(SKAction.playSoundFileNamed("asteroidDeath.caf", waitForCompletion: false))
        let emitterNode = SKEmitterNode(fileNamed: "AsteroidExplosion.sks")
        emitterNode!.particlePosition = pos
        self.addChild(emitterNode!)
        // Don't forget to remove the emitter node after the explosion
        self.runAction(SKAction.waitForDuration(3), completion: { emitterNode!.removeFromParent() })
        
    }
    
    //MARK: Game OVER MAN!
    func gameOver(){
        waitTime = 1.2
        let reveal = SKTransition.fadeWithDuration(0.5)
        let gameOverScene = GameOverScene(size: self.size, score:score)
        self.view?.presentScene(gameOverScene, transition: reveal)
    }
}

