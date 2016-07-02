//
//  BoostMenu.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 8/17/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

class BoostMenu: SKSpriteNode {
    
    var parentScene: GameScene!
    var scale: CGFloat!
    
    var placementDictionary = [String:CGPoint]()
    var sprites = [String: SKSpriteNode]()

    var bgNode: SKSpriteNode!
    var currencySelected: String!
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(parentScene: GameScene, scale: CGFloat, size: CGSize) {
        
        self.init(texture:nil, color: UIColor.clearColor(), size: size)
        
        let bgColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        bgNode = SKSpriteNode(color: bgColor, size: size)
        bgNode.anchorPoint = CGPointMake(0, 0)
        bgNode.alpha = 0
        bgNode.zPosition = 40
        
        self.parentScene = parentScene
        self.scale = scale
        
        // Textures are a bit too small... 
        if parentScene.IS_IPAD == true {
            self.scale = scale + 0.3
        }
        
        readPlacements()
        prepareSprites()
        addSprites()
        
        self.hidden = true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first! 
        let touchLocation = touch.locationInNode(self)
        let nodeTouched = self.nodeAtPoint(touchLocation)
        
        if nodeTouched.name == nil { return }
        
        if nodeTouched.name!.hasPrefix("lilac") {
            switchCurrencySelected("lilac", withSound: true)
        }
        else if nodeTouched.name!.hasPrefix("silver") {
            switchCurrencySelected("silver", withSound: true)
        }
        else if nodeTouched.name!.hasPrefix("gold") {
            switchCurrencySelected("gold", withSound: true)
        }
        else if nodeTouched.name! == "watch_button" || nodeTouched.name! == "watch_label" && nodeTouched.hidden == false {
            parentScene.nativeXController.displayPlacement()
        }
        else if nodeTouched.name! == "boostMenu_right_nav" {
            dismissMenu()
        }
    }
    
    func displayMenu() {
        self.hidden = false
        
        if parentScene.nativeX_disabled == true {
            sprites["watch_button"]!.hidden = true
            sprites["watch_label"]!.hidden = true
        }
    }
    
    func dismissMenu() {
        self.userInteractionEnabled = false
        bgNode.runAction(SKAction.fadeOutWithDuration(0.2))
        let slide = SKAction.moveToX(-40, duration: 0.1)
        let moveAction = SKAction.sequence([slide, SKAction.moveToX(self.parentScene.size.width, duration: 0.2)])
        self.runAction(moveAction, completion: { self.actuallyDismissMenu() } )
        
        AudioManager.sharedInstance.playSound("dismiss_menu")
    }
    
    private func actuallyDismissMenu() {
        self.runAction(SKAction.waitForDuration(0.15))
        
        bgNode.removeFromParent()
        self.hidden = true
        parentScene.boostMenuButton.hidden = false
        parentScene.menuButton.hidden = false
        parentScene.userInteractionEnabled = true
        parentScene.gestureRecognizer.enabled = true
        
        parentScene.state = GameState.GameIdle.rawValue
    }
    
    func switchCurrencySelected(selected: String, withSound: Bool = false) {
        
        if withSound == true {
            AudioManager.sharedInstance.playSound("button_click")
        }
        
        currencySelected = selected
        
        switch currencySelected {
        case "lilac":
            self.childNodeWithName("silver-icon")!.alpha = 0.4
            self.childNodeWithName("silver-plate")!.alpha = 0.4
            
            self.childNodeWithName("gold-icon")!.alpha = 0.4
            self.childNodeWithName("gold-plate")!.alpha = 0.4
            
            self.childNodeWithName("lilac-icon")!.alpha = 1.0
            self.childNodeWithName("lilac-plate")!.alpha = 1.0
            break
        case "silver":
            self.childNodeWithName("lilac-icon")!.alpha = 0.4
            self.childNodeWithName("lilac-plate")!.alpha = 0.4
            
            self.childNodeWithName("gold-icon")!.alpha = 0.4
            self.childNodeWithName("gold-plate")!.alpha = 0.4
            
            self.childNodeWithName("silver-icon")!.alpha = 1.0
            self.childNodeWithName("silver-plate")!.alpha = 1.0
            break
        default: //gold
            self.childNodeWithName("silver-icon")!.alpha = 0.4
            self.childNodeWithName("silver-plate")!.alpha = 0.4
            
            self.childNodeWithName("lilac-icon")!.alpha = 0.4
            self.childNodeWithName("lilac-plate")!.alpha = 0.4
            
            self.childNodeWithName("gold-icon")!.alpha = 1.0
            self.childNodeWithName("gold-plate")!.alpha = 1.0
        }
    }
    
    func addSprites() {
        for sprite in sprites {
            if sprite.0 != "boostMenuButton" {
                self.addChild(sprite.1)
            }
        }
        
        switchCurrencySelected("lilac")
    }
    
    func prepareSprites() {
        for placement in placementDictionary {
            var sprite: SKSpriteNode
            
            if placement.0 == "watch_label" || placement.0 == "boostMenu_label" {
                sprite = SKSpriteNode(imageNamed: placement.0)
            }
            else if placement.0.hasSuffix("-plate") {
                sprite = SKSpriteNode(texture: parentScene.gameMenu.textures["boostMenu_plate"])
            }
            else {
                sprite = SKSpriteNode(texture: parentScene.gameMenu.textures[placement.0])
            }
            
            sprite.setScale(scale)
            sprite.position = getCorrectPosition(placement.1)
            sprite.name = placement.0
            sprites[placement.0] = sprite
            
            switch placement.0 {
                case "boostMenu_bg":
                    sprite.zPosition = 5
                case "lilac-icon", "gold-icon", "silver-icon", "watch_label":
                    sprite.zPosition = 15
                    sprite.setScale(scale + 0.2)
                default:
                    sprite.zPosition = 10
            }
        }
    }
    
    func readPlacements() {
        var fileName:String
        
        if parentScene.IS_IPAD == false {
            fileName = "boostMenuPlacements"
        }
        else {
            fileName = "boostMenuPlacements_ipad"
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
        
        // for the ipad
        if parentScene.IS_IPAD == true {
            adj_scale = 1.0
            pointConversion = 1.0
        }
        else {
            adj_scale = scale
            pointConversion = 2.0
        }
        
        var adjustedPosition = positionScale(position, scale: adj_scale)
        
        if parentScene.IS_IPHONE_4 == true {
            adjustedPosition.y -= CGFloat(40.0)
        }
        
        return CGPointMake(adjustedPosition.x / pointConversion, adjustedPosition.y / pointConversion)
    }
    
    func addBgNode() {
        parentScene.addChild(bgNode)
        bgNode.runAction(SKAction.fadeInWithDuration(0.05))
    }
}