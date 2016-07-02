//
//  SettingMenuNode.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 6/20/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

class SettingMenuNode: SKSpriteNode {
    
    var parentScene: GameScene!
    var slider: SKSpriteNode!
    var slider_back: SKSpriteNode!
    var icon: SKSpriteNode!
    var minX: CGFloat!
    var maxX: CGFloat!
    var canMove = false
    var rangeValues = [CGFloat]()
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        
    }
    
    convenience init(texture: SKTexture!, color: UIColor!, size: CGSize, parentScene: GameScene) {
        self.init(texture: texture, color: color, size: size)
        self.parentScene = parentScene
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSlider(minX: CGFloat, maxX: CGFloat) {
        let range = maxX - minX
        var divisor: CGFloat
        
        self.minX = minX
        self.maxX = maxX
        
        slider.position.x = minX + (range * CGFloat(Double(GameData.sharedInstance.settings![self.name!]!) / 10))
        if slider.position.x == minX {
            icon.alpha = 0.5
        }
        
        for index in 0...9 {
            if index != 0 && index != 9 {
                divisor = CGFloat(CGFloat(index) / 9.0)
                rangeValues.append( minX + (range * (divisor)))
            }
            else if index == 0 {
                rangeValues.append(minX)
            }
            else if index == 9 {
                rangeValues.append(maxX)
            }
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        let touchLocation = (touches.first)!.locationInNode(self)
        if isWithinRangeofSlider(touchLocation) {
            canMove = true
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if canMove == true {
            let newX = (touches.first)!.locationInNode(self).x - slider.size.width
            if (slider.position.x > minX && slider.position.x < maxX) {
                
                if icon.alpha != 1 {
                    icon.alpha = 1
                }
                
                slider.position.x = newX
            }
            else if slider.position.x <= minX && newX > minX {
                slider.position.x = newX
            }
            else if slider.position.x >= maxX && newX < maxX {
                slider.position.x = newX
            }
            
            // At the end of the day, we don't want the slider to go past the bounds
            if slider.position.x < minX {
                icon.alpha = 0.5
                slider.position.x = minX
            }
            else if slider.position.x > maxX {
                slider.position.x = maxX
            }
            
            updateSetting(slider.position.x)
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        canMove = false
    }
    
    func isWithinRangeofSlider(touchLocation: CGPoint) -> Bool {
        
        var ret = false
        if touchLocation.x > (slider.position.x - (slider.size.width/2)) && touchLocation.x < (slider.position.x + slider.size.width * 1.5) {
            if touchLocation.y > (slider.position.y - (slider.size.height * 1.25)) && touchLocation.y < (slider.position.y + (slider.size.height * 0.25)) {
                ret = true
            }
        }
        
        return ret
    }

    func updateSetting(sliderPositionX: CGFloat) {
        var newSetting = 1
        
        switch sliderPositionX {
        case minX:
            newSetting = 0
            break
        case rangeValues[0]...rangeValues[1]:
            newSetting = 1
            break
        case rangeValues[1]...rangeValues[2]:
            newSetting = 2
            break
        case rangeValues[2]...rangeValues[3]:
            newSetting = 3
            break
        case rangeValues[3]...rangeValues[4]:
            newSetting = 4
            break
        case rangeValues[4]...rangeValues[5]:
            newSetting = 5
            break
        case rangeValues[5]...rangeValues[6]:
            newSetting = 6
            break
        case rangeValues[6]...rangeValues[7]:
            newSetting = 7
            break
        case rangeValues[7]...rangeValues[8]:
            newSetting = 8
            break
        case rangeValues[8]...rangeValues[9]:
            newSetting = 9
            break
        case maxX:
            newSetting = 10
            break
        default:
            break
        }
        
        AudioManager.sharedInstance.updateVolume(newSetting, forSetting: self.name!)
        GameData.sharedInstance.settings!.updateValue(newSetting, forKey: self.name!)
    }
}