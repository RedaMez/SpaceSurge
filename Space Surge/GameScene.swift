//
//  GameScene.swift
//  Space Surge
//
//  Created by Reda Meziane on 20/01/2024.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var gameScore = 0
    let scoreLabel = SKLabelNode(fontNamed: "JungleAdventurer")
    let livesLabel = SKLabelNode(fontNamed: "JungleAdventurer")
    let loserLabel = SKLabelNode(fontNamed: "JungleAdventurer")
    
    let player = SKSpriteNode(imageNamed: "spaceship")
    let bulletSound = SKAction.playSoundFileNamed("bulletSound", waitForCompletion: false)
    let explosionSound = SKAction.playSoundFileNamed("explosionSound", waitForCompletion: false)
    let spaceshipSpeed: CGFloat = 50.0
    
    var livesNumber = 3
    
    var levelNumber = 0
    
    var gameOver = false
    
    struct PhysicsCategories {
        static let None : UInt32 = 0
        static let Player : UInt32 = 0b1
        static let Bullet : UInt32 = 0b10
        static let Asteroid : UInt32 = 0b100
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(0xFFFFFFFF))
    }
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    override func didMove(to view: SKView) {
        let traits: NSFontTraitMask = NSFontTraitMask()
        let font = NSFontManager.shared.font(withFamily: "JungleAdventurer", traits: traits, weight: 5, size: 12 )
        print(font ?? "test")
        
        self.physicsWorld.contactDelegate = self
        
        let background = SKSpriteNode(imageNamed: "background")
        background.size = self.size
        background.position = CGPoint(x: 0, y: 0)
        background.zPosition = 0
        self.addChild(background)
        
        player.setScale(1)
        player.position = CGPoint(x: -self.size.width/3, y: 0)
        player.zPosition = 2
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody!.affectedByGravity = false
        player.physicsBody!.categoryBitMask = PhysicsCategories.Player
        player.physicsBody!.collisionBitMask = PhysicsCategories.None
        player.physicsBody!.contactTestBitMask = PhysicsCategories.Asteroid
        self.addChild(player)
        
        scoreLabel.text = "Score: 0"
        scoreLabel.fontName = "JungleAdventurer"
        scoreLabel.fontSize = 50
        scoreLabel.fontColor = SKColor.white
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        scoreLabel.position = CGPoint(x: 0, y: self.size.height/2 - scoreLabel.fontSize)
        scoreLabel.zPosition = 100
        self.addChild(scoreLabel)
        
        livesLabel.text = "Lives: \(livesNumber)"
        livesLabel.fontSize = 50
        livesLabel.fontColor = SKColor.white
        livesLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        livesLabel.position = CGPoint(x: 0, y: -self.size.height/2 + livesLabel.fontSize)
        livesLabel.zPosition = 100
        self.addChild(livesLabel)

        loserLabel.text = "Loser !"
        loserLabel.fontSize = 100
        loserLabel.fontColor = SKColor.white
        loserLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        loserLabel.position = CGPoint(x: 0, y: 0)
        loserLabel.zPosition = 100
        
        startNewLevel()
    }
    
    func addScore() {
        gameScore += 1
        scoreLabel.text = "Score: \(gameScore)"
        
        if gameScore == 10 || gameScore == 25 || gameScore == 50 {
            startNewLevel()
        }
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var body1 = SKPhysicsBody()
        var body2 = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            body1 = contact.bodyA
            body2 = contact.bodyB
        } else {
            body1 = contact.bodyB
            body2 = contact.bodyA
        }
        
        if body1.categoryBitMask == PhysicsCategories.Player && body2.categoryBitMask == PhysicsCategories.Asteroid {
            // Spaceship hit the asteroid
            
            livesNumber -= 1
            livesLabel.text = "Lives: \(livesNumber)"
            if body1.node != nil {
                spawnExplosion(spawnPosition: body1.node!.position)
            }
            
            if body2.node != nil {
                spawnExplosion(spawnPosition: body2.node!.position)
            }
            body2.node?.removeFromParent()
            if livesNumber == 0 {
                
                body1.node?.removeFromParent()
                self.addChild(loserLabel)
                gameOver = true
            }
                
        }
        
        if body1.categoryBitMask == PhysicsCategories.Bullet && body2.categoryBitMask == PhysicsCategories.Asteroid {
            // Bullet hit the asteroid
            
            addScore()
            
            if body2.node != nil {
                spawnExplosion(spawnPosition: body2.node!.position)
            }
            
            body1.node?.removeFromParent()
            body2.node?.removeFromParent()
        }
    }
    
    func spawnExplosion(spawnPosition: CGPoint){
        let explosion = SKSpriteNode(imageNamed: "explosion")
        explosion.position = spawnPosition
        explosion.zPosition = 3
        explosion.setScale(0)
        self.addChild(explosion)
        
        let scaleIn = SKAction.scale(to: 1, duration: 0.1)
        let fadeOut = SKAction.fadeIn(withDuration: 0.1)
        let delete = SKAction.removeFromParent()
        
        let explosionSequence = SKAction.sequence([explosionSound, scaleIn, fadeOut, delete])
        explosion.run(explosionSequence)
    }
    
    func startNewLevel() {
        
        levelNumber += 1
        
        var asteroidFrequency: TimeInterval
        
        switch levelNumber {
        case 1: asteroidFrequency = 1.2
        case 2: asteroidFrequency = 1
        case 3: asteroidFrequency = 0.8
        case 4: asteroidFrequency = 0.5
        default:
            asteroidFrequency = 0.5
        }
        
        let spawn = SKAction.run(spawnAsteroids)
        let waitToSpawn = SKAction.wait(forDuration: asteroidFrequency)
        let spawnSequence = SKAction.sequence([spawn, waitToSpawn])
        let spawnForever = SKAction.repeatForever(spawnSequence)
        self.run(spawnForever)
    }
    
    func fireBullet() {
        let bullet = SKSpriteNode(imageNamed: "bullet")
        bullet.setScale(1)
        bullet.position = player.position
        bullet.zPosition = 1
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody!.affectedByGravity = false
        bullet.physicsBody!.categoryBitMask = PhysicsCategories.Bullet
        bullet.physicsBody!.collisionBitMask = PhysicsCategories.None
        bullet.physicsBody!.contactTestBitMask = PhysicsCategories.Asteroid
        self.addChild(bullet)
        
        let moveBullet = SKAction.moveTo(x: self.size.width + bullet.size.width, duration: 1)
        let deleteBullet = SKAction.removeFromParent()
        let bulletSequence = SKAction.sequence([bulletSound, moveBullet, deleteBullet])
        bullet.run(bulletSequence)
    }
    
    func spawnAsteroids() {
        let randomYStart = random(min: -self.size.height/2, max: self.size.height/2)
        let randomYEnd = random(min: -self.size.height/2, max: self.size.height/2)
        
        
        var imageNamed = "rock1"
        let randomImage = random(min: 0, max: 1)
        
        // V1
        if randomImage > 0.5 {
            imageNamed = "rock2"
        }
        
        // V2
//        if randomImage > 0.25 {
//            imageNamed = "rock2"
//        }
//        if randomImage > 0.5 {
//            imageNamed = "specialAsteroid"
//        }
//        if randomImage > 0.75 {
//            imageNamed = "specialAsteroid2"
//        }
        
        let asteroid = SKSpriteNode(imageNamed: imageNamed)
        asteroid.setScale(random(min: 0.2, max: 0.7))
        let startPoint = CGPoint(x: self.size.width/2 + asteroid.size.width, y: randomYStart)
        asteroid.position = startPoint
        asteroid.zPosition = 2
        asteroid.physicsBody = SKPhysicsBody(rectangleOf: asteroid.size)
        asteroid.physicsBody!.affectedByGravity = false
        asteroid.physicsBody!.categoryBitMask = PhysicsCategories.Asteroid
        asteroid.physicsBody!.collisionBitMask = PhysicsCategories.None
        asteroid.physicsBody!.contactTestBitMask = PhysicsCategories.Player | PhysicsCategories.Bullet
        self.addChild(asteroid)
        
        let endPoint = CGPoint(x: -self.size.width/2 - asteroid.size.width, y: randomYEnd)
        
        let moveAsteroid = SKAction.move(to: endPoint, duration: random(min: 5, max: 10))
        let rotateAsteroid = SKAction.rotate(byAngle: 5, duration: random(min: 5, max: 10))
        let moveAndRotateAsteroid = SKAction.group([moveAsteroid, rotateAsteroid])
        let deleteAsteroid = SKAction.removeFromParent()
        let asteroidSequence = SKAction.sequence([moveAndRotateAsteroid, deleteAsteroid])
        asteroid.run(asteroidSequence)
    }
    
    override func keyDown(with event: NSEvent) {
        if !gameOver {
            let keyCode = event.keyCode
            switch keyCode {
            case 49:    // Space
                fireBullet()
            case 125:   // Down
                if player.position.y > -self.size.height/2 + player.size.height {
                    let moveDown = SKAction.moveTo(y: player.position.y - spaceshipSpeed, duration: 0.2)
                    player.run(moveDown)
                }
            case 126:   // Up
                if player.position.y < self.size.height/2 - player.size.height {
                    let moveUp = SKAction.moveTo(y: player.position.y + spaceshipSpeed, duration: 0.2)
                    player.run(moveUp)
                }
            default:
                break
            }
        }
    }
    
//    private var label : SKLabelNode?
//    private var spinnyNode : SKShapeNode?
//    
//    override func didMove(to view: SKView) {
//        
//        // Get label node from scene and store it for use later
//        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
//        if let label = self.label {
//            label.alpha = 0.0
//            label.run(SKAction.fadeIn(withDuration: 2.0))
//        }
//        
//        // Create shape node to use during mouse interaction
//        let w = (self.size.width + self.size.height) * 0.05
//        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
//        
//        if let spinnyNode = self.spinnyNode {
//            spinnyNode.lineWidth = 2.5
//            
//            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
//            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
//                                              SKAction.fadeOut(withDuration: 0.5),
//                                              SKAction.removeFromParent()]))
//        }
//    }
//    
//    
//    func touchDown(atPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.green
//            self.addChild(n)
//        }
//    }
//    
//    func touchMoved(toPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.blue
//            self.addChild(n)
//        }
//    }
//    
//    func touchUp(atPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.red
//            self.addChild(n)
//        }
//    }
//    
//    override func mouseDown(with event: NSEvent) {
//        self.touchDown(atPoint: event.location(in: self))
//    }
//    
//    override func mouseDragged(with event: NSEvent) {
//        self.touchMoved(toPoint: event.location(in: self))
//    }
//    
//    override func mouseUp(with event: NSEvent) {
//        self.touchUp(atPoint: event.location(in: self))
//    }
//    
//    override func keyDown(with event: NSEvent) {
//        switch event.keyCode {
//        case 0x31:
//            if let label = self.label {
//                label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
//            }
//        default:
//            print("keyDown: \(event.characters!) keyCode: \(event.keyCode)")
//        }
//    }
//    
//    
//    override func update(_ currentTime: TimeInterval) {
//        // Called before each frame is rendered
//    }
}
