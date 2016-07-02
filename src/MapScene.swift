//
//  MapScene.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 8/2/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit
import StoreKit

class MapScene: SKScene {
    
    var skView: SKView!
    var previousScene: GameScene!
    var viewController: UIViewController!
    var semaphore: dispatch_semaphore_t!
    var nativeXController: NativeXController!
    
    var menuItemAtlasToUse: String?
    var meteorAtlasToUse: String?
    var textureAtlasToUse: SKTextureAtlas?
    
    var IS_IPAD: Bool!
    var scale: CGFloat!
    var planetJustCompleted: String!
    var textures: [String: SKTexture]!
    var placementDictionary = [String:CGPoint]()
    var sprites = [String: SKSpriteNode]()
    var iapController: IAPController!
    var iapPrices = [String: String]()
    
    var currentlySelected:String!
    var iapEnabled = false // iap disabled by default, only enabled when we receive product prices
    var secondPlanetUnlocked = false
    var thirdPlanetUnlocked = false
    var ads_Needed_fire = 5 // not gonna be nice and save... watch all 5 right now! 
    var ads_Needed_ice = 5
    var buyAmountLabel: BitMapFontLabel!
    var adAmountLabel: BitMapFontLabel!
    
    func earlyInitialize(IS_IPAD: Bool, scale: CGFloat, planetCompleted: String, menuTextures: [String: SKTexture], sem: dispatch_semaphore_t) {
        
        self.IS_IPAD = IS_IPAD
        self.scale = scale
        
        if IS_IPAD == true {
            self.scale = 2.0
        }
        
        self.planetJustCompleted = planetCompleted
        self.textures = menuTextures
        
        self.semaphore = sem
        
        // If we're coming from the title scene
        if previousScene == nil {
            let tempController: NativeXController = NativeXController()
            nativeXController = tempController
            nativeXController.createSessionWithAppID("30541")
            
            previousScene = GameScene.sharedInstance
            previousScene.nativeXController = self.nativeXController
            previousScene.nextScene = self
            previousScene.onMapScene = true
            
            AudioManager.sharedInstance.initialize()
            AudioManager.sharedInstance.preLoad()
        }
        else {
            nativeXController = previousScene.nativeXController
        }
        
        readPlacements()
        prepareSprites()
        addSprites()
        
        iapController = IAPController.sharedInstance
        iapController.initialize(self.viewController, parentScene: self)
        iapController.requestProductData()
    }
    
    override func didMoveToView(view: SKView) {
        
        AudioManager.sharedInstance.stopMusic()
        AudioManager.sharedInstance.setMusic("intro")
        AudioManager.sharedInstance.beginMusic()
        
        self.view?.userInteractionEnabled = true
        self.userInteractionEnabled = true
        GameData.sharedInstance.currentPlanet = "hasYetToChooseNew_\(GameData.sharedInstance.currentPlanet)"
        previousScene.onMapScene = true
        
        // Hide all the buttons initially
        hideOffers()
        sprites["travel_button"]!.hidden = true
        sprites["travel_label"]!.hidden = true
    }
    
    // Update our view based on the products given
    func updatePrices(products: [String: SKProduct]) {
        for product in products {
            iapPrices[product.1.productIdentifier] = product.1.price.stringValue
        }
        
        notifyReady()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first! 
        let touchLocation = touch.locationInNode(self)
        let nodeTouched = self.nodeAtPoint(touchLocation)
        
        if nodeTouched.name == nil {
            return
        }
        
        if nodeTouched.name!.hasSuffix("-icon") || nodeTouched.name!.hasPrefix("selector_") {
            processSelection(nodeTouched.name!)
        }
        else if nodeTouched.name! == "secondPlanetLock" {
            processSelection("secondPlanet-icon")
        }
        else if nodeTouched.name! == "thirdPlanetLock" {
            processSelection("thirdPlanet-icon")
        }
        else if (nodeTouched.name! == "travel_label" || nodeTouched.name! == "travel_button") && self.childNodeWithName("travel_button")?.hidden == false {
            colorizeNodeTouched(sprites["travel_button"]!)
            colorizeNodeTouched(sprites["travel_label"]!)
            travel()
        }
        else if (nodeTouched.name! == "watch_button" || nodeTouched.name! == "watch_label" || nodeTouched.name == "adAmount_label") && adAmountLabel.hidden == false {
            colorizeNodeTouched(sprites["watch_button"]!)
            colorizeNodeTouched(sprites["watch_label"]!)
            nativeXController.displayPlacement()
        }
        else if (nodeTouched.name! == "buy_button" || nodeTouched.name! == "buy_label" || nodeTouched.name! == "buyAmount_label") && buyAmountLabel.hidden == false {
            colorizeNodeTouched(sprites["buy_button"]!)
            colorizeNodeTouched(sprites["buy_label"]!)
            switch currentlySelected {
                case "secondPlanet":
                    iapController.buyProduct("solar_conquest_second_planet")
                default: // thirdPlanet
                    iapController.buyProduct("third_planet")
            }
        }
        else if nodeTouched.name! == "restore_button" || nodeTouched.name! == "restore_label" {
            colorizeNodeTouched(sprites["restore_button"]!)
            colorizeNodeTouched(sprites["restore_label"]!)
            iapController.buyProduct("RESTORE")
        }
    }
    
    func processSelection(nodeTouched: String) {
        
        self.childNodeWithName("selector_\(currentlySelected)")?.removeAllActions()
        self.childNodeWithName("selector_\(currentlySelected)")?.hidden = true
        self.childNodeWithName("preview_\(currentlySelected)")?.hidden = true
        
        AudioManager.sharedInstance.playSound("button_click")
        
        switch nodeTouched {
            case "firstPlanet-icon", "selector_firstPlanet":
                currentlySelected = "firstPlanet"
                self.childNodeWithName("preview_firstPlanet")?.hidden = false
                self.childNodeWithName("selector_firstPlanet")?.hidden = false
                
                // spin!
                var selector = self.childNodeWithName("selector_firstPlanet")! as! SKSpriteNode
                runSpinAction(&selector)
                
                hideOffers()
                self.childNodeWithName("travel_button")?.hidden = false
                
                break
            
            case "secondPlanet-icon", "selector_secondPlanet":
                currentlySelected = "secondPlanet"
                self.childNodeWithName("preview_secondPlanet")?.hidden = false
                self.childNodeWithName("selector_secondPlanet")?.hidden = false
                
                // spin!
                var selector = self.childNodeWithName("selector_secondPlanet")! as! SKSpriteNode
                runSpinAction(&selector)
                
                if !secondPlanetUnlocked {
                    showOffers()
                    if iapEnabled == false {
                        buyAmountLabel.hidden = true
                        sprites["buy_button"]!.hidden = true
                        sprites["buy_label"]!.hidden = true
                    }
                    else {
                        let price = iapPrices["solar_conquest_second_planet"]!
                        buyAmountLabel.set_Text("\(price)", centered: true)
                    }
                    
                    if previousScene.nativeX_disabled == true {
                        sprites["watch_button"]!.hidden = true
                        sprites["watch_label"]!.hidden = true
                        adAmountLabel.hidden = true
                    }
                    else {
                        adAmountLabel.set_Text("x\(ads_Needed_ice)", centered: true)
                    }
                    
                }
                else {
                    hideOffers()
                }
                
                break
            
            default:
                currentlySelected = "thirdPlanet"
                self.childNodeWithName("preview_thirdPlanet")?.hidden = false
                self.childNodeWithName("selector_thirdPlanet")?.hidden = false
                
                // spin!
                var selector = self.childNodeWithName("selector_thirdPlanet")! as! SKSpriteNode
                runSpinAction(&selector)
                
                if !thirdPlanetUnlocked {
                    showOffers()
                    if iapEnabled == false {
                        buyAmountLabel.hidden = true
                        sprites["buy_button"]!.hidden = true
                        sprites["buy_label"]!.hidden = true
                    }
                    else {
                        let price = iapPrices["third_planet"]!
                        buyAmountLabel.set_Text("\(price)", centered: true)
                    }
                    
                    if previousScene.nativeX_disabled == true {
                        sprites["watch_button"]!.hidden = true
                        sprites["watch_label"]!.hidden = true
                        adAmountLabel.hidden = true
                    }
                    else {
                        adAmountLabel.set_Text("x\(ads_Needed_fire)", centered: true)
                    }
                    
                }
                else {
                    hideOffers()
                }
                
                break
        }
    }

    func showOffers() {
        sprites["travel_button"]!.hidden = true
        sprites["travel_label"]!.hidden = true
        
        sprites["watch_button"]!.hidden = false
        sprites["watch_label"]!.hidden = false
        adAmountLabel.hidden = false
        
        sprites["buy_button"]!.hidden = false
        sprites["buy_label"]!.hidden = false
        buyAmountLabel.hidden = false
        
    }
    
    func hideOffers() {
        sprites["travel_button"]!.hidden = false
        sprites["travel_label"]!.hidden = false
        
        sprites["watch_button"]!.hidden = true
        sprites["watch_label"]!.hidden = true
        adAmountLabel.hidden = true
        
        sprites["buy_button"]!.hidden = true
        sprites["buy_label"]!.hidden = true
        buyAmountLabel.hidden = true
    }
    
    func itemPurchased(productIdentifier: String) {
        if productIdentifier == "solar_conquest_second_planet" && secondPlanetUnlocked == false {
            secondPlanetUnlocked = true
            unlockPlanet("secondPlanet")
        }
        else if productIdentifier == "third_planet" && thirdPlanetUnlocked == false {
            unlockPlanet("thirdPlanet")
        }
    }
    
    // If there was any error... disable iap and notify that we are ready
    // This function should only be called when we request products, before this
    // scene is presen
    func onIapError() {
        iapEnabled = false
        notifyReady()
    }

    // The player has to watch 5 ads before a planet is unlocked.
    // Once it's unlocked, save as though the player bought it
    func addNativeXReward() {
        
        // Just selecting one.
        if currentlySelected == nil {
            ads_Needed_ice -= 1
            return
        }
        
        if currentlySelected == "secondPlanet" {
            adAmountLabel.set_Text("x\(--ads_Needed_ice)", centered: true)
        }
        else {
            adAmountLabel.set_Text("x\(--ads_Needed_fire)", centered: true)
        }
        
        if ads_Needed_ice == 0 && secondPlanetUnlocked == false {
            unlockPlanet("secondPlanet")
        }
        else if ads_Needed_fire == 0 && thirdPlanetUnlocked == false {
            unlockPlanet("thirdPlanet")
        }
    }
    
    func unlockPlanet(planet: String) {
        let unlockAction = SKAction.sequence([SKAction.scaleTo(scale + 0.2, duration: 0.5), SKAction.fadeOutWithDuration(0.5)])
        
        hideOffers()
        
        if planet == "secondPlanet" {
            secondPlanetUnlocked = true
            GameData.sharedInstance.iap_purchased?.append("secondPlanet")
            self.childNodeWithName("secondPlanetLock")!.runAction(unlockAction)
        }
        else {
            thirdPlanetUnlocked = true
            GameData.sharedInstance.iap_purchased?.append("thirdPlanet")
            self.childNodeWithName("thirdPlanetLock")!.runAction(unlockAction)
        }
        
        GameData.save()
    }
    
    func travel() {
        let semaphore = dispatch_semaphore_create(0)
        self.userInteractionEnabled = false
        
        GameData.sharedInstance.reset()
        GameData.sharedInstance.currentPlanet = currentlySelected
        
        if previousScene.gameHasStarted == false {
            prepareGameScene(semaphore)
        }
        else {
            previousScene.reset(semaphore)
            previousScene.skView = self.skView
        }
        
        // Wait here for notification from next scene
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            let timeout = dispatch_time(DISPATCH_TIME_NOW, Int64(10)) // 10 sec timeout
            dispatch_semaphore_wait(semaphore, timeout)
            
            dispatch_async(dispatch_get_main_queue(), {
                self.showNextScene()
            })
        })
    }
    
    func showNextScene() {

        let transition = SKTransition.fadeWithDuration(1.0)
        let presentScene = SKAction.runBlock({ self.skView.presentScene(self.previousScene, transition: transition) })
        let removeStuff = SKAction.runBlock({ self.removeAllChildren() })
        
        self.runAction(SKAction.sequence([presentScene, removeStuff]))
    }
    
    func prepareGameScene(semaphore: dispatch_semaphore_t) {
        
        /* Set the scale mode to scale to fit the window */
        previousScene.scaleMode = .AspectFill
        previousScene.size = self.skView.bounds.size
        if self.IS_IPAD == true {
            previousScene._scale = 1.65
        }
        else {
            previousScene._scale = scale
        }
        previousScene.atlas = textureAtlasToUse
        previousScene.meteorAtlasToUse = meteorAtlasToUse
        previousScene.menuItemAtlasToUse = menuItemAtlasToUse
        previousScene.IS_IPAD = IS_IPAD
        previousScene.viewController = viewController
        previousScene.skView = self.skView
        
        // now that scene should initialize all of its stuff
        previousScene.earlyInitialize(semaphore)
    }
    
    // Just prepare all the sprites we will need
    func prepareSprites() {
        for placement in placementDictionary {
            let spriteName = placement.0 as String
            var sprite: SKSpriteNode!
            
            if spriteName == "map_bg" {
                sprite = SKSpriteNode(imageNamed: "map_bg")
                sprite.name == "bg"
                sprite.anchorPoint = CGPointMake(0, 1)
                sprite.position = CGPointMake(0, self.frame.size.height)
                
                if IS_IPAD == false {
                    sprite.setScale(scale)
                }
            }
            else if spriteName == "adAmount_label" {
                adAmountLabel = BitMapFontLabel(text: "x\(ads_Needed_ice)", fontName: "number_", usingAtlas: "atlas_fonts", centered: true)
                adAmountLabel.setScale(scale + 0.2)
                adAmountLabel.position = getCorrectPosition(placement.1)
                adAmountLabel.name = spriteName
                adAmountLabel.zPosition = 10
                adAmountLabel.hidden = true
            }
            else if spriteName == "buyAmount_label" {
                buyAmountLabel = BitMapFontLabel(text: "x\(0)", fontName: "number_", usingAtlas: "atlas_fonts", centered: true)
                buyAmountLabel.setScale(scale + 0.2)
                buyAmountLabel.position = getCorrectPosition(placement.1)
                buyAmountLabel.name = spriteName
                buyAmountLabel.zPosition = 10
                buyAmountLabel.hidden = true
            }
            else if spriteName.hasSuffix("_label") {
                sprite = SKSpriteNode(imageNamed: spriteName)
                sprite.position = getCorrectPosition(placement.1)
                sprite.name = spriteName
                if spriteName != "restore_label" {
                    sprite.setScale(scale + 0.2)
                }
                else {
                    sprite.setScale(scale - 0.1)
                }
            }
            else {
                sprite = SKSpriteNode(texture: textures[spriteName]!)
                sprite.position = getCorrectPosition(placement.1)
                sprite.name = spriteName
                sprite.setScale(scale)
            }
            
            // if it was either of the font labels, skip the rest
            if sprite == nil {
                continue
            }
            
            // take care of the zpositions
            switch spriteName {
                case "map_bg":
                    sprite.zPosition = 0
                    break
                case "map-ui":
                    sprite.zPosition = 5
                    break
                case "orbit":
                    sprite.zPosition = 6
                    break
                case "preview_frame":
                    sprite.zPosition = 7
                    break
                case "lockedIcon":
                    sprite.zPosition = 10
                    break
                case "moreInfo":
                    sprite.userInteractionEnabled = false
                    sprite.zPosition = 7
                    break
                case "travel_label", "buy_label", "watch_label", "restore_label":
                    sprite.zPosition = 10
                default:
                    sprite.zPosition = 8
            }
            
            sprites[spriteName] = sprite
        }
    }
    
    func addSprites() {
        
        // Add all necessary sprites to screen
        for sprite in sprites {
            if (sprite.0.hasPrefix("preview_") && sprite.0 != "preview_frame") || sprite.0.hasPrefix("selector"){
                sprite.1.hidden = true
            }
            else if sprite.0 == "lockedIcon" {
                continue
            }
            
            self.addChild(sprite.1)
        }
        
        self.addChild(buyAmountLabel)
        self.addChild(adAmountLabel)
        
        // Add locked icons where needed, as well as font labels for prices/ads to watch
        for iapName in GameData.sharedInstance.iap_purchased! {
            if iapName == "secondPlanet" {
                secondPlanetUnlocked = true
            }
            else if iapName == "thirdPlanet" {
                thirdPlanetUnlocked = true
            }
        }
        
        if secondPlanetUnlocked == false {
            let lock = (sprites["lockedIcon"]!).copy() as! SKSpriteNode
            lock.name = "secondPlanetLock"
            lock.position = sprites["secondPlanet-icon"]!.position
            lock.hidden = false
            self.addChild(lock)
        }
        
        if thirdPlanetUnlocked == false {
            let lock2 = (sprites["lockedIcon"]!).copy() as! SKSpriteNode
            lock2.name = "thirdPlanetLock"
            lock2.position = sprites["thirdPlanet-icon"]!.position
            lock2.hidden = false
            self.addChild(lock2)
            return
        }
    }
    
    func readPlacements() {
        var fileName:String
        
        if IS_IPAD == false {
            fileName = "mapPlacements"
        }
        else {
            fileName = "mapPlacements"
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
    
    private func positionScale(position: CGPoint, scale: CGFloat) -> CGPoint {
        return CGPointMake(position.x * scale, position.y * scale)
    }
    
    func getCorrectPosition(position: CGPoint) -> CGPoint {
        var adj_scale: CGFloat
        var pointConversion: CGFloat
        var adjustedPosition: CGPoint
        
        // for the ipad
        if IS_IPAD == true {
            adj_scale = 1.0
            pointConversion = 1.0
            
            // For some reason this menu is shifted up on the ipad >:(
            adjustedPosition = CGPointMake(position.x, position.y - 160)
        }
        else {
            adj_scale = scale
            pointConversion = 2.0
            adjustedPosition = positionScale(position, scale: adj_scale)
        }
        
        if previousScene.IS_IPHONE_4 == true {
            adjustedPosition.y -= CGFloat(40.0)
        }
        
        return CGPointMake(adjustedPosition.x / pointConversion, adjustedPosition.y / pointConversion)
    }
    
    private func colorizeNodeTouched(node: SKSpriteNode) {
        let colorize = (SKAction.colorizeWithColor(UIColor.blackColor(), colorBlendFactor: 0.7, duration: 0.05))
        let reverse = SKAction.colorizeWithColorBlendFactor(0.0, duration: 0.05)
        node.runAction(SKAction.sequence([colorize, reverse]))
        
        for child in node.children {
            child.runAction(SKAction.sequence([colorize, reverse]))
        }
    }
    
    func runSpinAction(inout selector: SKSpriteNode) {
        let spin = SKAction.rotateByAngle(CGFloat(M_PI), duration: 1.0)
        selector.runAction(SKAction.repeatActionForever(spin))
    }
    
    func notifyReady() {
        dispatch_semaphore_signal(semaphore)
    }
    
}