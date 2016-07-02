//
//  Laser.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 3/30/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

// Laser is a category of a Weapon.
// shoot() must be overriden
// This weapon shoots a beam that lasts 2.0 seconds
class Laser: Weapon {
    
    var currentBeam: Projectile!
    var continueSpawning: Bool = true
    
    convenience init(texture: SKTexture!, color: UIColor!, size: CGSize, name: String, level: Int, sublevel: Int, parentScene: GameScene) {
        self.init(texture: texture, color: color, size: size)
        self.weaponName = name
        self.level = level
        self.sublevel = sublevel
        self.parentScene = parentScene
        coolDown = 2.5
        
        self.levelDamage = 1.4
        self.sublevelDamage = 0.4
    }
    
    override func shoot(touchLocation: CGPoint, vector: CGPoint) {
        currentVector = vector
        currentTouchLocation = touchLocation
        rotateToFaceTouch(vector)
        
        if currentBeam == nil && canShoot == true {
            canShoot = false
            let spawn = SKAction.runBlock({ self.spawnLaser() })
            let wait = SKAction.waitForDuration(coolDown)
            self.runAction(SKAction.repeatActionForever(SKAction.sequence([spawn, wait])), withKey: "shooting")
        }
    }
    
    func spawnLaser() {
        
        let beamTextureString = "beam-\(self.level)"
        let texture = SKTexture(imageNamed: beamTextureString)
        let beam = Projectile(texture: texture, color: UIColor.clearColor(), size: CGSizeMake(0, texture.size().height), damage: getDamage(), type: Projectile.ProjectileType.Beam.rawValue)
        currentBeam = beam
        
        beam.anchorPoint = CGPointMake(0.5, 0)
        let beam_vector = currentVector.normalized
        let beam_position = vectorSubtract(self.position, right: vectorMultiply(beam_vector, factor: -2 * self.size.height/2))
        beam.position = parentScene.convertPoint(beam_position, toNode: self)
        beam.zPosition = 2
        
        // Physics stuff
        beam.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(20, 1000))
        beam.physicsBody?.affectedByGravity = false
        beam.physicsBody?.categoryBitMask = ColliderType.Projectile.rawValue
        beam.physicsBody?.contactTestBitMask = ColliderType.Meteor.rawValue
        beam.physicsBody?.collisionBitMask = ColliderType.Object.rawValue
        beam.physicsBody?.dynamic = false

        // effects stuff
        let wait = SKAction.waitForDuration(1.5)
        let remove = SKAction.runBlock({ beam.removeFromParent(); self.parentScene.meteorShowerController?.removeAllBurning(); self.currentBeam = nil })
        let resizeUP = SKAction.resizeToWidth(texture.size().width, duration: 0.1)
        let resizeDOWN = SKAction.resizeToWidth(0, duration: 0.1)
        
        self.addChild(beam)
        beam.runAction(SKAction.sequence([resizeUP, wait, resizeDOWN, remove]))
        
        AudioManager.sharedInstance.playSound("laser_shoot")
        
    }
    
    override func stopShooting() {
        self.removeActionForKey("shooting")

        // If the beam is still on-screen, the wait time should be longer...
        if self.actionForKey("coolDown") == nil {
            self.runAction(SKAction.sequence([SKAction.waitForDuration(self.coolDown/3), SKAction.runBlock({ self.canShoot = true })]), withKey: "coolDown")
        }
    }
}