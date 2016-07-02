//
//  GameScene.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 3/27/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit
import GameKit

extension SKAction {
    class func shake(initialPosition:CGPoint, duration:Float, amplitudeX:Int = 0, amplitudeY:Int = 3) -> SKAction {
        let startingX = initialPosition.x
        let startingY = initialPosition.y
        let numberOfShakes = duration / 0.015
        var actionsArray:[SKAction] = []
        for _ in 1...Int(numberOfShakes) {
            let newXPos = startingX + CGFloat(arc4random_uniform(UInt32(amplitudeX))) - CGFloat(amplitudeX / 2)
            let newYPos = startingY + CGFloat(arc4random_uniform(UInt32(amplitudeY))) - CGFloat(amplitudeY / 2)
            actionsArray.append(SKAction.moveTo(CGPointMake(newXPos, newYPos), duration: 0.015))
        }
        actionsArray.append(SKAction.moveTo(initialPosition, duration: 0.015))
        return SKAction.sequence(actionsArray)
    }
}

enum GameState:UInt32 {
    case PlayerShooting = 0x01
    case PlayerCollecting = 0x02
    case GameIdle = 0x04
    case Menu = 0x08
    case ShootingOffBounds = 0x16
    case PullingMenu = 0x32
    case PullingBoostMenu = 0x64
}

enum ColliderType:UInt32 {
    case Meteor = 0xf0
    case Projectile = 0xf
    case Bit = 0xf00
    case FallingBit = 0xf000
    case Object = 0xf0000
    case Weapon = 0xf00000
    case DontTouchMe = 0xf000000
    case Explosion = 0xf0000000
}

@objc
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    class var sharedInstance: GameScene {
        struct Singleton {
            static let instance = GameScene()
        }
        
        return Singleton.instance
    }

    var viewController:UIViewController!
    var nativeXController:NativeXController!
    var nextScene: MapScene!
    var skView: SKView!
    var fromMenu = false
    var fade: SKSpriteNode!
    
    let IS_IPHONE_4 = UIScreen.mainScreen().bounds.size.height == 480
    var IS_IPAD: Bool!
    var IS_SUPER_HIGH_RES: Bool = false
    var _scale:CGFloat!
    var atlas: SKTextureAtlas!
    var meteorAtlasToUse: String!
    var menuItemAtlasToUse: String!
    
    var shakeLayer: SKNode!
    var meteorShowerController: MeteorShower!
    var parallaxManager: ParallaxManager!
    var gameMenu:GameMenu!
    var boostMenu:BoostMenu!
    var forceField:SKSpriteNode!
    var menuButton: SKSpriteNode!
    var boostMenuButton:SKSpriteNode!
    var currencyNode: SKSpriteNode!
    var equippedWeapon:Weapon!
    var platform:SKSpriteNode!
    var planetBase:PlanetBase!
    var currencyManager: CurrencyManager!
    var beginningLocation: CGPoint!
    var gestureRecognizer: UIPanGestureRecognizer!
    var currentContacts: [SKPhysicsContact] = []
    var state = GameState.GameIdle.rawValue
    var minShootY: CGFloat!
    var multiplier: BitMapFontLabel!
    var multiplierTracker = 0
    var effectDelayTracker:CGFloat = 0
    
    var gameHasStarted = false
    var onMapScene = false
    var nativeX_disabled = false
    
    var tutorialHand: SKSpriteNode?
    
    func earlyInitialize(semaphore: dispatch_semaphore_t) {
        initGame()
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVectorMake(0.0, -2.5)
        
        if onMapScene == false {
            AudioManager.sharedInstance.initialize()
            AudioManager.sharedInstance.preLoad()
        }
        
        
        dispatch_semaphore_signal(semaphore)
    }
    
    func reset(semaphore: dispatch_semaphore_t) {
        self.removeAllChildren()
        self.removeAllActions()
        
        shakeLayer = SKNode()
        shakeLayer.position = self.position
        self.addChild(shakeLayer)
        
        initBase()
        initBackground()
        initWeapon()
        initMenus()
        initWaveController()
        
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVectorMake(0.0, -2.5)
        
        dispatch_semaphore_signal(semaphore)
    }
    
    override func didMoveToView(view: SKView) {
        self.view!.userInteractionEnabled = true
        self.userInteractionEnabled = true
        
        gestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanFrom:")
        gestureRecognizer.enabled = true
        self.view!.addGestureRecognizer(gestureRecognizer)
        
        if nativeXController == nil {
            let tempController: NativeXController = NativeXController()
            nativeXController = tempController
            nativeXController.createSessionWithAppID("30541")
        }
        
        beginGame()
    }
    
    func displayBoostMenu() {
        state = GameState.Menu.rawValue
        boostMenu.displayMenu()
        boostMenuButton.hidden = true
        menuButton.hidden = true
        
        let slide = SKAction.moveToX(-40, duration: 0.1)
        let slideBack = SKAction.moveToX(0, duration: 0.08)
        boostMenu.runAction(SKAction.sequence([slide, slideBack]), completion: { self.boostMenu.addBgNode() })
        
        AudioManager.sharedInstance.playSound("display_menu")
        
        boostMenu.userInteractionEnabled = true
        self.userInteractionEnabled = false
        self.gestureRecognizer.enabled = false
    }
    
    func displayMenu() {
        state = GameState.Menu.rawValue
        gameMenu.displayMenu()
        menuButton.hidden = true
        boostMenuButton.hidden = true
        
        let slide = SKAction.moveToX(-40, duration: 0.1)
        let slideBack = SKAction.moveToX(0, duration: 0.08)
        gameMenu.runAction(SKAction.sequence([slide, slideBack]), completion: { self.gameMenu.addBgNode() })
        
        AudioManager.sharedInstance.playSound("display_menu")
        
        gameMenu.userInteractionEnabled = true
        self.userInteractionEnabled = false
        self.gestureRecognizer.enabled = false
    }
    
    // Whenever the player touches the screen, the weapon should shoot
    // shoot() behavior changes based on the currentWeapon
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        let touch = touches.first
        let touchLocation = touch!.locationInNode(self)
        
        if self.nodeAtPoint(touchLocation) == menuButton {
            state = GameState.PullingMenu.rawValue
            return
        }
        
        if self.nodeAtPoint(touchLocation) == boostMenuButton {
            state = GameState.PullingBoostMenu.rawValue
            return
        }
        
        if self.nodeAtPoint(touchLocation).name == "silver" || self.nodeAtPoint(touchLocation).name == "gold"
                                                             || self.nodeAtPoint(touchLocation).name == "lilac" {
            state = GameState.PlayerCollecting.rawValue
            return
        }
        
        if touchLocation.y > minShootY {
            beginningLocation = CGPointMake(equippedWeapon.position.x, equippedWeapon.position.y)
            let targetVector = vectorSubtract(touchLocation, right: beginningLocation)
            
            state = GameState.PlayerShooting.rawValue
            equippedWeapon.shoot(touchLocation, vector: targetVector)
        }
        else {
            state = GameState.PlayerCollecting.rawValue
            
            let possibleNodes = self.nodesAtPoint(touchLocation)
            
            for node in possibleNodes {
                var possibleNode = node as? Bit
                
                if possibleNode?.name == nil { continue }
                
                if possibleNode?.name! == "gold" || possibleNode?.name! == "silver" || possibleNode?.name! == "lilac" || possibleNode?.name! == "plain" {
                    meteorShowerController.moveToCorrespondingCurrency(&possibleNode!)
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        if state == GameState.PlayerShooting.rawValue {
            state = GameState.GameIdle.rawValue
            equippedWeapon.stopShooting()
        }
        else if state == GameState.PullingMenu.rawValue {
            state = GameState.GameIdle.rawValue
        }
        else if state == GameState.PlayerCollecting.rawValue {
            state = GameState.GameIdle.rawValue
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        switch contactMask {
        case ColliderType.Projectile.rawValue | ColliderType.Meteor.rawValue:
            
            var projectile:Projectile?
            var meteor:Meteor?
        
            if contact.bodyA.categoryBitMask == ColliderType.Projectile.rawValue {
                projectile = contact.bodyA.node as? Projectile
                meteor = contact.bodyB.node as? Meteor
            }
            else {
                projectile = contact.bodyB.node as? Projectile
                meteor = contact.bodyA.node as? Meteor
            }
            
            if meteor == nil || projectile == nil{
                return
            }
            
            if meteor!.isDestroyed {
                return
            }
            
            let contactPoint = self.convertPoint(contact.contactPoint, toNode: meteor!)
            
            meteor?.takeDamage(projectile!.damage, contactPos: contactPoint, projectile: projectile!.type)
            
            if projectile!.type == Projectile.ProjectileType.Elec.rawValue {
                (equippedWeapon as! RailGun).canShoot = true
            }
            
            if projectile!.type != Projectile.ProjectileType.Beam.rawValue {
                projectile!.removeFromParent()
            }
            else {
                // To remove all the burning effects once the beam disappears
                currentContacts.append(contact)
            }
        case ColliderType.Explosion.rawValue | ColliderType.Meteor.rawValue:
            
            var meteor:Meteor?
            
            if contact.bodyB.categoryBitMask == ColliderType.Explosion.rawValue {
                meteor = contact.bodyA.node as? Meteor
            }
            else {
                meteor = contact.bodyB.node as? Meteor
            }
            
            if meteor == nil {
                return
            }
            
            if meteor!.alreadyTookMissileDamage == true {
                return
            }
            
            let contactPoint = self.convertPoint(contact.contactPoint, toNode: meteor!)
            meteor?.takeDamage(equippedWeapon.getDamage()/2, contactPos: contactPoint, projectile: Projectile.ProjectileType.Explosion.rawValue)
        
        default:
            break
        }
    }
    
    func didEndContact(contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        switch contactMask {
            case ColliderType.Projectile.rawValue | ColliderType.Meteor.rawValue:
                var projectile:Projectile?
                var meteor:Meteor?
                
                if contact.bodyA.categoryBitMask == ColliderType.Projectile.rawValue {
                    projectile = contact.bodyA.node as? Projectile
                    meteor = contact.bodyB.node as? Meteor
                }
                else {
                    projectile = contact.bodyB.node as? Projectile
                    meteor = contact.bodyA.node as? Meteor
                }
                
                if meteor?.isDestroyed == true {
                    return
                }
            
                if projectile?.type == Projectile.ProjectileType.Beam.rawValue {
                    meteor?.removeBurn()
                    meteor?.removeActionForKey("takingDamage")
                }
            
            default:
                break
            }
    }
    
    func shake() {
        shakeLayer.runAction(SKAction.shake(self.position, duration: Float(0.3)))
    }
    
    func meteorWasDestroyed() {
        multiplierTracker += 1
        setMultiplierLabel()
    }
    
    func setMultiplierLabel() {
        self.removeActionForKey("multiplier")
        
        var tierWait: NSTimeInterval!
        
        // Change the timer for the streak
        if multiplierTracker < 3 {
            tierWait = 4.0
        }
        else if multiplierTracker < 5 {
            tierWait = 3.0
        }
        else {
            tierWait = 2.0
        }
        
        let timer = SKAction.waitForDuration(tierWait)
        let reset = SKAction.runBlock({ self.multiplierTracker = 0 })
        let scaleDown = SKAction.scaleTo(0.1, duration: 0.1)
        let scaleDownAndHide = SKAction.runBlock({ self.multiplier.runAction(SKAction.sequence([ scaleDown, SKAction.hide() ]) ) })
        
        if self.multiplierTracker == 2 {
            let reveal = SKAction.unhide()
            let scaleUp = SKAction.scaleTo(_scale + 0.2, duration: 0.2)
            let reduce = SKAction.scaleTo(_scale, duration: 0.1)
            multiplier.set_Text("x\(multiplierTracker)")
            multiplier.runAction(SKAction.sequence( [reveal, scaleUp, reduce]))
            AudioManager.sharedInstance.playSound("streak_1")
        }
        else if self.multiplierTracker > 2 {
            if multiplierTracker == 3 {
                AudioManager.sharedInstance.playSound("streak_1")
            }
            else {
                AudioManager.sharedInstance.playSound("streak_1")
            }
            
            multiplier.set_Text("x\(multiplierTracker)")
        }
        
        self.runAction(SKAction.sequence([timer, scaleDownAndHide, reset]), withKey: "multiplier")
    }
    
    // MARK: init functions
    
    // Try to retrieve saved game data and call appropriate functions to set up the scene.
    func initGame() {
        
        shakeLayer = SKNode()
        shakeLayer.position = self.position
        self.addChild(shakeLayer)
        
        initBase()
        initBackground()
        initWeapon()
        initMenus()
        initWaveController()
        
        if GameData.sharedInstance.tutorialCompleted! == false {
            tutorialHand = SKSpriteNode(texture: atlas.textureNamed("cursor"))
            tutorialHand?.setScale(_scale)
            tutorialHand?.position = self.position
            tutorialHand?.alpha = 0
            tutorialHand?.zPosition = 60
            self.addChild(tutorialHand!)
        }
    }
    
    func beginGame() {
        AudioManager.sharedInstance.stopMusic()
        AudioManager.sharedInstance.setMusic("\(GameData.sharedInstance.currentPlanet!)_music")
        AudioManager.sharedInstance.beginMusic()
        
        gameHasStarted = true
        
        if GameData.sharedInstance.tutorialCompleted == false {
            beginTutorial()
            return
        }
        
        self.runAction(SKAction.waitForDuration(10.0), completion: {self.meteorShowerController.beginWave()})
    }
    
    // A meteor will spawn, and the cursor shows how to shoot
    // Bits fall to the ground, and the cursor shows how to collect
    // Finally, the cursor shows how to open the menu
    // Then, the game begins
    func beginTutorial() {
        
        // TODO: Make the hand simulate following the meteor after it repositions
        let moveCursor = SKAction.sequence([ SKAction.fadeInWithDuration(0.3), SKAction.moveToX(self.frame.maxX * 0.3, duration: 4.0), SKAction.fadeOutWithDuration(0.3)])
        
        self.runAction(SKAction.waitForDuration(2.5), completion: { self.meteorShowerController.spawnMeteor(15, yPosition: 2, currency: "lilac") })
        
        tutorialHand!.position = CGPointMake(self.frame.maxX * 0.8, self.frame.maxY * 0.65)
        tutorialHand!.runAction(SKAction.sequence([SKAction.waitForDuration(4.5), moveCursor]))
        
        self.runAction(SKAction.waitForDuration(7.5), completion: { self.meteorShowerController.spawnMeteor(10, yPosition: 2, currency: "lilac") })
        
        // Showing how to collect
        let cursorPath2 = UIBezierPath()
        cursorPath2.moveToPoint(CGPointMake(self.frame.midX, self.frame.maxY * 0.2))
        cursorPath2.addArcWithCenter(CGPointMake(self.frame.midX, self.frame.maxY * 0.2), radius: self.frame.maxX * 0.25, startAngle: 0, endAngle: CGFloat(2 * M_PI), clockwise: true)
        cursorPath2.closePath()
        
        let moveCursor2 = SKAction.sequence([ SKAction.runBlock({ self.tutorialHand!.position = CGPointMake(self.frame.midX, self.frame.maxY * 0.2) }), SKAction.fadeInWithDuration(0.2), SKAction.followPath(cursorPath2.CGPath, asOffset: false, orientToPath: false, speed: 320.0), SKAction.fadeOutWithDuration(0.2)])
        
        tutorialHand!.runAction(SKAction.sequence([SKAction.waitForDuration(15.0), moveCursor2]))
        
        let moveCursor3 = SKAction.sequence([ SKAction.fadeInWithDuration(0.2), SKAction.moveToX(self.menuButton.position.x - 75, duration: 0.5), SKAction.fadeOutWithDuration(0.2)])
        tutorialHand!.runAction(SKAction.sequence([SKAction.waitForDuration(24.0), SKAction.repeatAction(SKAction.sequence([ SKAction.runBlock({ self.tutorialHand?.position = CGPointMake(menuButton.position.x + 20, menuButton.position.y - 40)}), moveCursor3]), count: 2)]))
        
        self.runAction(SKAction.waitForDuration(28.0), completion: { self.meteorShowerController.beginWave(); self.tutorialHand!.removeFromParent() })
        
        GameData.sharedInstance.tutorialCompleted = true
        
        GameData.save()
    }
    
    func initMenus() {
        
        // Game Menu
        gameMenu = GameMenu(_scale: _scale, size: self.size, parentScene: self, atlasToUse: menuItemAtlasToUse)
        gameMenu.position = CGPointMake(self.size.width * 0.8, 0)
        gameMenu.zPosition = 45
        gameMenu.anchorPoint = CGPointMake(0, 0)
        gameMenu.hidden = true
        gameMenu.userInteractionEnabled = false
        self.addChild(gameMenu)
        
        gameMenu.displayCurrencyNode()
        
        menuButton = gameMenu.menuButton
        menuButton.zPosition = 50
        self.addChild(menuButton)
        
        // Boost Menu
        boostMenu = BoostMenu(parentScene: self, scale: _scale, size: self.size)
        boostMenu.position = CGPointMake(self.size.width, 0)
        boostMenu.zPosition = 45
        boostMenu.hidden = true
        boostMenu.userInteractionEnabled = false
        self.addChild(boostMenu)
        
        boostMenuButton = boostMenu.sprites["boostMenuButton"]!
        boostMenuButton.hidden = false
        boostMenuButton.zPosition = 50
        self.addChild(boostMenuButton)
        
        // multiplier
        multiplier = BitMapFontLabel(text: "", fontName: "multiplier_", usingAtlas: "atlas_fonts.atlas")
        multiplier.setScale(0.1)
        multiplier.zPosition = 44
        multiplier.anchorPoint = CGPointMake(0, 1)
        multiplier.position = CGPointMake(self.size.width/12, self.frame.height * 0.55)
        multiplier.hidden = true
        self.addChild(multiplier)
    }
    
    // Sets up the appropriate background image according the player's current planet
    func initBackground() {
        let textureString = GameData.sharedInstance.currentPlanet! + "_background"
        let texture = SKTexture(imageNamed: textureString)
        let background = SKSpriteNode(texture: texture, size: texture.size())
        background.name = "background"
        background.userInteractionEnabled = false
        background.position = CGPointMake(self.frame.midX, self.frame.midY)
        background.zPosition = -10
        
        let g_string = GameData.sharedInstance.currentPlanet! + "_ground"
        let g_texture = SKTexture(imageNamed: g_string)
        let ground = SKSpriteNode(texture: g_texture, size: g_texture.size())
        ground.name = "ground"
        ground.userInteractionEnabled = false
        ground.anchorPoint = CGPointMake(0.5, 0)
        ground.position = CGPointMake(self.frame.midX, self.frame.minY)
        ground.zPosition = -2
        
        forceField = SKSpriteNode(imageNamed: "planet_forceField")
        if IS_IPAD == false {
            forceField.setScale(_scale)
        }
        forceField.anchorPoint = CGPointMake(0.5, 0)
        forceField.position = CGPointMake(self.size.width/2, 0)
        forceField.alpha = 0
        forceField.zPosition = 35
        forceField.runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.fadeInWithDuration(1.5), SKAction.fadeOutWithDuration(1.5), SKAction.waitForDuration(60.0)])))
        shakeLayer.addChild(forceField)
        
        // the ipad uses different ground textures.
        if IS_IPAD != true {
            ground.setScale(_scale)
            background.setScale(_scale)
        }
        
        self.shakeLayer.addChild(ground)
        self.addChild(background)
        
        parallaxManager = ParallaxManager(currentPlanet: GameData.sharedInstance.currentPlanet!, parent: self)
        parallaxManager.beginParallaxEffect()
    }
    
    func swapWeapon(name: String) {
        GameData.sharedInstance.equippedWeaponName = name
        
        let newWeapon = loadWeapon(name)
        equippedWeapon.removeFromParent()
        equippedWeapon = newWeapon
        
        equippedWeapon.anchorPoint = CGPointMake(0.5, 0.03)
        equippedWeapon.position = platform.position
        equippedWeapon.zPosition = 26
        equippedWeapon.setScale(_scale)
        equippedWeapon.scale = _scale
        shakeLayer.addChild(equippedWeapon)
        
        swapPlatform(name)
    }
    
    func swapPlatform(weaponName: String) {
        let level = GameData.sharedInstance.weaponInventory![weaponName]!.level
        let string = "platform-\(level)"
        platform.removeFromParent()
        platform = SKSpriteNode(texture: atlas.textureNamed(string))
        platform.anchorPoint = CGPointMake(0.5, 0.73)
        platform.position = planetBase.getCorrectPosition()
        platform.setScale(_scale)
        platform.zPosition = -1
        shakeLayer.addChild(platform)
    }
    
    func loadWeapon(name: String) -> Weapon {
        let data = GameData.sharedInstance.weaponInventory![name]
        let string = "\(name)-\(data!.level!)"
        let texture = atlas.textureNamed(string)
        
        var weapon: Weapon
        
        if name.hasPrefix("machine_gun") {
            weapon = MachineGun(texture: texture, color: UIColor.clearColor(), size: texture.size(), name: data!.name!, level: data!.level!, sublevel: data!.sublevel!, parentScene: self)
        }
        else if name.hasPrefix("missile_launcher"){
            weapon = Missile(texture: texture, color: UIColor.clearColor(), size: texture.size(), name: data!.name!, level: data!.level!, sublevel: data!.sublevel!, parentScene: self)
        }
        else if name.hasPrefix("laser") {
            weapon = Laser(texture: texture, color: UIColor.clearColor(), size: texture.size(), name: data!.name!, level: data!.level!, sublevel: data!.sublevel!, parentScene: self)
        }
        else {
            weapon = RailGun(texture: texture, color: UIColor.clearColor(), size: texture.size(), name: data!.name!, level: data!.level!, sublevel: data!.sublevel!, parentScene: self)
        }
        
        return weapon
    }
    
    // Sets up the appropriate weapon based on the player's equipped weapon
    // Also sets up the weapon platform
    func initWeapon() {
        let equippedName = GameData.sharedInstance.equippedWeaponName!
        
        equippedWeapon = loadWeapon(equippedName)
        
        // Platform for weapon
        let platformString = "platform-\(equippedWeapon.level!)"
        platform = SKSpriteNode(texture: atlas.textureNamed(platformString))
        platform.name = "platform"
        platform.anchorPoint = CGPointMake(0.5, 0.73)
        platform.position = planetBase.getCorrectPosition()
        platform.setScale(_scale)
        platform.zPosition = 1
        
        shakeLayer.addChild(platform)
        
        equippedWeapon.anchorPoint = CGPointMake(0.5, 0.03)
        equippedWeapon.name = "weapon"
        equippedWeapon.position = platform.position
        equippedWeapon.zPosition = 26
        equippedWeapon.setScale(_scale)
        equippedWeapon.scale = _scale
        shakeLayer.addChild(equippedWeapon)
        
        minShootY = equippedWeapon.position.y + (equippedWeapon.size.height * 1.75)
        
    }
    
    // Sets up the object in charge of the wave of meteors
    func initWaveController() {
        meteorShowerController = MeteorShower(parentScene: self, scale: _scale, is_i4: IS_IPHONE_4, meteorAtlasToUse: meteorAtlasToUse)
    }
    
    // Sets up the buildings for the base, as well as the spacemen positions
    func initBase() {
        planetBase = PlanetBase(base_states: GameData.sharedInstance.baseStates!, scene: self, scale: _scale)
        planetBase.initBase()
        planetBase.initSpacemen()
    }
    
    func prepareForNextScene() {
        
        // Update the planet stat
        let currentPlanet = GameData.sharedInstance.currentPlanet!
        var currentStat = GameData.sharedInstance.planetStats![currentPlanet]!
        GameData.sharedInstance.planetStats!.updateValue(++currentStat, forKey: currentPlanet)
        
        AudioManager.sharedInstance.stopMusic()
        
        fade.runAction(SKAction.fadeInWithDuration(2.0))
        
        let semaphore = dispatch_semaphore_create(0)
        
        // Preparing the map scene asynchronously, and waiting for the signal that it's ready
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.prepareMapScene(semaphore)
            
            // Wait here for notification from MapScene
            let timeout = dispatch_time(DISPATCH_TIME_NOW, Int64(10)) // 10 sec timeout
            dispatch_semaphore_wait(semaphore, timeout)
            
            dispatch_async(dispatch_get_main_queue(), {
                self.showNextScene()
            })
        })
    }
    
    // A short cutscene to show that we are done with this planet
    func showEndGame() {
        
        gameMenu.dismissMenu()
        self.userInteractionEnabled = false
        self.view?.userInteractionEnabled = false
        self.view?.removeGestureRecognizer(gestureRecognizer)
        
        // a short fade
        fade = SKSpriteNode(color: UIColor.blackColor(), size: self.size)
        fade.position = CGPointMake(self.size.width/2, self.size.height/2)
        fade.zPosition = 120
        fade.alpha = 0
        self.addChild(fade)
        fade.runAction(SKAction.sequence([SKAction.fadeInWithDuration(0.5), SKAction.fadeOutWithDuration(0.5)]))
        
        meteorShowerController.controller.removeAllActions()
        meteorShowerController.controller.removeAllChildren()
        
        // forcefield fades
        self.forceField.removeFromParent()
        let forceFieldEnd = SKSpriteNode(imageNamed: "endGame_forceField")
        if IS_IPAD == false {
            forceFieldEnd.setScale(_scale)
        }
        forceFieldEnd.anchorPoint = CGPointMake(0.5, 0)
        forceFieldEnd.position = CGPointMake(self.size.width/2, 0)
        forceFieldEnd.alpha = 0
        forceFieldEnd.zPosition = 35
        
        // all spacemen are running the wave animation
        planetBase.spacemenController.makeAllWave()
        
        // Change hangar texture to one without the spaceship
        planetBase.hangar.texture = atlas.textureNamed("hangar-NoSpaceship")
        
        let spaceship = SKSpriteNode(texture: atlas.textureNamed("spaceship"))
        spaceship.setScale(_scale)
        spaceship.zPosition = 10
        spaceship.position = CGPointMake(planetBase.hangar.frame.maxX, planetBase.hangar.position.y + 40)
        spaceship.alpha = 0
        spaceship.zPosition = 35
        
        self.addChild(spaceship)
        spaceship.runAction(SKAction.sequence([SKAction.waitForDuration(0.5), SKAction.fadeInWithDuration(0), SKAction.moveToY(self.frame.maxY + 50, duration: 5.0)]))
        
        // Forcefield fades in and out a bit
        forceFieldEnd.alpha = 0
        self.addChild(forceFieldEnd)
        forceFieldEnd.runAction(SKAction.sequence([SKAction.waitForDuration(3.0), SKAction.fadeInWithDuration(1.5), SKAction.repeatActionForever(SKAction.sequence([SKAction.fadeAlphaTo(0.7, duration: 0.5), SKAction.fadeAlphaTo(1.0, duration: 0.5)]))]))
        
        // prepare the next scene in 10 seconds
        self.runAction(SKAction.waitForDuration(10.0), completion: { self.prepareForNextScene() })
    }
    
    func showNextScene() {
        let transition = SKTransition.fadeWithDuration(0.5)
        let presentScene = SKAction.runBlock({ self.skView.presentScene(self.nextScene, transition: transition) })
        let removeStuff = SKAction.runBlock({ self.removeAllChildren() })
        
        self.runAction(SKAction.sequence([presentScene, removeStuff]))
    }
    
    func prepareMapScene(sem: dispatch_semaphore_t) {
        
        nextScene = MapScene()
        
        /* Set the scale mode to scale to fit the window */
        nextScene.scaleMode = .AspectFill
        nextScene.size = skView.bounds.size
        nextScene.anchorPoint = CGPointMake(0, 0)
        nextScene.previousScene = self
        nextScene.skView = skView
        nextScene.viewController = self.viewController
        
        // now that scene should initialize all of its stuff
        nextScene.earlyInitialize(IS_IPAD, scale: _scale, planetCompleted: GameData.sharedInstance.currentPlanet!, menuTextures: gameMenu.textures, sem: sem)
    }
    
    // MARK: Helper functions
    
    // For some reason, even when disabled, this handler is still called :/
    func handlePanFrom(sender: UIGestureRecognizer) {
        
        if state == GameState.Menu.rawValue || state == GameState.GameIdle.rawValue {
            return
        }
        
        if sender.state == UIGestureRecognizerState.Began {
            
            if sender.numberOfTouches() == 0 {
                return
            }
            
            if state == GameState.PlayerShooting.rawValue {
                let updatedShootingInfo: (touchLocation: CGPoint, vector: CGPoint) = updateShootingInformation(sender)
                
                // If the pan is too sudden, touches began does not get called, and the weapon never shoots. This is the quick and dirty fix >:)
                if equippedWeapon.weaponName! == "laser"  && updatedShootingInfo.touchLocation.y > minShootY {
                    if (equippedWeapon as! Laser).currentBeam == nil {
                        state = GameState.PlayerShooting.rawValue
                        equippedWeapon.shoot(updatedShootingInfo.touchLocation, vector: updatedShootingInfo.vector)
                    }
                }
            }
        }
        else if sender.state == UIGestureRecognizerState.Changed {
            if sender.numberOfTouches() == 0 {
                return
            }
            
            if state == GameState.PlayerShooting.rawValue || state == GameState.ShootingOffBounds.rawValue {
                let updatedShootingInfo: (touchLocation: CGPoint, vector: CGPoint) = updateShootingInformation(sender)
                
                // If they go past the bounds, the weapon will stop shooting
                if updatedShootingInfo.touchLocation.y < minShootY {
                    
                    state = GameState.ShootingOffBounds.rawValue
                    
                    if equippedWeapon.weaponName == "rail_gun" {
                        (equippedWeapon as! RailGun).releaseProjectile()
                    }
                    else {
                        equippedWeapon.removeActionForKey("shooting")
                    }
                    
                    return
                }
                else if state == GameState.ShootingOffBounds.rawValue {
                    state = GameState.PlayerShooting.rawValue
                    self.equippedWeapon.shoot(updatedShootingInfo.touchLocation, vector: updatedShootingInfo.vector)
                }
                
                equippedWeapon.rotateToFaceTouch(equippedWeapon.currentVector)
                
            }
            else if state == GameState.PullingMenu.rawValue {
                let tempLocation = sender.locationOfTouch(0, inView: sender.view)
                let touchLocation = CGPointMake(tempLocation.x, self.frame.maxY - tempLocation.y)
                if touchLocation.x < self.size.width * 0.85 {
                    displayMenu()
                }
            }
            else if state == GameState.PullingBoostMenu.rawValue {
                let tempLocation = sender.locationOfTouch(0, inView: sender.view)
                let touchLocation = CGPointMake(tempLocation.x, self.frame.maxY - tempLocation.y)
                if touchLocation.x < self.size.width * 0.85 {
                    displayBoostMenu()
                }
            }
            else if state == GameState.PlayerCollecting.rawValue {
                let tempLocation = sender.locationOfTouch(0, inView: sender.view)
                let touchLocation = CGPointMake(tempLocation.x, self.frame.maxY - tempLocation.y)
                
                let possibleNodes = self.nodesAtPoint(touchLocation)
                
                for node in possibleNodes {
                    var possibleNode = node as? Bit
                    
                    if possibleNode?.name == nil { continue }
                    
                    if possibleNode?.name! == "gold" || possibleNode?.name! == "silver" || possibleNode?.name! == "lilac" || possibleNode?.name! == "plain" {
                        
                        let delayTime = NSTimeInterval(effectDelayTracker * 0.05)
                        meteorShowerController.moveToCorrespondingCurrency(&possibleNode!, effectDelay: delayTime)
                        effectDelayTracker++
                        if effectDelayTracker == 5 { effectDelayTracker = 0 }
                    }
                }
            }
    
        }
        else if sender.state == UIGestureRecognizerState.Ended {
            
            if state == GameState.PlayerShooting.rawValue || state == GameState.ShootingOffBounds.rawValue {
                state = GameState.GameIdle.rawValue
                
                equippedWeapon.stopShooting()
            }
            else if state == GameState.PlayerCollecting.rawValue {
                effectDelayTracker = 0.0
                state = GameState.GameIdle.rawValue
            }
        }
        
        else if sender.state == UIGestureRecognizerState.Cancelled {
            if state == GameState.PlayerShooting.rawValue || state == GameState.ShootingOffBounds.rawValue {
                state = GameState.GameIdle.rawValue
                
                equippedWeapon.stopShooting()
            }
            else if state == GameState.PlayerCollecting.rawValue {
                effectDelayTracker = 0.0
                state = GameState.GameIdle.rawValue
            }
        }
    }
    
    // Return the new touchLocation and vector from the pan gesture recognizer
    func updateShootingInformation(sender: UIGestureRecognizer) -> (CGPoint, CGPoint) {
        let tempLocation = sender.locationInView(self.view!)
        let touchLocation = CGPointMake(tempLocation.x, self.frame.maxY - tempLocation.y) // for some reason the y coordinates are flipped??
        let targetVector = vectorSubtract(touchLocation, right: beginningLocation)
        equippedWeapon.currentVector = targetVector
        equippedWeapon.currentTouchLocation = touchLocation
        return (touchLocation, targetVector)
    }
    
    // Updates the game data with the given currency key, and updates the text
    func updateCurrency(key: String, value: Int, animate: Bool) {
        if value > 0 && animate == true {
            gameMenu.makeCurrencyParticles(key)
            let scaleUp = SKAction.scaleTo(_scale + 0.2, duration: 0.1)
            let scaleDown = SKAction.scaleTo(_scale, duration: 0.1)
            currencyNode.childNodeWithName("\(key)-icon")?.runAction(SKAction.sequence([scaleUp, scaleDown]))
        }
        
        //if value < 0 { return }
                
        // Make sure they don't go over 999
        if GameData.sharedInstance.currency![key]! + value > 999 {
            GameData.sharedInstance.currency![key] = 999
        }
        else {
            GameData.sharedInstance.currency![key]! += value
        }
        
        let newNum = GameData.sharedInstance.currency![key]!
        
        (currencyNode.childNodeWithName(key) as! BitMapFontLabel).set_Text("\(newNum)")
    }
    
    // queue up the boost wave!
    func addNativeXReward(amount: Int) {
        
        if self.onMapScene == true {
            nextScene.addNativeXReward()
            return
        }
        
        meteorShowerController.queuedCurrencyShowers++
        
        if self.gameHasStarted == true {
            self.boostMenu.dismissMenu()
            meteorShowerController.beginCurrencyShower(boostMenu.currencySelected)
        }
    }
    
    // Called when nativex was unable to launch
    func onNativeXError() {
        nativeX_disabled = true
    }
    
    override func update(currentTime: CFTimeInterval) {

    }
}
