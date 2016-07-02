//
//  Missile.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 3/30/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

// Missile is a category of a Weapon.
// shoot() must be overriden
// This weapon shoots one projectile that does critical damage, as well as splash damage
// on nearby meteors
// Short cooldown
//
// @param coolDown the amount of time the user must wait between shots
// @param canShoot determines whether the weapon can shoot or not
class Missile: Weapon {
    
    var missileCounter: Int = 1
    var soundCounter: Int = 1
    
    convenience init(texture: SKTexture!, color: UIColor!, size: CGSize, name: String, level: Int, sublevel: Int, parentScene: GameScene) {
        self.init(texture: texture, color: color, size: size)
        self.weaponName = name
        self.level = level
        self.sublevel = sublevel
        self.parentScene = parentScene
        
        self.coolDown = 0.9
        
        self.levelDamage = 7
        self.sublevelDamage = 4
    }
    
    // If the weapon can shoot, spawn a projectile and have it move in the direction the user tapped
    override func shoot(touchLocation: CGPoint, vector: CGPoint) {
        super.rotateToFaceTouch(vector)
        if canShoot == true {
            
            currentVector = vector
            //var spawnAction = SKAction.runBlock({ self.spawnMissile(touchLocation)})
            //var waitAction = SKAction.waitForDuration(coolDown)
            //var canShootNow = SKAction.runBlock({ self.canShoot = true })
            
            // The code below lets the weapon shoot continously
            /*self.runAction(SKAction.sequence([waitAction, canShootNow]))
            self.runAction(SKAction.repeatActionForever(SKAction.sequence([spawnAction, waitAction])), withKey: "shooting")*/
            
            self.spawnMissile(touchLocation)
        }
    }
    
    // Spawns a projectile and makes it travel in the direction of the player's tap
    func spawnMissile(touchLocation: CGPoint) {
        let missileTextureString = "rocket-\(self.level)"
        let texture = SKTexture(imageNamed: missileTextureString)
        var moveSpeed: NSTimeInterval
        
        if parentScene.IS_IPAD == true {
            moveSpeed = 2.5
        }
        else {
            moveSpeed = 3.0
        }
        
        // Create
        let missile = Projectile(texture: texture, color: UIColor.clearColor(), size: texture.size(), damage: getDamage(), type: Projectile.ProjectileType.Missile.rawValue)
        missile.anchorPoint = CGPointMake(0.5, 0)
        missile.setScale(scale)
        
        // Position
        let missile_vector = currentVector.normalized
        missile.position = vectorSubtract(self.position, right: vectorMultiply(missile_vector, factor: -2 * self.size.height/3))
        missile.rotateToFaceTouch(missile_vector)
        
        // Physics stuff
        missile.physicsBody = SKPhysicsBody(rectangleOfSize: missile.size)
        missile.physicsBody!.dynamic = true
        missile.physicsBody!.affectedByGravity = false
        missile.physicsBody!.categoryBitMask = ColliderType.Projectile.rawValue
        missile.physicsBody!.contactTestBitMask = ColliderType.Meteor.rawValue
        missile.physicsBody?.collisionBitMask = ColliderType.Object.rawValue
        missile.physicsBody!.allowsRotation = true
        
        var dest = vectorSubtract(touchLocation, right: vectorMultiply(missile_vector, factor: -700))
        
        switch missileCounter {
        case 1:
            if level == 2 {
                missile.position.x += missile.size.width/2
                dest.x += missile.size.width/2
            }
            else if level == 3 {
                missile.position.y += 5
                missile.zPosition = -1
            }
            break
        case 2:
            missile.position.x -= missile.size.width/2
            dest.x -= missile.size.width/2
            break
        default: //3
            missile.position.x += missile.size.width/2
            dest.x += missile.size.width/2
            break
        }
        
        if ++missileCounter > level {
            missileCounter = 1
        }
        
        let move = SKAction.moveTo(dest, duration: moveSpeed)
        let moveAction = SKAction.sequence([move, SKAction.removeFromParent()])
        
        // Add and move to destination
        parentScene.addChild(missile)
        missile.runAction(moveAction)
    
        switch soundCounter {
        case 1:
            AudioManager.sharedInstance.playSound("missile_launcher_shoot")
            soundCounter++
            break
        case 2:
            AudioManager.sharedInstance.playSound("missile_launcher_shoot2")
            soundCounter++
            break
        default:
            soundCounter = 1
            AudioManager.sharedInstance.playSound("missile_launcher_shoot3")
            break
        }
    }
    
    // Anything special that the weapon has to do when the player stops touching/holding
    override func stopShooting() {
        
        if missileCounter == 1 {
            if self.actionForKey("coolDown") == nil {
                canShoot = false
                self.runAction(SKAction.sequence([SKAction.waitForDuration(self.coolDown), SKAction.runBlock({ self.canShoot = true })]), withKey: "coolDown")
            }
        }
    }
}