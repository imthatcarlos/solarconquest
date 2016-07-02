//
//  WeaponMenuNode.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 6/19/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

// Custom sprite node class for weapon nodes in weapon menu

class WeaponMenuNode: SKSpriteNode {
    var icon: SKSpriteNode!
    var levelLabel: SKSpriteNode!
    var levelFrame: SKSpriteNode!
    var levelFill: SKSpriteNode!
    var upgradeButton: SKSpriteNode!
    var unlockButton: SKSpriteNode!
    
    var wasSelected: Bool = false
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        let touch = touches.first! 
        let touchLocation = touch.locationInNode(self)
        let nodeTouched = self.nodeAtPoint(touchLocation) as! SKSpriteNode
        
        // This object is receiving touches outside of bounds sometimes
        if touchLocation.x > self.size.width * 0.6 {
            return
        }
        
        if wasSelected == false {
            AudioManager.sharedInstance.playSound("button_click")
            (parent?.parent as! GameMenu).switchWeaponFocus(self)
            self.changeNodeAlpha(1.0)
            wasSelected = true
            return
        }
        
        if nodeTouched.name == "upgradeButton" && nodeTouched.hidden == false {
            colorizeNodeTouched(nodeTouched)
            (parent?.parent as! GameMenu).upgradeWeapon(self.name!)
        }
        else if  nodeTouched.parent?.name == "upgradeButton" && nodeTouched.parent?.hidden == false {
            colorizeNodeTouched(nodeTouched.parent as! SKSpriteNode)
            (parent?.parent as! GameMenu).upgradeWeapon(self.name!)
        }
        else if nodeTouched.name == "unlockButton" && nodeTouched.hidden == false {
            AudioManager.sharedInstance.playSound("unlock_weapon")
            colorizeNodeTouched(nodeTouched)
            (parent?.parent as! GameMenu).unlockWeapon(self.name!)
        }
        else if nodeTouched.parent?.name == "unlockButton" && nodeTouched.parent?.hidden == false {
            AudioManager.sharedInstance.playSound("unlock_weapon")
            colorizeNodeTouched(nodeTouched.parent as! SKSpriteNode)
            (parent?.parent as! GameMenu).unlockWeapon(self.name!)
        }
    }
    
    private func changeNodeAlpha(value: CGFloat) {
        for child in self.children {
            (child as! SKSpriteNode).alpha = value
        }
    }
    
    private func colorizeNodeTouched(node: SKSpriteNode) {
        let colorize = (SKAction.colorizeWithColor(UIColor.blackColor(), colorBlendFactor: 0.7, duration: 0.05))
        let reverse = SKAction.colorizeWithColorBlendFactor(0.0, duration: 0.05)
        node.runAction(SKAction.sequence([colorize, reverse]))
    }
}