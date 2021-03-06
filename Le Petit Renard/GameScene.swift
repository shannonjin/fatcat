//
//  GameScene.swift
//  fatcat
//
//  Created by Shannon Jin on 6/2/20.
//  Copyright © 2020 Shannon Jin. All rights reserved.
//

import SpriteKit
import GameplayKit
import UIKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var lastUpdateTime : TimeInterval = 0
    
    private var label : SKLabelNode!
    private var score = 0 {
        didSet {
            label.text = "\(score)"
        }
    }
    
    private var fox =  SKSpriteNode()
    private var foxRunFrames: [SKTexture] = []
  
    private var motionManager = CMMotionManager()
    private var destX:CGFloat  = 0.0
    
    struct PhysicsCategory {
      static let none:     UInt32 = 0
      static let all :     UInt32 = UInt32.max
      static let star:     UInt32 = 0b1       // 1
      static let edge:     UInt32 = 0b10      // 2
      static let fox:      UInt32 = 0b100     // 4
      static let loop:     UInt32 = 0b1000    // 8
      static let asteroid: UInt32 = 0b10000 //16
    }
    
    private weak var previousScene: SKScene? = nil
    
    override func sceneDidLoad() {
        
        let background = SKSpriteNode(imageNamed:"background")
        background.position = CGPoint(x:frame.midX , y: frame.midY)
        background.size = self.size
        self.addChild(background)
    }
    
    
    override func didMove(to view: SKView) {
        
        
        physicsWorld.contactDelegate = self
        
        makeFox()
        
        let edge = SKShapeNode()
        let pathToDraw = CGMutablePath()

        pathToDraw.move(to: CGPoint(x: (size.width * -1), y: (size.height * -1)))
        pathToDraw.addLine(to: CGPoint(x:size.width, y:  (size.height * -1)))
        edge.path = pathToDraw
        edge.strokeColor = SKColor.red
        
        label = SKLabelNode()
        label.text = "0"
        label.position = CGPoint(x: frame.midX, y: (frame.height/4))
        label.fontSize = 100
        label.zPosition = 1.0
        addChild(label)
        
        if let path = edge.path{
            edge.physicsBody = SKPhysicsBody(edgeChainFrom: path)
        }
        
        edge.physicsBody?.categoryBitMask = PhysicsCategory.edge
        edge.physicsBody?.contactTestBitMask = PhysicsCategory.edge
        edge.physicsBody?.collisionBitMask = PhysicsCategory.none
        addChild(edge)
   
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addStar),
                SKAction.wait(forDuration: 1.0)
            ])
      ))
        
        run(SKAction.repeatForever(
                   SKAction.sequence([
                       SKAction.wait(forDuration: 5.0),
                       SKAction.run(addAsteroid)
                   ])
             ))
      
    //  let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
    //  backgroundMusic.autoplayLooped = true
    //  addChild(backgroundMusic)*/
    }
    
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
      
        if(firstBody.categoryBitMask & PhysicsCategory.star != 0){
            
            if(secondBody.categoryBitMask & PhysicsCategory.edge != 0){
                
                if let star = firstBody.node as? SKSpriteNode {
                    star.removeFromParent()
                }
            }
            else if(secondBody.categoryBitMask & PhysicsCategory.fox != 0){
                
                if let star = firstBody.node as? SKSpriteNode {
                    score += Int(star.size.width/20)
                    star.removeFromParent()
                }
            }
        }
        else if(firstBody.categoryBitMask & PhysicsCategory.edge != 0){
           
            if let asteroid = secondBody.node as? SKSpriteNode {
                asteroid.removeFromParent()
            }
        }
        else if(firstBody.categoryBitMask & PhysicsCategory.fox != 0){
            if let asteroid = secondBody.node as? SKSpriteNode {
                score -= Int(asteroid.size.width/5)
                if(score <= 0){
                    
                    let gameOverScene = GameOverScene(fileNamed:"GameOverScene")
                    
                    if let gameOverScene = gameOverScene{
                        gameOverScene.scaleMode = .aspectFit
                        self.removeAllActions()
                        self.removeAllChildren()
                        let reveal = SKTransition.crossFade(withDuration: 1.0)
                        self.view?.presentScene(gameOverScene, transition:reveal)
                    }
                    
                }
            }
        }
    }
    
    func addStar(){
        
          let star = SKSpriteNode(imageNamed: "star")
          
          let scale = CGFloat.random(in: 0.1 ... 0.5)
          star.xScale = scale
          star.yScale = scale
          star.zPosition = 1.0
          
          star.physicsBody = SKPhysicsBody(rectangleOf: star.size)
          star.physicsBody?.linearDamping = 1.0
          star.physicsBody?.friction = 1.0
          
          star.physicsBody?.isDynamic = true // 2
          star.physicsBody?.categoryBitMask = PhysicsCategory.star // 3
          star.physicsBody?.contactTestBitMask = PhysicsCategory.star | PhysicsCategory.edge | PhysicsCategory.fox
          star.physicsBody?.collisionBitMask = PhysicsCategory.none
          
          let actualX = CGFloat.random(in: (-1*size.width/2)+50 ... (size.width/2)-50)
         
          star.position = CGPoint(x: actualX, y: self.size.height)
          addChild(star)
      }
    
    func makeFox(){
        let foxAnimatedAtlas = SKTextureAtlas(named: "fox")
        var runFrames: [SKTexture] = []
        
        let numImages = foxAnimatedAtlas.textureNames.count
        
        for i in 1...numImages{
            let foxTextureName = "fox\(i)"
            runFrames.append(foxAnimatedAtlas.textureNamed(foxTextureName))
        }
        foxRunFrames = runFrames
        
        let firstFrameTexture = foxRunFrames[0]
        fox = SKSpriteNode(texture: firstFrameTexture)
        let actualY = CGFloat((size.height/2) * -1 * 0.6)
        fox.position = CGPoint(x: frame.midX, y:actualY)
        fox.xScale = 2.5
        fox.yScale = 2.5
        fox.zPosition = 1.0
        fox.physicsBody = SKPhysicsBody(rectangleOf: fox.size)
        fox.physicsBody?.affectedByGravity = false
        fox.physicsBody?.contactTestBitMask = 0b11111
        fox.physicsBody?.categoryBitMask = PhysicsCategory.fox
        fox.physicsBody?.collisionBitMask = PhysicsCategory.loop | PhysicsCategory.asteroid
        
        let xRange = SKRange(lowerLimit:(-1 * size.width/2),upperLimit:size.width/2)
        let yRange = SKRange(lowerLimit:actualY,upperLimit:actualY)
        //sprite.constraints = [SKConstraint.positionX(xRange,Y:yRange)] // iOS 9
        fox.constraints = [SKConstraint.positionX(xRange,y:yRange)]  // iOS 10
        addChild(fox)
        
        if motionManager.isAccelerometerAvailable {
        motionManager.accelerometerUpdateInterval = 0.01
        motionManager.startAccelerometerUpdates(to: .main) {
            [weak self]
            (data, error) in
            guard let data = data, error == nil else {
                return
            }
            
            if let scene = self{
                let currentX = scene.fox.position.x
                scene.destX = currentX + CGFloat(data.acceleration.x * 500)
            }
            
            }
        }
    }
 
    func animateFox() {
      fox.run(SKAction.repeatForever(
        SKAction.animate(with: foxRunFrames,
                         timePerFrame: 0.1,
                         resize: false,
                         restore: true)),
               withKey:"runningInPlaceFox")
    }
    
    func moveFox() {
        
        var multiplierForDirection: CGFloat = 1.0
        
        if let accelerometerData = motionManager.accelerometerData {
            if(accelerometerData.acceleration.x < 0){
                multiplierForDirection = -1.0
            }
        }
        
        fox.xScale = abs(fox.xScale) * multiplierForDirection
        
        if fox.action(forKey: "runningInPlaceFox") == nil {
            // if legs are not moving, start them
            animateFox()
            
        }

        let moveAction = SKAction.moveTo(x: destX, duration: 0.5)
        
        let doneAction = SKAction.run({ [weak self] in
             self?.foxMoveEnded()
           })
        
      let moveActionWithDone = SKAction.sequence([moveAction, doneAction])
      fox.run(moveActionWithDone, withKey:"foxMoving")
    }
    
    func foxMoveEnded() {
      fox.removeAllActions()
    }
    
 
    override func update(_ currentTime: TimeInterval) {
        
        let action = SKAction.run({ [weak self] in
          self?.moveFox()
        })
        
        fox.run(action)
    }
    
    func addAsteroid(){
        let asteroidAnimatedAtlas = SKTextureAtlas(named: "asteroid_medium")
        var runFrames: [SKTexture] = []
        
        let numImages = asteroidAnimatedAtlas.textureNames.count
        
        for i in 1...numImages{
            let asteroidTextureName = "a\(i)"
            runFrames.append(asteroidAnimatedAtlas.textureNamed(asteroidTextureName))
        }
        
        let firstFrameTexture = runFrames[0]
        let asteroid = SKSpriteNode(texture: firstFrameTexture)
        let actualX = CGFloat.random(in: (-1*size.width/2)+50 ... (size.width/2)-50)
        
        asteroid.position = CGPoint(x: actualX, y: size.height)
        
        if(score > 300){
            let scale = CGFloat.random(in: 1.0 ... 3.0)
            asteroid.xScale = scale
            asteroid.yScale = scale
        }
        
        asteroid.zPosition = 1.0
        
        asteroid.physicsBody = SKPhysicsBody(rectangleOf: asteroid.size)
        asteroid.physicsBody?.linearDamping = 1.0
        asteroid.physicsBody?.friction = 1.0
        
        asteroid.physicsBody?.isDynamic = true // 2
        asteroid.physicsBody?.categoryBitMask = PhysicsCategory.asteroid // 3
        asteroid.physicsBody?.contactTestBitMask = PhysicsCategory.fox | PhysicsCategory.edge
        asteroid.physicsBody?.collisionBitMask = PhysicsCategory.fox
        
        
        addChild(asteroid)
        
        asteroid.run(SKAction.repeatForever(
        SKAction.animate(with: runFrames,
                         timePerFrame: 0.1,
                         resize: false,
                         restore: true)),
               withKey:"fallingAsteroid")
        

    }

    deinit{
        print("deinit")
    }
}


