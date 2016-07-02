//
//  RailGun.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 4/9/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

// This weapon shoots electric-powered projectiles
// Projectiles take 1.5 seconds before they are at max size
class RailGun: Weapon {
    
    let chargeWait: NSTimeInterval = 1.5
    var elecQueue: [Projectile] = []
    
    convenience init(texture: SKTexture!, color: UIColor!, size: CGSize, name: String, level: Int, sublevel: Int, parentScene: GameScene) {
        self.init(texture: texture, color: color, size: size)
        self.weaponName = name
        self.level = level
        self.sublevel = sublevel
        self.parentScene = parentScene
        
        self.levelDamage = 20
        self.sublevelDamage = 4
    }
    
    // This is called when the player either just tapped, or has started the pan
    override func shoot (touchLocation: CGPoint, vector: CGPoint) {
        if canShoot == true {
            canShoot = false
            super.rotateToFaceTouch(vector)
            currentVector = vector
            currentTouchLocation = touchLocation
            initElec()
        }
    }
    
    // update the position of the elec as well
    override func rotateToFaceTouch(vector: CGPoint) {
        super.rotateToFaceTouch(vector)
        elecQueue[0].position = vectorSubtract(self.position, right: vectorMultiply(currentVector.normalized, factor: -2 * self.size.height * (2/3)))
    }
    
    // Initializing stuff
    func initElec() {
        let textureString = "elec-\(self.level)"
        let texture = SKTexture(imageNamed: textureString)
        let elec = Projectile(texture: texture, color: UIColor.clearColor(), size: texture.size(), damage: getDamage(), type: Projectile.ProjectileType.Elec.rawValue)
        elec.zPosition = 25
        
        elec.setScale(0.1)
        elec.physicsBody = SKPhysicsBody(circleOfRadius: elec.size.width/3)
        elec.physicsBody?.categoryBitMask = ColliderType.Projectile.rawValue
        elec.physicsBody?.contactTestBitMask = ColliderType.Meteor.rawValue
        elec.physicsBody?.collisionBitMask = ColliderType.Object.rawValue
        elec.physicsBody?.affectedByGravity = false
        elec.physicsBody?.dynamic = true
        elec.zPosition = 2
        
        let elec_vector = currentVector.normalized
        elec.position = vectorSubtract(self.position, right: vectorMultiply(elec_vector, factor: -2 * self.size.height * (2/3)))
        parentScene.addChild(elec)
        
        elecQueue.append(elec)
        
        charging(elec)
    }
    
    // The more the user keeps pressing, the larger/stronger the projectile gets
    func charging(elec: Projectile) {
        AudioManager.sharedInstance.playSound("rail_gun_charge")
        
        let scale = SKAction.scaleTo(parentScene._scale, duration: chargeWait)
        let rotate = SKAction.repeatActionForever(SKAction.rotateByAngle(CGFloat(2 * M_PI), duration: chargeWait))
        
        let tiers = SKAction.group([rotate, scale])
        let elecAction = SKAction.runBlock({ elec.runAction(tiers, withKey: "gettingHuge") })
        self.runAction(SKAction.sequence([elecAction, SKAction.waitForDuration(chargeWait), SKAction.runBlock({ elec.isReady = true })]))
    }
    
    func releaseProjectile(playerTriggered: Bool = true) {
        var moveSpeed: NSTimeInterval
        
        if parentScene.IS_IPAD == true {
            moveSpeed = 0.9
        }
        else {
            moveSpeed = 1.2
        }
        
        self.canShoot = true
        
        if elecQueue.isEmpty == true { return }
        
        AudioManager.sharedInstance.stopSound("rail_gun_charge")
        
        let currentElec = elecQueue.removeAtIndex(0) as Projectile
        currentElec.removeActionForKey("gettingHuge")
        self.removeActionForKey("elecAction")
        
        if currentElec.isReady == false {
            currentElec.removeFromParent()
            return
        }
        
        AudioManager.sharedInstance.playSound("rail_gun_shoot")
        
        let dest = vectorSubtract(currentTouchLocation, right: vectorMultiply(currentVector.normalized, factor: -700))
        let moveAction = SKAction.moveTo(dest, duration: moveSpeed)
        currentElec.runAction(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
    }
    
    override func stopShooting() {
        self.releaseProjectile()
    }
}