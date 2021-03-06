//
//  GameScene.swift
//  Rocket Trip
//
//  Created by Patryk Krajnik on 06/06/2020.
//  Copyright © 2020 Patryk Krajnik. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    var motionManager = CMMotionManager()
    
    var background = SKSpriteNode()
    var rocket = SKSpriteNode()
    var rock = SKSpriteNode()
    
    var scoreLabel: SKLabelNode!
    var infoLabel: SKLabelNode!
    var bestScoreLabel: SKLabelNode!
    
    var destX: CGFloat = 0.0
    var counter = 0
    var seconds = 0
    var highestScoreEasy = 0
    var highestScoreHard = 0
    var numberOfRocket = 1
    var points = 0 {
        didSet {
            scoreLabel.text = "\(points)"
        }
    }
    
    var accelerometer = false
    var startRockCreating = false
    var gameFinished = false
    
    func didBegin(_ contact: SKPhysicsContact) {
        gameFinished = true
        startRockCreating = false
        
        rocket.physicsBody?.affectedByGravity = false
        rocket.physicsBody?.pinned = true
        rocket.physicsBody?.isDynamic = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        infoLabel.run(SKAction.hide())
        accelerometer = true
        startRockCreating = true
        
        rocket.physicsBody?.affectedByGravity = true
        rocket.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        rocket.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 300))
    }
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        motionManager.startAccelerometerUpdates()
        
        createBackground()
        rocketProperties()
        scoreLabelDesign()
        bestScoreLabelDesign()
        
        if UserDefaults.standard.bool(forKey: "hard") {
            let savedScore: Int = UserDefaults.standard.integer(forKey: "highestScoreHard")
            bestScoreLabel.text = "Best: \(savedScore)"
        } else {
            let savedScore: Int = UserDefaults.standard.integer(forKey: "highestScoreEasy")
            bestScoreLabel.text = "Best: \(savedScore)"
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        moveBackground()
        moveX()
        rocket.run(SKAction.moveTo(x: destX, duration: 1))
        sideConstraints()
        createRock()
        
        if gameFinished {
            rocket.run(SKAction.moveTo(x: rocket.position.x, duration: 1))
            motionManager.stopAccelerometerUpdates()
            setHighestScore()
            endGame()
            return
        }
    }
    
    //Design and bit masks of Rocket
    func rocketProperties() {
        numberOfRocket = UserDefaults.standard.integer(forKey: "numberOfRocket")
        rocket = (childNode(withName: "rocket") as? SKSpriteNode)!
        rocket.texture = SKTexture(imageNamed: "flyingRocket\(numberOfRocket)")
        infoLabel = (childNode(withName: "infoLabel") as! SKLabelNode)
        
        rocket.physicsBody?.categoryBitMask = 1
        rocket.physicsBody?.collisionBitMask = 2
        rocket.physicsBody?.contactTestBitMask = 2
    }
    
    //Details of score design
    func scoreLabelDesign() {
        scoreLabel = SKLabelNode(text: "0")
        scoreLabel.position = CGPoint(x: (((self.scene?.size.width)!)/(-4))-50, y: (((self.scene?.size.height)!)/3)+100)
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontSize = 70
        scoreLabel.fontColor = UIColor.yellow
        addChild(scoreLabel)
    }
    
    //Details of best score design
    func bestScoreLabelDesign() {
        bestScoreLabel = SKLabelNode(text: "Best: ")
        bestScoreLabel.position = CGPoint(x: (((self.scene?.size.width)!)/(-4))-50, y: (((self.scene?.size.height)!)/3)+50)
        bestScoreLabel.fontName = "AmericanTypewriter-Bold"
        bestScoreLabel.fontSize = 30
        bestScoreLabel.fontColor = UIColor.yellow
        addChild(bestScoreLabel)
    }
    
    //Moving a Rocket at X axis
    func moveX() {
        if accelerometer == true && motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.01
            motionManager.startAccelerometerUpdates(to: .main) {
                (data, error) in
                guard let data = data, error == nil else {
                    return
                }

                let currentX = self.rocket.position.x
                self.destX = currentX + CGFloat(data.acceleration.x * 3000)
            }
        }
    }
    
    //Setting limits of game area on the sides
    func sideConstraints() {
        let rightConstraint = size.width/2 - 70
        let leftConstraint = rightConstraint*(-1)
        let positionX = rocket.position.x
        
        if (positionX > rightConstraint) {
            rocket.run(SKAction.moveTo(x: rightConstraint, duration: 0.1))
            if destX < rightConstraint {
                rocket.run(SKAction.moveTo(x: destX, duration: 1))
            }
        }
        
        if (positionX < leftConstraint) {
            rocket.run(SKAction.moveTo(x: leftConstraint, duration: 0.1))
            if destX > leftConstraint {
                rocket.run(SKAction.moveTo(x: destX, duration: 1))
            }
        }
    }
    
    //Design of game background
    func createBackground() {
        for i in 0...3 {
            background = SKSpriteNode(imageNamed: "gameBackground")
            background.name = "stars"
            background.size = self.size
            background.position = CGPoint(x: 0, y: CGFloat(i) * background.size.height)
            background.zPosition = -2
            addChild(background)
        }
    }
    
    //Make background moving
    func moveBackground() {
        self.enumerateChildNodes(withName: "stars", using: ({
            (node, error) in
            
            node.position.y -= 2
            
            if node.position.y < -((self.scene?.size.height)!) {
                node.position.y += (self.scene?.size.height)! * 3
            }
        }))
    }
    
    //Creating rocks depending on chosen difficulty level
    func createRock() {
        let rockSize = [80, 90, 100, 110, 120, 130, 140, 150]
        
        if (startRockCreating == true) {
            if UserDefaults.standard.bool(forKey: "hard") {
                counter += 1
                if (counter%4 == 0) {
                    counter += 1
                }
            }
            
            counter += 1
            countPoints()
            
            if (counter%45 == 0) {
                let size = rockSize.randomElement()
                rock = SKSpriteNode(imageNamed: "rock")
                
                if (arc4random_uniform(5)<2) {
                    rock.physicsBody = SKPhysicsBody(circleOfRadius: 75)
                } else {
                    rock.scale(to: CGSize(width: size!, height: size!))
                    rock.physicsBody = SKPhysicsBody(circleOfRadius: CGFloat(size!)*0.5)
                }
                
                rockProperties()
                addChild(rock)
                rock.run(SKAction.sequence([SKAction.wait(forDuration: 5.0), SKAction.removeFromParent()]))
            }
        }
    }
    
    //Design and physic properties of rocks
    func rockProperties() {
        let xAxis = Int(arc4random_uniform(640))-640/2
        let yAxis = Int(1334)
        rock.position = CGPoint(x: xAxis, y: yAxis)
        
        rock.physicsBody?.mass = 0.1
        rock.physicsBody?.linearDamping = 1.0
        
        rock.physicsBody?.categoryBitMask = 2
        rock.physicsBody?.collisionBitMask = 1
        rock.physicsBody?.contactTestBitMask = 1
    }
    
    //Counting the current score of player
    func countPoints() {
        seconds += 1
        if (seconds%60 == 0) {
            points += 1
        }
    }
    
    //Switch to another scene when game finishes
    func endGame() {
        let transition = SKTransition.flipHorizontal(withDuration: 1.0)
        let gameOver = SKScene(fileNamed: "GameOverScene") as! GameOverScene
        
        gameOver.scaleMode = .aspectFill
        gameOver.score = points
        view!.presentScene(gameOver, transition: transition)
    }
    
    //Set the new highest score if it is beaten
    func setHighestScore() {
        let userDefaults = UserDefaults.standard
        
        if (points > userDefaults.integer(forKey: "highestScoreHard")) && userDefaults.bool(forKey: "hard") {
            highestScoreHard = points
            userDefaults.set(highestScoreHard, forKey: "highestScoreHard")
            userDefaults.synchronize()
        }
        
        if (points > userDefaults.integer(forKey: "highestScoreEasy")) && !(userDefaults.bool(forKey: "hard")) {
            highestScoreEasy = points
            userDefaults.set(highestScoreEasy, forKey: "highestScoreEasy")
            userDefaults.synchronize()
        }
    }
}
