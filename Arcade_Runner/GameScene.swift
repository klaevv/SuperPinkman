//
//  GameScene.swift
//  Arcade_Runner
//
//  Created by Leevi on 16/05/16.
//  Copyright (c) 2016 TERVAdev. All rights reserved.
//

import SpriteKit
import AVFoundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


// MARK: Text Constants
let kFont = "Copperplate-Bold"
var kFontSize: CGFloat = 24.0
let kFontColour = SKColor.white
// MARK: UI Positions
var kYLowMargin: CGFloat = 60
var kYHighMargin: CGFloat = 50
var kYHighMarginWithAds: CGFloat = 90
var kButtonGapMargin: CGFloat = 75
var kMenuWheelYPos: CGFloat = 110
var menuLastScoreMargin: CGFloat = 200
var menuHighScoreMargin: CGFloat = 240
var menuTitleHighMargin: CGFloat = 120
var leftMargin: CGFloat = 12.0
var rowGap: CGFloat = 25.0
var groundMarginY: CGFloat = 1

// MARK: Hints
let kHints = ["\"Pinkman moves as fast as you can tap\"",
              "\"Use both thumbs to move in one direction\"",
              "\"Anticipate where you should move\"",
              "\"Use any amount of fingers to tap\"",
              "\"Keep practicing your tapping\"",
              "\"Remember not to exhaust your fingers\"",
              "\"Winners never quit\"",
              "\"Pinkman can deadlift 200 kg\"",
              "\"Pinkman is always happy\"",
              "\"Did you know: Pinkman is cool\"",
              "\"Pinkman knows how to dodge\"",
              "\"Pinkman can survive armageddon\""]

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: z Layers
    let layerIntro = SKNode()
    let layerUIMenu = SKNode()
    let layerUISettings = SKNode()
    let layerUICredits = SKNode()
    let layerUIBg = SKNode()
    let layerGameFront = SKNode()
    let layerGameMiddle = SKNode()
    let layerGameRear = SKNode()
    // MARK: Parameters
    lazy var dt: TimeInterval = TimeInterval()
    var lastUpdateTime: TimeInterval?
    var score = 0
    var scoreLabel = SKLabelNode(fontNamed: kFont)
    var lastScoreLabel = SKLabelNode(fontNamed: kFont)
    var highScoreLabel = SKLabelNode(fontNamed: kFont)
    var randomHintLabel = SKLabelNode(fontNamed: kFont)
    var lastScore: Int?
    var didHighscore = false
    var lastPlayerX: CGFloat = -1
    var gameStateOn = false
    var playerStep: CGFloat!
    var fallingSpeed: CGFloat = 370.0
    var spawnRate: Double = 0.42
    // MARK: Game Constants
    let playerCollisionCategory: UInt32 = 0x1 << 0
    let fallingCollisionCategory: UInt32 = 0x1 << 1
    let kGroundY: CGFloat = SKSpriteNode(imageNamed: "ground_block").size.height
    let data = AppData()
    var music = AVAudioPlayer()
    
    
    // MARK: Init Scene
    
    override func didMove(to view: SKView) {
        
        groundMarginY = size.height - 450;
        playerStep = size.width / 16
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
            kFontSize += 10.0
            kYLowMargin *= 1.2
            kYHighMargin *= 2.0
            kButtonGapMargin *= 2.0
            kYHighMarginWithAds *= 2.0
            kMenuWheelYPos *= 2.0
            menuLastScoreMargin *= 2.0
            menuHighScoreMargin *= 2.0
            menuTitleHighMargin *= 2.0
            leftMargin *= 2.0
            rowGap *= 2.0
            groundMarginY -= CGFloat(450.0)
            fallingSpeed *= 2.0
            
        }
        
        isUserInteractionEnabled = true
        physicsWorld.contactDelegate = self
        scene?.backgroundColor = SKColor.blueSkyColour()
        
        layerIntro.zPosition = 100; addChild(layerIntro)
        layerUIMenu.zPosition = 1100; addChild(layerUIMenu)
        layerUISettings.zPosition = 1000; addChild(layerUISettings)
        layerUICredits.zPosition = 999; addChild(layerUICredits)
        layerUIBg.zPosition = 900; addChild(layerUIBg)
        layerGameFront.zPosition = 800; addChild(layerGameFront)
        layerGameMiddle.zPosition = 700; addChild(layerGameMiddle)
        layerGameRear.zPosition = 600; addChild(layerGameRear)
        
        initMenu()
        initSettings()
        initCredits()
        playMusic()
        showFirstScreen()
        
    }
    
    fileprivate func playMusic() {
        
        let path = Bundle.main.path(forResource: "Victory_loop", ofType: "caf")
        let url = URL(fileURLWithPath: path!)
        do {
            music = try AVAudioPlayer(contentsOf: url)
        }
        catch {
            // ...
        }
        music.numberOfLoops = -1
        music.prepareToPlay()
        let playLoop = { () -> Void in
            self.music.play()
        }
        if !self.data.getMute() {
            let playIntro = SKAction.playSoundFileNamed("Victory_intro.caf", waitForCompletion: true)
            layerUISettings.run(SKAction.sequence([playIntro, SKAction.run(playLoop)]))
        }
        
    }
    
    // MARK: Node Layers
    
    fileprivate func hideLayerUIMenu() {
        
        layerUIMenu.isHidden = true
        
    }
    
    fileprivate func showLayerUIMenu() {
        
        layerUIMenu.isHidden = false
        
    }
    
    fileprivate func hideLayerUISettings() {
        
        layerUISettings.isHidden = true
        
    }
    
    fileprivate func showLayerUISettings() {
        
        layerUISettings.isHidden = false
        
    }
    
    fileprivate func hideLayerUICredits() {
        
        layerUICredits.isHidden = true
        
    }
    
    fileprivate func showLayerUICredits() {
        
        layerUICredits.isHidden = false
        
    }
    
    fileprivate func hideLayerUIBg() {
        
        layerUIBg.isHidden = true
        
    }
    
    fileprivate func showLayerUIBg() {
        
        layerUIBg.isHidden = false
        
    }
    
    fileprivate func hideLayerGameFront() {
        
        layerGameFront.isHidden = true
        
    }
    
    fileprivate func showLayerGameFront() {
        
        layerGameFront.isHidden = false
        
    }
    
    fileprivate func hideLayerGameMiddle() {
        
        layerGameMiddle.isHidden = true
        
    }
    
    fileprivate func showLayerGameMiddle() {
        
        layerGameMiddle.isHidden = false
        
    }
    
    fileprivate func hideLayerGameRear() {
        
        layerGameRear.isHidden = true
        
    }
    
    fileprivate func showLayerGameRear() {
        
        layerGameRear.isHidden = false
        
    }
    
    fileprivate func clearGameLayers() {
        
        layerGameFront.removeAllChildren(); layerGameFront.removeAllActions()
        layerGameMiddle.removeAllChildren(); layerGameMiddle.removeAllActions()
        layerGameRear.removeAllChildren(); layerGameRear.removeAllActions()
        
    }
    
    // MARK: Node setup
    
    fileprivate func showFirstScreen() {
        
        let soundAction = SKAction.playSoundFileNamed("stamp", waitForCompletion: false)
        
        let tervadevLabel = SKLabelNode(fontNamed: kFont)
        tervadevLabel.position = CGPoint(x: scene!.size.width / 2, y: scene!.size.height - kYHighMarginWithAds)
        tervadevLabel.text = "tervadev 2016"
        tervadevLabel.fontSize = kFontSize
        tervadevLabel.fontColor = kFontColour
        layerIntro.addChild(tervadevLabel)
        
        let playerNode = SKSpriteNode(imageNamed: "player")
        playerNode.position = CGPoint(x: scene!.size.width / 2, y: scene!.size.height / 2 + kYLowMargin)
        
        let initPlayerBlock = { () -> Void in
            self.layerIntro.run(soundAction)
            self.layerIntro.addChild(playerNode)
        }
        let titleBlock = { () -> Void in
            self.layerIntro.run(soundAction)
            let titleLabel = SKLabelNode(fontNamed: kFont)
            titleLabel.position = CGPoint(x: self.scene!.size.width / 2, y: self.scene!.size.height / 2)
            titleLabel.text = "SUPER PINKMAN"
            titleLabel.fontSize = kFontSize + 8
            titleLabel.fontColor = UIColor.pinkHotColour()
            self.layerIntro.addChild(titleLabel)
        }
        let playerBlock = { () -> Void in
            self.layerIntro.run(soundAction)
            let texture = SKTexture(imageNamed: "player_intro")
            playerNode.size = texture.size()
            playerNode.texture = texture
        }
        let menuBlock = { () -> Void in
            self.layerIntro.run(soundAction)
            let startButton = SKSpriteNode(imageNamed: "button_green")
            startButton.name = "startB"
            startButton.position = CGPoint(x: self.scene!.size.width / 2, y: kYLowMargin)
            self.layerIntro.addChild(startButton)
            
            let startLabel = SKLabelNode(fontNamed: kFont)
            startLabel.name = "startL"
            startLabel.position = startButton.position
            startLabel.zPosition = startButton.zPosition + 10
            startLabel.text = "START"
            startLabel.fontSize = kFontSize
            startLabel.fontColor = kFontColour
            self.layerIntro.addChild(startLabel)
        }
        let wait = SKAction.wait(forDuration: 0.7)
        layerIntro.run(SKAction.sequence([wait, SKAction.run(initPlayerBlock), wait, SKAction.run(titleBlock), wait, SKAction.run(playerBlock), wait, SKAction.run(menuBlock)]))
        
    }
    
    fileprivate func initMenu() {
        
        clearGameLayers()
        
        // title
        let titleLabel = SKLabelNode(fontNamed: kFont)
        titleLabel.position = CGPoint(x: scene!.size.width / 2, y: size.height - menuTitleHighMargin)
        titleLabel.zPosition = 100
        titleLabel.text = "SUPER PINKMAN"
        titleLabel.fontSize = kFontSize + 8
        titleLabel.fontColor = UIColor.pinkHotColour()
        titleLabel.zRotation = CGFloat(M_PI / 8)
        layerUIMenu.addChild(titleLabel)
        
        let shrink = SKAction.scale(to: 0.8, duration: 0.6)
        let grow = SKAction.scale(to: 1.2, duration: 0.6)
        let sequence = SKAction.sequence([shrink, grow])
        let repeatPulse = SKAction.repeatForever(sequence)
        titleLabel.run(repeatPulse)
        
        // last score label
        lastScore = (lastScore != nil ? lastScore! : 0)
        lastScoreLabel.position = CGPoint(x: titleLabel.position.x, y: scene!.size.height - menuLastScoreMargin)
        lastScoreLabel.text = "last score: " + String(lastScore!)
        lastScoreLabel.fontSize = kFontSize
        lastScoreLabel.fontColor = kFontColour
        layerUIMenu.addChild(lastScoreLabel)
        
        // high score label
        highScoreLabel.position = CGPoint(x: titleLabel.position.x, y: scene!.size.height - menuHighScoreMargin)
        highScoreLabel.text = "best score: " + String(data.getHighscore())
        highScoreLabel.fontSize = kFontSize
        highScoreLabel.fontColor = kFontColour
        layerUIMenu.addChild(highScoreLabel)
        
        // play button
        let playButton = SKSpriteNode(imageNamed: "button_green")
        playButton.name = "playB"
        playButton.position = CGPoint(x: scene!.size.width / 2, y: kYLowMargin)
        layerUIMenu.addChild(playButton)
        
        let playLabel = SKLabelNode(fontNamed: kFont)
        playLabel.name = "playL"
        playLabel.position = playButton.position
        playLabel.zPosition = playButton.zPosition + 10
        playLabel.text = "PLAY"
        playLabel.fontSize = kFontSize
        playLabel.fontColor = kFontColour
        layerUIMenu.addChild(playLabel)
        
        // settings button
        let settingsButton = SKSpriteNode(imageNamed: "button_green")
        settingsButton.name = "settingsB"
        settingsButton.position = CGPoint(x: playButton.position.x, y: playButton.position.y + kButtonGapMargin)
        layerUIMenu.addChild(settingsButton)
        
        let settingsLabel = SKLabelNode(fontNamed: kFont)
        settingsLabel.name = "settingsL"
        settingsLabel.position = settingsButton.position
        settingsLabel.zPosition = settingsButton.zPosition + 10
        settingsLabel.text = "SETTINGS"
        settingsLabel.fontSize = kFontSize
        settingsLabel.fontColor = kFontColour
        layerUIMenu.addChild(settingsLabel)
        
        // credits button
        let creditsButton = SKSpriteNode(imageNamed: "button_green")
        creditsButton.name = "creditsB"
        creditsButton.position = CGPoint(x: settingsButton.position.x, y: settingsButton.position.y + kButtonGapMargin)
        layerUIMenu.addChild(creditsButton)
        
        let creditsLabel = SKLabelNode(fontNamed: kFont)
        creditsLabel.name = "creditsL"
        creditsLabel.position = creditsButton.position
        creditsLabel.zPosition = creditsButton.zPosition + 10
        creditsLabel.text = "CREDITS"
        creditsLabel.fontSize = kFontSize
        creditsLabel.fontColor = kFontColour
        layerUIMenu.addChild(creditsLabel)
        
        // menu bg
        let menuBg = SKSpriteNode(imageNamed: "bg")
        menuBg.position = CGPoint(x: playButton.position.x, y: kYLowMargin)
        layerUIBg.addChild(menuBg)
        
        let rotate = SKAction.rotate(byAngle: CGFloat(M_PI), duration: 3.2)
        let repeatRotation = SKAction.repeatForever(rotate)
        menuBg.run(repeatRotation)
        
        hideLayerUIMenu(); hideLayerUIBg()
        
    }
    
    fileprivate func initSettings() {
        
        let backButton = SKSpriteNode(imageNamed: "button_green")
        backButton.name = "backB"
        backButton.position = CGPoint(x: scene!.size.width / 2, y: kYLowMargin)
        layerUISettings.addChild(backButton)
        
        let backLabel = SKLabelNode(fontNamed: kFont)
        backLabel.name = "backL"
        backLabel.position = backButton.position
        backLabel.zPosition = backButton.zPosition + 10
        backLabel.text = "BACK"
        backLabel.fontSize = kFontSize
        backLabel.fontColor = kFontColour
        layerUISettings.addChild(backLabel)
        
        let muteButton = SKSpriteNode(imageNamed: "button_green")
        muteButton.name = "muteB"
        muteButton.position = CGPoint(x: backButton.position.x, y: backButton.position.y + kButtonGapMargin)
        layerUISettings.addChild(muteButton)
        
        let muteLabel = SKLabelNode(fontNamed: kFont)
        muteLabel.name = "muteL"
        muteLabel.position = muteButton.position
        muteLabel.zPosition = muteButton.zPosition + 10
        muteLabel.text = "TOGGLE MUSIC"
        muteLabel.fontSize = kFontSize
        muteLabel.fontColor = kFontColour
        layerUISettings.addChild(muteLabel)
        
        let hintButton = SKSpriteNode(imageNamed: "button_green")
        hintButton.name = "hintB"
        hintButton.position = CGPoint(x: backButton.position.x, y: muteButton.position.y + kButtonGapMargin)
        layerUISettings.addChild(hintButton)
        
        let hintLabel = SKLabelNode(fontNamed: kFont)
        hintLabel.name = "hintL"
        hintLabel.position = hintButton.position
        hintLabel.zPosition = hintButton.zPosition + 10
        hintLabel.text = "NEXT HINT"
        hintLabel.fontSize = kFontSize
        hintLabel.fontColor = kFontColour
        layerUISettings.addChild(hintLabel)
        
        randomHintLabel.position = CGPoint(x: hintButton.position.x, y: scene!.size.height - kYHighMarginWithAds)
        randomHintLabel.zPosition = hintButton.zPosition + 10
        let r: Range<Int> = 0..<kHints.count
        randomHintLabel.text = kHints[Int.random(r)]
        randomHintLabel.fontSize = kFontSize - 10.0
        randomHintLabel.fontColor = kFontColour
        layerUISettings.addChild(randomHintLabel)
        
        let size = CGSize(width: scene!.size.width, height: kYHighMarginWithAds + 10)
        let upperBlackBox = SKSpriteNode(color: SKColor.black, size: size)
        upperBlackBox.anchorPoint = CGPoint(x: 0, y: 1)
        upperBlackBox.position = CGPoint(x: 0, y: scene!.size.height)
        upperBlackBox.zPosition = -1
        upperBlackBox.alpha = 0.5
        layerUISettings.addChild(upperBlackBox)
        
        hideLayerUISettings()
        
    }
    
    fileprivate func initCredits() {
        
        let backButton = SKSpriteNode(imageNamed: "button_green")
        backButton.name = "backB"
        backButton.position = CGPoint(x: scene!.size.width / 2, y: kYLowMargin)
        layerUICredits.addChild(backButton)
        
        let backLabel = SKLabelNode(fontNamed: kFont)
        backLabel.name = "backL"
        backLabel.position = backButton.position
        backLabel.zPosition = backButton.zPosition + 10
        backLabel.text = "BACK"
        backLabel.fontSize = kFontSize
        backLabel.fontColor = kFontColour
        layerUICredits.addChild(backLabel)
        
        let size = CGSize(width: scene!.size.width, height: scene!.size.height / 2)
        let upperBlackBox = SKSpriteNode(color: SKColor.black, size: size)
        upperBlackBox.anchorPoint = CGPoint(x: 0, y: 1)
        upperBlackBox.position = CGPoint(x: 0, y: scene!.size.height)
        upperBlackBox.zPosition = -1
        upperBlackBox.alpha = 0.5
        layerUICredits.addChild(upperBlackBox)
        
        let first = SKLabelNode(fontNamed: kFont)
        first.position = CGPoint(x: scene!.size.width / 2, y: scene!.size.height - kYHighMarginWithAds)
        first.text = "code & design: tervadev"
        first.fontSize = kFontSize - 5.0
        first.fontColor = kFontColour
        layerUICredits.addChild(first)
        
        let second = SKLabelNode(fontNamed: kFont)
        second.position = CGPoint(x: scene!.size.width / 2, y: first.position.y - rowGap)
        second.text = "music: Bryan Teoh (www.sleepfacingwest.com)"
        second.fontSize = kFontSize - 12.0
        second.fontColor = kFontColour
        layerUICredits.addChild(second)
        
        let third = SKLabelNode(fontNamed: kFont)
        third.position = CGPoint(x: scene!.size.width / 2, y: second.position.y - rowGap)
        third.text = "sprites: www.kenney.nl"
        third.fontSize = kFontSize - 5.0
        third.fontColor = kFontColour
        layerUICredits.addChild(third)
        
        hideLayerUICredits()
        
    }
    
    fileprivate func showGameScene() {
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "gameStateChanged"), object: nil)
        
        hideLayerUIMenu(); hideLayerUIBg()
        showLayerGameFront(); showLayerGameMiddle(); showLayerGameRear()
        
        fallingSpeed = 370.0
        spawnRate = 0.42
        if UIDevice.current.userInterfaceIdiom == .pad {
            fallingSpeed *= 2
            // spawnRate *= 2
        }
        gameStateOn = true
        didHighscore = false
        score = 0
        
        scoreLabel.position = CGPoint(x: scene!.size.width / 2, y: scene!.size.height - 50)
        scoreLabel.text = String(score)
        scoreLabel.fontSize = kFontSize + 18.0
        scoreLabel.fontColor = kFontColour
        layerGameFront.addChild(scoreLabel)
        
        var i: CGFloat = 0.0
        var x: CGFloat = 0.0
        repeat {
            let grassNode = SKSpriteNode(imageNamed: "grass_block")
            grassNode.anchorPoint = CGPoint.zero
            grassNode.position = CGPoint(x: grassNode.size.width * i, y: groundMarginY)
            layerGameRear.addChild(grassNode)
            x = grassNode.position.x
            i += 1
        } while x < scene!.size.width
        
        i = 0.0
        x = 0.0
        var y = groundMarginY
        var j: CGFloat = 1.0
        repeat {
            repeat {
                let groundNode = SKSpriteNode(imageNamed: "ground_block")
                groundNode.anchorPoint = CGPoint.zero
                groundNode.position = CGPoint(x: groundNode.size.width * i, y: groundMarginY - groundNode.size.height * j)
                layerGameRear.addChild(groundNode)
                x = groundNode.position.x; y = groundNode.position.y + groundNode.size.height
                i += 1
            } while x < scene!.size.width
            i = 0; x = 0; j += 1
        } while y > 0
        
    }
    
    fileprivate func showPlayer() {
        
        let node = SKSpriteNode(imageNamed: "player")
        node.name = "player"
        node.anchorPoint = CGPoint.zero
        node.position = CGPoint(x: scene!.size.width / 2, y: kGroundY + groundMarginY)
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody!.affectedByGravity = false
        node.physicsBody!.contactTestBitMask = playerCollisionCategory
        layerGameFront.addChild(node)
        
    }
    
    fileprivate func showFallingObjectAtRandomX(_ x: CGFloat) {
        
        let node = SKSpriteNode(imageNamed: giveRandomFallingFile())
        node.name = "falling"
        node.anchorPoint = CGPoint.zero
        node.position = CGPoint(x: x, y: scene!.size.height + node.size.height)
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody!.affectedByGravity = false
        node.physicsBody!.contactTestBitMask = fallingCollisionCategory
        layerGameMiddle.addChild(node)
        
    }
    
    fileprivate func showHighScoreLabel() {
        
        let backLabel = SKLabelNode(fontNamed: kFont)
        backLabel.name = "backL"
        backLabel.position = CGPoint(x: scene!.size.width / 2, y: 400)
        backLabel.text = "HIGHSCORE"
        backLabel.fontSize = kFontSize
        backLabel.fontColor = kFontColour
        layerGameFront.addChild(backLabel)
        
    }
    
    // MARK: Game Mechanics
    
    fileprivate func giveRandomFallingFile() -> String {
        
        let files = ["falling_box", "falling_box2", "falling_slime", "falling_lock", "falling_chip", "falling_dice"]
        let r: Range<Int> = 0..<files.count
        return files[Int.random(r)]
        
    }
    
    fileprivate func updateScore() {
        
        scoreLabel.text = String(score)
        
    }
    
    fileprivate func gameOver() {
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "gameStateChanged"), object: nil)
        
        destroyGameProps()
        
        gameStateOn = false
        
        lastScore = score
        lastScoreLabel.text = "last score: " + String(lastScore!)
        if lastScore > data.getHighscore() {
            data.setHighscore(lastScore!)
            highScoreLabel.text = "best score: " + String(data.getHighscore())
            let highScoreBlock = { () -> Void in
                let highScoreLabel = SKLabelNode(fontNamed: kFont)
                highScoreLabel.position = CGPoint(x: self.scene!.size.width / 2, y: self.scene!.size.height - kYHighMarginWithAds)
                highScoreLabel.text = "HIGHSCORE!"
                highScoreLabel.fontSize = kFontSize
                highScoreLabel.fontColor = kFontColour
                self.layerGameFront.addChild(highScoreLabel)
                self.layerGameFront.run(SKAction.playSoundFileNamed("highscore.caf", waitForCompletion: false))
            }
            run(SKAction.sequence([SKAction.wait(forDuration: 0.8), SKAction.run(highScoreBlock)]))
        }
        else {
            let highScoreBlock = { () -> Void in
                let highScoreLabel = SKLabelNode(fontNamed: kFont)
                highScoreLabel.position = CGPoint(x: self.scene!.size.width / 2, y: self.scene!.size.height - kYHighMarginWithAds)
                highScoreLabel.text = "GOOD RUN!"
                highScoreLabel.fontSize = kFontSize
                highScoreLabel.fontColor = kFontColour
                self.layerGameFront.addChild(highScoreLabel)
                self.layerGameFront.run(SKAction.playSoundFileNamed("highscore.caf", waitForCompletion: false))
            }
            run(SKAction.sequence([SKAction.wait(forDuration: 0.8), SKAction.run(highScoreBlock)]))
        }
        
        let menuBlock = { () -> Void in
            let gameOverScoreLabel = SKLabelNode(fontNamed: kFont)
            gameOverScoreLabel.name = "toMenuL"
            gameOverScoreLabel.position = CGPoint(x: self.scene!.size.width / 2, y: self.scene!.size.height - kYHighMarginWithAds - kButtonGapMargin / 2)
            gameOverScoreLabel.zPosition = 10
            gameOverScoreLabel.text = "FINAL SCORE:  " + String(self.lastScore!)
            gameOverScoreLabel.fontSize = kFontSize
            gameOverScoreLabel.fontColor = kFontColour
            self.layerGameFront.addChild(gameOverScoreLabel)
            
            let menuButton = SKSpriteNode(imageNamed: "button_green")
            menuButton.name = "toMenuB"
            menuButton.position = CGPoint(x: self.scene!.size.width / 2, y: kYLowMargin)
            self.layerGameFront.addChild(menuButton)
            
            let menuLabel = SKLabelNode(fontNamed: kFont)
            menuLabel.name = "toMenuL"
            menuLabel.position = menuButton.position
            menuLabel.zPosition = menuButton.zPosition + 10
            menuLabel.text = "MENU"
            menuLabel.fontSize = kFontSize
            menuLabel.fontColor = kFontColour
            self.layerGameFront.addChild(menuLabel)
            self.layerGameFront.run(SKAction.playSoundFileNamed("highscore.caf", waitForCompletion: false))
        }
        
        run(SKAction.sequence([SKAction.wait(forDuration: 1.6), SKAction.run(menuBlock)]))
        
    }
    
    fileprivate func createFallingObjects() {
        
        let spawnBlock = { () -> Void in
            let boxWidth = Int(SKSpriteNode(imageNamed: "falling_box").size.width)
            let xMin = 0
            let xMax = Int(self.scene!.size.width) - boxWidth
            var xPos = -1
            let r: Range<Int> = 1..<11
            let randomDraw = Int.random(r)
            if randomDraw < 3 {
                xPos = Int(self.lastPlayerX)
            }
            else {
                let r2: Range<Int> = xMin..<xMax
                xPos = Int.random(r2)
            }
            self.showFallingObjectAtRandomX(CGFloat(xPos))
        }
        let runBlock = SKAction.run(spawnBlock)
        let delay = SKAction.wait(forDuration: spawnRate)
        let sequence = SKAction.sequence([runBlock, delay])
        let repeatSequence = SKAction.repeatForever(sequence)
        layerGameMiddle.run(repeatSequence)
        
    }
    
    fileprivate func moveAndRemoveFallingObjects() {
        
        layerGameMiddle.enumerateChildNodes(withName: "falling") {
            node, stop in
            let a: CGFloat = self.fallingSpeed * CGFloat(self.dt)
            node.position = CGPoint(x: node.position.x, y: node.position.y - a)
            if (node.position.y <= self.kGroundY + groundMarginY) {
                node.removeFromParent()
                self.layerGameMiddle.run(SKAction.playSoundFileNamed("explosion.caf", waitForCompletion: false))
                self.score += 1
                self.updateScore()
                self.animateScoreLabel()
                if self.score % 10 == 0 {
                    self.upDifficulty()
                }
            }
        }
        
    }
    
    fileprivate func movePlayer(_ deltaX: CGFloat) {
        
        layerGameFront.enumerateChildNodes(withName: "player") {
            node, stop in
            let xPos = node.position.x + deltaX
            let xMax = self.size.width - SKSpriteNode(imageNamed: "player").size.width / 2
            if xPos > 0 && xPos < xMax {
                node.position = CGPoint(x: xPos, y: node.position.y)
                self.animatePlayerWithSound()
                self.lastPlayerX = node.position.x
            }
        }
        
    }
    
    fileprivate func upDifficulty() {
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            fallingSpeed += 24.0
            spawnRate -= 0.03
        }
        else {
            fallingSpeed += 12.0
            spawnRate -= 0.03
        }
        
    }
    
    // MARK: Logic
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            let xy = touch.location(in: view!)
            let location = touch.location(in: self)
            let node = atPoint(location)
            let nodeName: String? = node.name
            
            if nodeName == "startB" || nodeName == "startL" {
                layerIntro.removeAllChildren()
                showLayerUIMenu(); showLayerUIBg()
            }
            else if nodeName == "playB" || nodeName == "playL" { // start game
                gameStateOn = true
                showGameScene()
                showPlayer()
                createFallingObjects()
            }
            else if nodeName == "settingsB" || nodeName == "settingsL" { // go to settings
                hideLayerUIMenu()
                showLayerUISettings()
            }
            else if nodeName == "creditsB" || nodeName == "creditsL" { // go to credits
                hideLayerUIMenu()
                showLayerUICredits()
            }
            else if nodeName == "muteB" || nodeName == "muteL" { // mute
                data.setMute(!data.getMute())
                if data.getMute() {
                    music.pause()
                }
                else {
                    music.play()
                }
            }
            else if nodeName == "hintB" || nodeName == "hintL" { // show hint
                let r: Range<Int> = 0..<kHints.count
                randomHintLabel.text = kHints[Int.random(r)]
            }
            else if nodeName == "backB" || nodeName == "backL" { // go to main menu
                hideLayerUISettings()
                hideLayerUICredits()
                showLayerUIMenu()
            }
            else if nodeName == "toMenuB" || nodeName == "toMenuL" { // go to main menu
                clearGameLayers()
                showLayerUIMenu()
                showLayerUIBg()
            }
            else if gameStateOn && xy.x < (view!.bounds.size.width / 2) { // move player left
                movePlayer(-playerStep)
            }
            else if gameStateOn && xy.x >= (view!.bounds.size.width / 2) { // move player right
                movePlayer(playerStep)
            }
            
        }
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        if lastUpdateTime != nil {
            dt = currentTime - lastUpdateTime!
            lastUpdateTime = currentTime
        }
        else {
            lastUpdateTime = currentTime
        }
        
        if gameStateOn {
            moveAndRemoveFallingObjects()
        }
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            gameOver()
        }
        else {
            gameOver()
        }
        
    }
    
    // MARK: Animations
    
    fileprivate func destroyGameProps() {
        
        layerGameMiddle.removeAllActions()
        
        let grow = SKAction.scale(to: 2.0, duration: 0.12)
        let wait = SKAction.wait(forDuration: 0.1)
        
        layerGameMiddle.enumerateChildNodes(withName: "falling") {
            node, stop in
            let pos = node.position
            node.removeFromParent()
            let smoke = SKSpriteNode(imageNamed: "smoke")
            smoke.zPosition = 10
            smoke.position = pos
            self.layerGameFront.addChild(smoke)
            
            let removeBlock = { () -> Void in
                smoke.removeFromParent()
            }
            smoke.run(SKAction.sequence([grow, wait, SKAction.run(removeBlock)]))
        }
        layerGameFront.enumerateChildNodes(withName: "player") {
            node, stop in
            node.removeFromParent()
        }
        
        run(SKAction.playSoundFileNamed("big_bang.caf", waitForCompletion: false))
        
    }
    
    fileprivate func animatePlayerWithSound() {
        
        layerGameFront.run(SKAction.playSoundFileNamed("select.caf", waitForCompletion: false))
        layerGameFront.enumerateChildNodes(withName: "player") {
            node, stop in
            let growRatio: CGFloat = 1.1; let shrinkRatio: CGFloat = 1 / growRatio
            let grow = SKAction.scale(to: growRatio, duration: 0.08); let shrink = SKAction.scale(to: shrinkRatio, duration: 0.0)
            let pulse = SKAction.sequence([grow, shrink])
            node.run(pulse)
        }
        
    }
    
    fileprivate func animateScoreLabel() {
        
        let growRatio: CGFloat = 1.3
        let shrinkRatio: CGFloat = 1 / growRatio
        let grow = SKAction.scale(to: growRatio, duration: 0.05)
        let shrink = SKAction.scale(to: shrinkRatio, duration: 0.05)
        let pulse = SKAction.sequence([grow, shrink])
        scoreLabel.run(pulse)
        
    }
    
}
