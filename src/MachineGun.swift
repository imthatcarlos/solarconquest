//
//  MachineGun.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 3/30/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

// MachineGun is a category of a Weapon. 
// shoot() must be overriden
// This weapon shoots continuously as long as the player is touching the screen
class MachineGun: Weapon {
    
    var soundCounter: Int = 1
        
    convenience init(texture: SKTexture!, color: UIColor!, size: CGSize, name: String, level: Int, sublevel: Int, parentScene: GameScene) {
        self.init(texture: texture, color: color, size: size)
        self.weaponName = name
        self.level = level
        self.sublevel = sublevel
        self.parentScene = parentScene

        self.coolDown = 0.35
        self.levelDamage = 3
        self.sublevelDamage = 0.8
        
    }
    
    override func shoot(touchLocation: CGPoint, vector: CGPoint) {
        if canShoot == true {
            self.canShoot = false
            currentVector = vector
            currentTouchLocation = touchLocation
            super.rotateToFaceTouch(vector)
            let wait = SKAction.waitForDuration(0.5)
            let shoot = SKAction.runBlock({ self.spawnBullets() })
            self.runAction(SKAction.repeatActionForever(SKAction.sequence([shoot, wait])), withKey: "shooting")
        }
    }
    
    func spawnBullets() {
    
        // Create the sprite node
        let bulletTextureString = "bullet-\(self.level)"
        let texture = SKTexture(imageNamed: bulletTextureString)
        
        let bullet = Projectile(texture: texture, color: UIColor.clearColor(), size: texture.size(), damage: getDamage(), type: Projectile.ProjectileType.Bullet.rawValue)
        bullet.rotateToFaceTouch(currentVector)
        bullet.setScale(scale)
        
        bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.size)
        bullet.physicsBody?.affectedByGravity = false
        bullet.physicsBody?.categoryBitMask = ColliderType.Projectile.rawValue
        bullet.physicsBody?.contactTestBitMask = ColliderType.Meteor.rawValue
        bullet.physicsBody?.collisionBitMask = ColliderType.Object.rawValue
        bullet.physicsBody?.dynamic = false
        
        let bullet_vector = currentVector.normalized
        bullet.position = vectorSubtract(self.position, right: vectorMultiply(bullet_vector, factor: -2 * self.size.height/2))
        
        // Position stuff
        let dest = vectorSubtract(currentTouchLocation, right: vectorMultiply(bullet_vector, factor: -700))
        let moveAction = SKAction.moveTo(dest, duration: 1.2)
        let scaleAction = SKAction.scaleTo(scale - 0.4, duration: 0.8)
        
        // Add and move to destination
        self.parentScene.addChild(bullet)
        bullet.runAction(SKAction.group([scaleAction, SKAction.sequence([moveAction, SKAction.removeFromParent()])]))
        
        // There are two instances of the same sound
        AudioManager.sharedInstance.playSound("machine_gun_shoot_\(soundCounter)", loopCount: 0)
        soundCounter++
        if soundCounter == 4 {
            soundCounter = 1
        }
    }
}