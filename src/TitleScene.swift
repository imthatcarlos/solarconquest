//
//  TitleScene.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 3/29/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

class TitleScene : SKScene {
    
    var viewController: UIViewController!
    let IS_IPHONE_5 = UIScreen.mainScreen().bounds.size.height == 568
    let IS_IPHONE_4 = UIScreen.mainScreen().bounds.size.height == 480
    let IS_IPHONE_6 = UIScreen.mainScreen().bounds.size.height == 667
    
    var IS_SUPER_HIGH_RES = false
    let currentModel = UIDevice.currentDevice().model
    var IS_IPAD:Bool = false
    var _scale:CGFloat!
    var textureAtlasToUse: SKTextureAtlas!
    var meteorAtlasToUse: String!
    var menuItemAtlasToUse: String!
    
    var skView: SKView!
    var nextScene: SKScene!
    
    var placementDictionary = [String: CGPoint]()
    var a_parallax: SKSpriteNode!
    var title: SKSpriteNode!
    var startGameLabel: SKSpriteNode!
    var blackCover: SKSpriteNode!
    
    override func didMoveToView(view: SKView) {
        
        self.userInteractionEnabled = false
        
        // Try retrieving the game data, or create a new one
        let filePath = GameData.getFilePath()
        var gameData = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? GameData
        
        if gameData == nil {
            gameData = GameData.sharedInstance
            GameData.sharedInstance.initialize()
        }
        
        if IS_IPHONE_5 || IS_IPHONE_4 {
            _scale = 0.86
            textureAtlasToUse = SKTextureAtlas(named: "atlas_textures@2x")
            meteorAtlasToUse = "atlas_meteors@2x"
            menuItemAtlasToUse = "atlas_menuItems@2x"
        }
        else if (currentModel as NSString).containsString("iPad") {
            _scale = 1.65
            textureAtlasToUse = SKTextureAtlas(named: "atlas_textures@2x")
            meteorAtlasToUse = "atlas_meteors@2x"
            menuItemAtlasToUse = "atlas_menuItems@2x"
            IS_IPAD = true
            
            if UIScreen.mainScreen().scale >= 2.0 {
                IS_SUPER_HIGH_RES = true
            }
        }
        else if IS_IPHONE_6 {
            textureAtlasToUse = SKTextureAtlas(named: "atlas_textures@2x")
            meteorAtlasToUse = "atlas_meteors@2x"
            menuItemAtlasToUse = "atlas_menuItems@2x"
            _scale = 1
        }
        else { //iphone 6+
            _scale = 1.11
            IS_SUPER_HIGH_RES = true
            textureAtlasToUse = SKTextureAtlas(named: "atlas_textures@2x")
            meteorAtlasToUse = "atlas_meteors@2x"
            menuItemAtlasToUse = "atlas_menuItems@2x"
        }
        
        // UI stuff
        showMainScreen()
        beginMusic()
        
        let semaphore = dispatch_semaphore_create(0)
        
        prepareNextScene(semaphore)
        
        // Wait here for notification from next scene
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            let timeout = dispatch_time(DISPATCH_TIME_NOW, Int64(10)) // 10 sec timeout
            dispatch_semaphore_wait(semaphore, timeout)
            
            dispatch_async(dispatch_get_main_queue(), {
                let allowTouches = SKAction.runBlock({ self.userInteractionEnabled = true })
                let blink = SKAction.sequence([SKAction.fadeOutWithDuration(1.0), SKAction.fadeInWithDuration(0.5), SKAction.waitForDuration(0.5)])
                self.startGameLabel.runAction(SKAction.sequence([SKAction.waitForDuration(1.5), allowTouches, SKAction.fadeInWithDuration(0.5), SKAction.repeatActionForever(blink)]))
            })
        })
        
    }
    
    // The image covers up the actual scene getting ready in the background
    func showMainScreen() {
        
        var adj_scale:CGFloat
        
        if IS_IPAD == true {
            adj_scale = _scale + 0.3
        }
        else {
            adj_scale = _scale
        }
        
        readPlacements()
        
        // Pretty fade in
        blackCover = SKSpriteNode(color: UIColor.blackColor(), size: self.size)
        blackCover.zPosition = 50
        blackCover.position = CGPointMake(self.size.width/2, self.size.height/2)
        self.addChild(blackCover)
        blackCover.runAction(SKAction.fadeOutWithDuration(0.5))
        
        // bg
        let bg = SKSpriteNode(imageNamed: "titleScreen-bg")
        bg.anchorPoint = CGPointMake(0, 1)
        bg.position = CGPointMake(0, self.frame.size.height)
        if IS_IPAD == false {
            bg.setScale(_scale)
        }
        bg.zPosition = 10
        
        // planet
        let planet = SKSpriteNode(imageNamed: "titleScreen-planet")
        planet.position = getCorrectPosition(placementDictionary["titleScreen-planet"]!)
        if IS_IPAD == false {
            planet.setScale(_scale)
        }
        
        planet.zPosition = 12
        
        // asteroid front
        let a_front = SKSpriteNode(texture: textureAtlasToUse.textureNamed("asteroidsFront"))
        a_front.position = getCorrectPosition(placementDictionary["asteroidsFront"]!)
        a_front.setScale(adj_scale)
        a_front.zPosition = 20
        
        // asteroid mid
        let a_mid = SKSpriteNode(texture: textureAtlasToUse.textureNamed("asteroidsMid"))
        a_mid.position = getCorrectPosition(placementDictionary["asteroidsMid"]!)
        a_mid.setScale(adj_scale)
        a_mid.zPosition = 15
        
        // asteroid parallax
        a_parallax = SKSpriteNode(texture: textureAtlasToUse.textureNamed("asteroidsParallax"))
        a_parallax.position = getCorrectPosition(placementDictionary["asteroidsParallax"]!)
        a_parallax.setScale(adj_scale)
        a_parallax.zPosition = 10
        
        // title
        title = SKSpriteNode(texture: textureAtlasToUse.textureNamed("titleScreen-title"))
        title.position = getCorrectPosition(placementDictionary["titleScreen-title"]!)
        title.setScale(_scale)
        title.alpha = 0
        title.zPosition = 30
        
        // start game label
        startGameLabel = SKSpriteNode(imageNamed: "titleScreen-startGame")
        startGameLabel.position = CGPointMake(self.size.width/2, self.size.height * 0.65)
        startGameLabel.setScale(_scale)
        startGameLabel.alpha = 0
        startGameLabel.zPosition = 30
        
        if IS_IPHONE_4 == true {
            title.position.y -= 80
            startGameLabel.position.y -= 20
        }
        
        self.addChild(bg)
        self.addChild(planet)
        self.addChild(a_front)
        self.addChild(a_mid)
        self.addChild(title)
        self.addChild(startGameLabel)
        
        // the animations
        
        let moveDown = SKAction.moveToY(a_front.position.y - 10, duration: 5.0)
        let moveBackUp = SKAction.moveToY(a_front.position.y + 10, duration: 5.0)
        a_front.runAction(SKAction.repeatActionForever(SKAction.sequence([moveDown, moveBackUp])))
        
        let moveUp = SKAction.moveToY(a_mid.position.y + 15, duration: 5.0)
        let moveBackDown = SKAction.moveToY(a_mid.position.y - 15, duration: 5.0)
        a_mid.runAction(SKAction.repeatActionForever(SKAction.sequence([moveUp, moveBackDown])))
        
        beginParallax()
        
        title.runAction(SKAction.sequence([SKAction.waitForDuration(1.0), SKAction.fadeInWithDuration(0.5)]))
        
    }
    
    func beginParallax() {
        let moveAcrossScreen = SKAction.moveToX(-a_parallax.size.width/2, duration: 30.0)
        let makeCopy = SKAction.runBlock({  let copy = self.a_parallax.copy() as! SKSpriteNode;
                                            copy.position.x += copy.size.width;
                                            self.addChild(copy)
                                            copy.runAction(moveAcrossScreen, completion: { copy.removeFromParent() })})
        
        let firstCopy = a_parallax.copy() as! SKSpriteNode
        let firstMoveAcross = SKAction.moveToX(-a_parallax.size.width/2, duration: 15.0)
        self.addChild(firstCopy)
        
        firstCopy.runAction(SKAction.sequence([firstMoveAcross, SKAction.removeFromParent()]))
        self.runAction(SKAction.repeatActionForever(SKAction.sequence([ makeCopy, SKAction.waitForDuration(15.0) ])))
    }
    
    // Loads the song for the intro
    func beginMusic() {
        AudioManager.sharedInstance.setMusic("intro")
        AudioManager.sharedInstance.beginMusic()
    }
    
    func readPlacements() {
        var fileName:String
        
        if IS_IPAD == true {
            fileName = "titleScreenPlacements_ipad"
        }
        else {
            fileName = "titleScreenPlacements"
        }
        
        if let fileReader = FileReader(path: NSBundle.mainBundle().pathForResource(fileName, ofType: ".txt")!) {
            
            while let line = fileReader.nextLine() {
                if line == "\n" {
                    break
                }
                
                var data = line.componentsSeparatedByString(",")
                let point = CGPointMake(CGFloat(NSNumberFormatter().numberFromString(data[1])!), CGFloat(NSNumberFormatter().numberFromString(data[2])!))
                placementDictionary[data[0]] = point;
            }
            
            fileReader.close()
        }
    }
    
    // Once the game is ready (everything loaded) the user can tap anywhere to begin playing
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        presentNextScene()
        self.userInteractionEnabled = false
    }
    
    func prepareNextScene(sem: dispatch_semaphore_t) {
        
        // If the player quit the game during the map menu, present the map menu
        if GameData.sharedInstance.currentPlanet!.hasPrefix("hasYetToChooseNew_") {
            prepareMapScene("didNotChoose", semaphore: sem)
            return
        }
        else {
            self.prepareGameScene(sem)
        }
    }
    
    func prepareGameScene(semaphore: dispatch_semaphore_t) {
        nextScene = GameScene.sharedInstance
        
        // Configure the view.
        skView = self.viewController.view as! SKView
        skView.showsFPS = false
        //skView.frameInterval = 2    // lowers the fps to 30
        skView.showsNodeCount = false
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = false
        
        /* Set the scale mode to scale to fit the window */
        nextScene.scaleMode = .AspectFill
        nextScene.size = skView.bounds.size
        (nextScene as! GameScene)._scale = self._scale!
        (nextScene as! GameScene).atlas = textureAtlasToUse
        (nextScene as! GameScene).meteorAtlasToUse = meteorAtlasToUse
        (nextScene as! GameScene).menuItemAtlasToUse = menuItemAtlasToUse
        (nextScene as! GameScene).IS_IPAD = IS_IPAD
        (nextScene as! GameScene).IS_SUPER_HIGH_RES = IS_SUPER_HIGH_RES
        (nextScene as! GameScene).viewController = viewController
        (nextScene as! GameScene).skView = skView
        
        // now that scene should initialize all of its stuff
        (nextScene as! GameScene).earlyInitialize(semaphore)
    }
    
    func prepareMapScene(planetJustCompleted: String, semaphore: dispatch_semaphore_t) {
        
        // Preload all textures for it
        let atlas = SKTextureAtlas(named: menuItemAtlasToUse)
        var textures = [String: SKTexture]()
        
        for textureName in atlas.textureNames {
            var name = textureName 
            name = substring(name, delim: "@")
            textures[name] = atlas.textureNamed(name)
        }
        
        nextScene = MapScene()
        
        // Configure the view.
        skView = self.viewController.view as! SKView
        
        skView.showsFPS = false
        //skView.frameInterval = 2    // lowers the fps to 30
        skView.showsNodeCount = false
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = false
        
        /* Set the scale mode to scale to fit the window */
        nextScene.scaleMode = .AspectFill
        nextScene.size = skView.bounds.size
        nextScene.anchorPoint = CGPointMake(0, 0)
        (nextScene as! MapScene).previousScene = nil
        (nextScene as! MapScene).skView = skView
        (nextScene as! MapScene).viewController = viewController
        (nextScene as! MapScene).meteorAtlasToUse = meteorAtlasToUse
        (nextScene as! MapScene).textureAtlasToUse = textureAtlasToUse
        (nextScene as! MapScene).menuItemAtlasToUse = menuItemAtlasToUse
        
        // now that scene should initialize all of its stuff
        (nextScene as! MapScene).earlyInitialize(IS_IPAD, scale: _scale, planetCompleted: planetJustCompleted, menuTextures: textures, sem: semaphore)
    }
    
    func presentNextScene() {
        let transition = SKTransition.fadeWithDuration(0.5)
        let presentScene = SKAction.runBlock({ self.skView.presentScene(self.nextScene, transition: transition) })
        let removeStuff = SKAction.runBlock({ self.removeAllChildren(); self.view!.removeFromSuperview() })
        
        self.runAction(SKAction.sequence([presentScene, removeStuff]))
    }
    
    private func positionScale(position: CGPoint, scale: CGFloat) -> CGPoint {
        return CGPointMake(position.x * scale, position.y * scale)
    }
    
    func getCorrectPosition(position: CGPoint) -> CGPoint {
        var adj_scale: CGFloat
        var pointConversion: CGFloat
        
        // for the ipad
        if IS_IPAD == true {
            pointConversion = 1.0
            adj_scale = 1.0
        }
        else {
            pointConversion = 2.0
            adj_scale = _scale
        }
        
        let adjustedPosition = positionScale(position, scale: adj_scale)
        return CGPointMake(adjustedPosition.x / pointConversion, adjustedPosition.y / pointConversion)
    }
    
    deinit {
        print("De-init!")
    }
    
}