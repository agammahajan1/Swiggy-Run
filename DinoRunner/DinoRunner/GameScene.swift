//
//  GameScene.swift
//  SwiggyRun
//
//  Created by agam mahajan on 7/07/22.
//  Copyright © 2022 agam mahajan. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //nodes
    var gameNode: SKNode!
    var groundNode: SKNode!
    var backgroundNode: SKNode!
    var cactusNode: SKNode!
    var dinosaurNode: SKNode!
    var birdNode: SKNode!
    
    //score
    var scoreNode: SKLabelNode!
    var resetInstructions: SKLabelNode!
    var score = 0 as Int
    
    //sound effects
    let jumpSound = SKAction.playSoundFileNamed("dino.assets/sounds/jump", waitForCompletion: false)
    let dieSound = SKAction.playSoundFileNamed("dino.assets/sounds/die", waitForCompletion: false)
    
    //sprites
    var dinoSprite: SKSpriteNode!
    
    //spawning vars
    var spawnRate = 1.5 as Double
    var timeSinceLastSpawn = 0.0 as Double
    
    //generic vars
    var groundHeight: CGFloat?
    var dinoYPosition: CGFloat?
    var groundSpeed = 500 as CGFloat
    
    var theatreSpeed = 50 as CGFloat
    
    //consts
    let dinoHopForce = 800 as Int
    let cloudSpeed = 50 as CGFloat
    let moonSpeed = 10 as CGFloat
    
    let background = 0 as CGFloat
    let foreground = 2 as CGFloat
    let middleground = 1 as CGFloat
    
    //collision categories
    let groundCategory = 1 << 0 as UInt32
    let dinoCategory = 1 << 1 as UInt32
    let cactusCategory = 1 << 2 as UInt32
    let birdCategory = 1 << 3 as UInt32
    
    var obstacleTextures = ["cones", "cones3", "trafficStop", "trafficStop2"]
    var obstacleTextures1 = ["cones", "cones3", "trafficStop", "trafficStop2"]
    var obstacleTextures2 = ["cones", "cones3", "trafficStop", "trafficStop2", "horseHurdle"]
    
    let objectAnimationTiming = 0.10 as TimeInterval
    var objectUpdated = false
    
    var indexForBuilding = 0
    
    override func didMove(to view: SKView) {
        
        self.backgroundColor = .white
        
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -9.8)
        
        //ground
        groundNode = SKNode()
        groundNode.zPosition = background
        createAndMoveGround()
        addCollisionToGround()
        
        //background elements
        backgroundNode = SKNode()
        backgroundNode.zPosition = middleground
        createMoon()
        createClouds()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.createTheatre()
        }
        
        //dinosaur
        dinosaurNode = SKNode()
        dinosaurNode.zPosition = foreground
        createDinosaur()
        
        //cacti
        cactusNode = SKNode()
        cactusNode.zPosition = foreground
        
        //birds
        birdNode = SKNode()
        birdNode.zPosition = foreground
        
        //score
        score = 0
        scoreNode = SKLabelNode(fontNamed: "Arial")
        scoreNode.fontSize = 30
        scoreNode.zPosition = foreground
        scoreNode.text = "Score: 0"
        scoreNode.fontColor = SKColor.gray
        scoreNode.position = CGPoint(x: 150, y: 100)
        
        //reset instructions
        resetInstructions = SKLabelNode(fontNamed: "Arial")
        resetInstructions.fontSize = 50
        resetInstructions.text = "Tap to Restart"
        resetInstructions.fontColor = SKColor.white
        resetInstructions.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        
        //parent game node
        gameNode = SKNode()
        gameNode.addChild(groundNode)
        gameNode.addChild(backgroundNode)
        gameNode.addChild(dinosaurNode)
        gameNode.addChild(cactusNode)
        gameNode.addChild(birdNode)
        gameNode.addChild(scoreNode)
        gameNode.addChild(resetInstructions)
        self.addChild(gameNode)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(gameNode.speed < 1.0){
            resetGame()
            return
        }
        
        for _ in touches {
            if let groundPosition = dinoYPosition {
                if dinoSprite.position.y <= groundPosition && gameNode.speed > 0 {
                    dinoSprite.physicsBody?.applyImpulse(CGVector(dx: 0, dy: dinoHopForce))
//                    run(jumpSound)
                }
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if(gameNode.speed > 0){
            groundSpeed += 0.2
            
            score += 1
            scoreNode.text = "Score: \(score/5)"
            
            if(currentTime - timeSinceLastSpawn > spawnRate){
                timeSinceLastSpawn = currentTime
                spawnRate = Double.random(in: 1.0 ..< 3.5)
                
                if(Int.random(in: 0...10) < 8){
                    spawnCactus()
                } else {
                    spawnBird()
                }
            }
        }
        if (score / 5) > 10 {
            updateObjectIcon()
            updateObstacles()
            
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if(hitCactus(contact) || hitBird(contact)){
//            run(dieSound)
            gameOver()
        }
    }
    
    func hitCactus(_ contact: SKPhysicsContact) -> Bool {
        return contact.bodyA.categoryBitMask & cactusCategory == cactusCategory ||
            contact.bodyB.categoryBitMask & cactusCategory == cactusCategory
    }
    
    func hitBird(_ contact: SKPhysicsContact) -> Bool {
        return contact.bodyA.categoryBitMask & birdCategory == birdCategory ||
                contact.bodyB.categoryBitMask & birdCategory == birdCategory
    }
    
    func resetGame() {
        gameNode.speed = 1.0
        timeSinceLastSpawn = 0.0
        groundSpeed = 500
        score = 0
        objectUpdated = false
        
        cactusNode.removeAllChildren()
        birdNode.removeAllChildren()
        
        resetInstructions.fontColor = SKColor.white
        obstacleTextures = obstacleTextures1
//        let dinoTexture1 = SKTexture(imageNamed: "dino.assets/dinosaurs/dinoRight")
//        let dinoTexture2 = SKTexture(imageNamed: "dino.assets/dinosaurs/dinoLeft")
//        dinoTexture1.filteringMode = .nearest
//        dinoTexture2.filteringMode = .nearest
//
//        let runningAnimation = SKAction.animate(with: [dinoTexture1, dinoTexture2], timePerFrame: 0.12)
        
//        let array: [SKTexture] = getObjectAssets(.de)
//        let runningAnimation = SKAction.animate(with: array, timePerFrame: objectAnimationTiming)
//
//        dinoSprite.position = CGPoint(x: self.frame.size.width * 0.15, y: dinoYPosition!)
//        dinoSprite.run(SKAction.repeatForever(runningAnimation))
        dinoSprite.removeFromParent()
        createDinosaur()
    }
    
    func gameOver() {
        gameNode.speed = 0.0
        
        resetInstructions.fontColor = SKColor.gray
        
//        let deadDinoTexture = SKTexture(imageNamed: "dino.assets/horses/game-over")
//        deadDinoTexture.filteringMode = .nearest
//        dinoSprite.size = deadDinoTexture.size()
        dinoSprite.removeAllActions()
//        dinoSprite.texture = deadDinoTexture
    }
    
    func createAndMoveGround() {
        let screenWidth = self.frame.size.width
        
        //ground texture
        let groundTexture = SKTexture(imageNamed: "dino.assets/landscape/ground")
        groundTexture.filteringMode = .nearest
        
        let homeButtonPadding = 50.0 as CGFloat
        groundHeight = groundTexture.size().height + homeButtonPadding
        
        //ground actions
        let moveGroundLeft = SKAction.moveBy(x: -groundTexture.size().width,
                                             y: 0.0, duration: TimeInterval(screenWidth / groundSpeed))
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0.0, duration: 0.0)
        let groundLoop = SKAction.sequence([moveGroundLeft, resetGround])
        
        //ground nodes
        let numberOfGroundNodes = 1 + Int(ceil(screenWidth / groundTexture.size().width))
        
        for i in 0 ..< numberOfGroundNodes {
            let node = SKSpriteNode(texture: groundTexture)
            node.anchorPoint = CGPoint(x: 0.0, y: 0.0)
            node.position = CGPoint(x: CGFloat(i) * groundTexture.size().width, y: groundHeight!)
            groundNode.addChild(node)
            node.run(SKAction.repeatForever(groundLoop))
        }
    }
    
    func addCollisionToGround() {
        let groundContactNode = SKNode()
        groundContactNode.position = CGPoint(x: 0, y: groundHeight! - 30)
        groundContactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width * 3,
                                                                          height: groundHeight!))
        groundContactNode.physicsBody?.friction = 0.0
        groundContactNode.physicsBody?.isDynamic = false
        groundContactNode.physicsBody?.categoryBitMask = groundCategory
        
        groundNode.addChild(groundContactNode)
    }
    
    func createMoon() {
        //texture
        let moonTexture = SKTexture(imageNamed: "dino.assets/landscape/moon")
        let moonScale = 3.0 as CGFloat
        moonTexture.filteringMode = .nearest
        
        //moon sprite
        let moonSprite = SKSpriteNode(texture: moonTexture)
        moonSprite.setScale(moonScale)
        //add to scene
        backgroundNode.addChild(moonSprite)
        
        //animate the moon
        animateMoon(sprite: moonSprite, textureWidth: moonTexture.size().width * moonScale)
    }
    
    func animateMoon(sprite: SKSpriteNode, textureWidth: CGFloat) {
        let screenWidth = self.frame.size.width
        let screenHeight = self.frame.size.height
        
        let distanceOffscreen = 50.0 as CGFloat // want to start the moon offscreen
        let distanceBelowTop = 150 as CGFloat
        
        //moon actions
        let moveMoon = SKAction.moveBy(x: -screenWidth - textureWidth - distanceOffscreen,
                                       y: 0.0, duration: TimeInterval(screenWidth / moonSpeed))
        let resetMoon = SKAction.moveBy(x: screenWidth + distanceOffscreen, y: 0.0, duration: 0)
        let moonLoop = SKAction.sequence([moveMoon, resetMoon])
        
        sprite.position = CGPoint(x: screenWidth + distanceOffscreen, y: screenHeight - distanceBelowTop)
        sprite.run(SKAction.repeatForever(moonLoop))
    }
    
    func createClouds() {
        //texture
        let cloudTexture = SKTexture(imageNamed: "dino.assets/landscape/cloud")
        let cloudScale = 3.0 as CGFloat
        cloudTexture.filteringMode = .nearest
        
        //clouds
        let numClouds = 3
        for i in 0 ..< numClouds {
            //create sprite
            let cloudSprite = SKSpriteNode(texture: cloudTexture)
            cloudSprite.setScale(cloudScale)
            //add to scene
            backgroundNode.addChild(cloudSprite)
            
            //animate the cloud
            animateCloud(cloudSprite, cloudIndex: i, textureWidth: cloudTexture.size().width * cloudScale)
        }
    }
    
    func animateCloud(_ sprite: SKSpriteNode, cloudIndex i: Int, textureWidth: CGFloat) {
        let screenWidth = self.frame.size.width
        let screenHeight = self.frame.size.height
        
        let cloudOffscreenDistance = (screenWidth / 3.0) * CGFloat(i) + 100 as CGFloat
        let cloudYPadding = 50 as CGFloat
        let cloudYPosition = screenHeight - (CGFloat(i) * cloudYPadding) - 200
        
        let distanceToMove = screenWidth + cloudOffscreenDistance + textureWidth
        
        //actions
        let moveCloud = SKAction.moveBy(x: -distanceToMove, y: 0.0, duration: TimeInterval(distanceToMove / cloudSpeed))
        let resetCloud = SKAction.moveBy(x: distanceToMove, y: 0.0, duration: 0.0)
        let cloudLoop = SKAction.sequence([moveCloud, resetCloud])
        
        sprite.position = CGPoint(x: screenWidth + cloudOffscreenDistance, y: cloudYPosition)
        sprite.run(SKAction.repeatForever(cloudLoop))
    }
    
    func createTheatre() {
        //texture
        var asset = "dino.assets/landscape/building4"
        if indexForBuilding % 2 != 0 {
            asset = "dino.assets/landscape/building5"
        }
        let moonTexture = SKTexture(imageNamed: asset)
        let moonScale = 0.8 as CGFloat
        moonTexture.filteringMode = .nearest
        
        //moon sprite
        let moonSprite = SKSpriteNode(texture: moonTexture)
        moonSprite.setScale(moonScale)
        //add to scene
        backgroundNode.addChild(moonSprite)
        
        //animate the moon
        animateTheatre(sprite: moonSprite, textureWidth: moonTexture.size().width * moonScale, textureHeight: moonTexture.size().height*moonScale)
    }
    
    func animateTheatre(sprite: SKSpriteNode, textureWidth: CGFloat, textureHeight: CGFloat) {
        let screenWidth = self.frame.size.width
        let screenHeight = self.frame.size.height
        
        let distanceOffscreen = 400 as CGFloat // want to start the moon offscreen
        let distanceBelowTop = 35 as CGFloat
        
        //moon actions
//        let moveMoon = SKAction.moveBy(x: -screenWidth - textureWidth - distanceOffscreen,
//                                       y: 0.0, duration: TimeInterval(screenWidth / moonSpeed))
//        let resetMoon = SKAction.moveBy(x: screenWidth + distanceOffscreen, y: 0.0, duration: 0)
//        let moonLoop = SKAction.sequence([moveMoon, resetMoon])
//
//        sprite.position = CGPoint(x: screenWidth + distanceOffscreen, y: screenHeight - distanceBelowTop)
//        sprite.run(SKAction.repeatForever(moonLoop))
        
        let moveMoon = SKAction.moveBy(x: -screenWidth - distanceOffscreen - 100,
                                       y: 0.0, duration: TimeInterval((screenWidth) / theatreSpeed))
        let removeCactus = SKAction.removeFromParent()
        let moonLoop = SKAction.sequence([moveMoon, removeCactus])
        
        sprite.position = CGPoint(x: screenWidth + distanceOffscreen, y: getGroundHeight() + textureHeight/2 + distanceBelowTop)
//        sprite.run(SKAction.repeatForever(moonLoop))
        sprite.run(moonLoop)
        sprite.run(moonLoop) {
            self.indexForBuilding += 1
            self.createTheatre()
        }
    }
    
    func createDinosaur() {
        let screenWidth = self.frame.size.width
        let dinoScale = 4.0 as CGFloat
        
        let array: [SKTexture] = getObjectAssets(.de)
        
        let runningAnimation = SKAction.animate(with: array, timePerFrame: objectAnimationTiming)
        let size: CGSize = .init(width: 30, height: 20.0)
        
        dinoSprite = SKSpriteNode()
        dinoSprite.size = size
        dinoSprite.setScale(dinoScale)
        dinosaurNode.addChild(dinoSprite)
        
        let physicsBox = CGSize(width: size.width * dinoScale,
                                height: size.height * dinoScale)
        
        dinoSprite.physicsBody = SKPhysicsBody(rectangleOf: physicsBox)
        dinoSprite.physicsBody?.isDynamic = true
        dinoSprite.physicsBody?.mass = 1.0
        dinoSprite.physicsBody?.categoryBitMask = dinoCategory
        dinoSprite.physicsBody?.contactTestBitMask = birdCategory | cactusCategory
        dinoSprite.physicsBody?.collisionBitMask = groundCategory
        
        dinoYPosition = getGroundHeight() + size.height * dinoScale
        dinoSprite.position = CGPoint(x: screenWidth * 0.15, y: dinoYPosition!)
        dinoSprite.run(SKAction.repeatForever(runningAnimation))
    }
    
    func updateObstacles() {
        obstacleTextures = obstacleTextures2
    }
    
    func spawnCactus() {
        
        //texture
        let obstacleTexture = SKTexture(imageNamed: "dino.assets/cacti/" + obstacleTextures.randomElement()!)
        let obstacleScale = 85/obstacleTexture.size().height as CGFloat
        obstacleTexture.filteringMode = .nearest
        
        //sprite
        let obstacleSprite = SKSpriteNode(texture: obstacleTexture)
        obstacleSprite.setScale(obstacleScale)
        
        //physics
        let contactBox = CGSize(width: obstacleTexture.size().width * obstacleScale,
                                height: obstacleTexture.size().height * obstacleScale)
        obstacleSprite.physicsBody = SKPhysicsBody(rectangleOf: contactBox)
        obstacleSprite.physicsBody?.isDynamic = true
        obstacleSprite.physicsBody?.mass = 1.0
        obstacleSprite.physicsBody?.categoryBitMask = cactusCategory
        obstacleSprite.physicsBody?.contactTestBitMask = dinoCategory
        obstacleSprite.physicsBody?.collisionBitMask = groundCategory
        
        //add to scene
        cactusNode.addChild(obstacleSprite)
        //animate
        animateCactus(sprite: obstacleSprite, texture: obstacleTexture, scale: obstacleScale)
    }
    
    func animateCactus(sprite: SKSpriteNode, texture: SKTexture, scale: CGFloat) {
        let screenWidth = self.frame.size.width
        let distanceOffscreen = 50.0 as CGFloat
        let distanceToMove = screenWidth + distanceOffscreen + texture.size().width * scale
        
        //actions
        let moveCactus = SKAction.moveBy(x: -distanceToMove, y: 0.0, duration: TimeInterval(screenWidth / groundSpeed))
        let removeCactus = SKAction.removeFromParent()
        let moveAndRemove = SKAction.sequence([moveCactus, removeCactus])
        
        sprite.position = CGPoint(x: distanceToMove, y: getGroundHeight() + texture.size().height * scale/2 )
        sprite.run(moveAndRemove)
    }
    
    func spawnBird() {
        //textures
        let birdTexture1 = SKTexture(imageNamed: "dino.assets/dinosaurs/flyer1")
        let birdTexture2 = SKTexture(imageNamed: "dino.assets/dinosaurs/flyer2")
        let birdScale = 3.0 as CGFloat
        birdTexture1.filteringMode = .nearest
        birdTexture2.filteringMode = .nearest
        
        //animation
        let screenWidth = self.frame.size.width
        let distanceOffscreen = 50.0 as CGFloat
        let distanceToMove = screenWidth + distanceOffscreen + birdTexture1.size().width * birdScale
        
        let flapAnimation = SKAction.animate(with: [birdTexture1, birdTexture2], timePerFrame: 0.5)
        let moveBird = SKAction.moveBy(x: -distanceToMove, y: 0.0, duration: TimeInterval(screenWidth / groundSpeed))
        let removeBird = SKAction.removeFromParent()
        let moveAndRemove = SKAction.sequence([moveBird, removeBird])
        
        //sprite
        let birdSprite = SKSpriteNode()
        birdSprite.size = birdTexture1.size()
        birdSprite.setScale(birdScale)
        
        //physics
        let birdContact = CGSize(width: birdTexture1.size().width * birdScale,
                                 height: birdTexture1.size().height * birdScale)
        birdSprite.physicsBody = SKPhysicsBody(rectangleOf: birdContact)
        birdSprite.physicsBody?.isDynamic = false
        birdSprite.physicsBody?.mass = 1.0
        birdSprite.physicsBody?.categoryBitMask = birdCategory
        birdSprite.physicsBody?.contactTestBitMask = dinoCategory
        
        birdSprite.position = CGPoint(x: distanceToMove,
                                      y: getGroundHeight() + birdTexture1.size().height * birdScale + 20)
        birdSprite.run(SKAction.group([moveAndRemove, SKAction.repeatForever(flapAnimation)]))
        
        //add to scene
        birdNode.addChild(birdSprite)
    }
    
    func getGroundHeight() -> CGFloat {
        if let gHeight = groundHeight {
            return gHeight
        } else {
            print("Ground size wasn't previously calculated")
            exit(0)
        }
    }
    
}

extension GameScene {
    
    func getObjectAssets(_ type: ObjectIconType) -> [SKTexture] {
        var array: [SKTexture] = []
        switch type {
        case .de:
            for item in 1...6 {
                let dinoTexture1 = SKTexture(imageNamed: "dino.assets/de/\(item)")
                dinoTexture1.filteringMode = .nearest
                array.append(dinoTexture1)
            }
        case .horses:
            for item in 1...12 {
                let dinoTexture1 = SKTexture(imageNamed: "dino.assets/horses/\(item)")
                dinoTexture1.filteringMode = .nearest
                array.append(dinoTexture1)
            }
        }
        return array
    }
    
    func updateObjectIcon() {
        guard !objectUpdated else { return }
        objectUpdated = true
        
        if let emitterNode = SKEmitterNode(fileNamed: "dino.assets/Sks/explosion") {
            emitterNode.position = CGPoint(x: self.frame.size.width * 0.15, y: dinoYPosition!)
            emitterNode.zPosition = 100
            addChild(emitterNode)
            let remove = SKAction.sequence([SKAction.wait(forDuration: 3), SKAction.removeFromParent()])
            emitterNode.run(remove)
        }
        dinoSprite.removeFromParent()
        
        let screenWidth = self.frame.size.width
        let dinoScale = 4.0 as CGFloat

        let array: [SKTexture] = getObjectAssets(.horses)

        let runningAnimation = SKAction.animate(with: array, timePerFrame: objectAnimationTiming)
        let size: CGSize = .init(width: 30, height: 20.0)
        dinoSprite = SKSpriteNode()
        dinoSprite.size = size
        dinoSprite.setScale(dinoScale)
        dinosaurNode.addChild(dinoSprite)

        let physicsBox = CGSize(width: size.width * dinoScale,
                                height: size.height * dinoScale)

        dinoSprite.physicsBody = SKPhysicsBody(rectangleOf: physicsBox)
        dinoSprite.physicsBody?.isDynamic = true
        dinoSprite.physicsBody?.mass = 1.0
        dinoSprite.physicsBody?.categoryBitMask = dinoCategory
        dinoSprite.physicsBody?.contactTestBitMask = birdCategory | cactusCategory
        dinoSprite.physicsBody?.collisionBitMask = groundCategory

        dinoYPosition = getGroundHeight() + size.height * dinoScale
        dinoSprite.position = CGPoint(x: screenWidth * 0.15, y: dinoYPosition!)
        dinoSprite.run(SKAction.repeatForever(runningAnimation), withKey: "horse")
    }
}

enum ObjectIconType: String {
    case de, horses
}
