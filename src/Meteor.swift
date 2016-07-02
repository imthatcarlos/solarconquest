//
//  Meteor.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 3/27/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

// A Meteor encapsulates each meteor node that passes by on-screen. It has "health" and a "currencyType".
// @param health is how much damage it can take from a weapon
// @param currencyType is the kind of currency it contains (i.e silver, gold, platinum)
//
class Meteor : SKSpriteNode {
    
    var controller: MeteorShower!
    var health: Double!
    var currencyType: String!
    var parentNode: SKNode!
    var y_tier: Int!
    var alreadyTookMissileDamage = false
    
    var isDestroyed = false
    var burning = false
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init(texture: SKTexture!, color: UIColor!, size: CGSize, health: Double, currencyType: String, pN: SKNode, controller: MeteorShower) {
        self.init(texture: texture, color: color, size: size)
        self.controller = controller
        self.health = health
        self.currencyType = currencyType
        self.parentNode = pN
    }
    
    // Whenever a weapon's projectile comes into contact with this meteor, "health" drops by the amount
    // of damage the weapon deals. If "health" is zero, the meteor explodes.
    func takeDamage(damage: Double, contactPos: CGPoint, projectile: UInt32) {
        self.health! -= damage
        
        if self.health <= 0 {
            self.isDestroyed = true
            controller.parentScene.meteorWasDestroyed()
            self.explode(contactPos)
            if projectile == Projectile.ProjectileType.Missile.rawValue {
                createSplashExplosion(contactPos)
            }
            
            controller.parentScene.shake()
        }
        else {
            if projectile == Projectile.ProjectileType.Missile.rawValue {
                AudioManager.sharedInstance.playSound("missile_launcher_hit")
                self.createSmoke_cloud(contactPos)
                self.createSplashExplosion(contactPos)
            }
            else if projectile == Projectile.ProjectileType.Bullet.rawValue {
                self.createSpark(contactPos)
            }
            else if projectile == Projectile.ProjectileType.Beam.rawValue { // If the projectile is a beam, meteor should take continuous damage
                self.createBurn()
                if burning == true {
                    self.runAction(SKAction.sequence([SKAction.waitForDuration(0.15), SKAction.runBlock({self.takeDamage(damage, contactPos: contactPos, projectile: projectile)})]), withKey: "takingDamage")
                }
            }
            else if projectile == Projectile.ProjectileType.Elec.rawValue {
                AudioManager.sharedInstance.playSound("rail_gun_hit")
                self.createElectricBolt(contactPos)
            }
            else { // Explosion
                self.runAction(SKAction.sequence([SKAction.runBlock({ self.createBurn() }), SKAction.waitForDuration(0.5), SKAction.runBlock({ self.removeBurn() })]))
            }
        }
    }
    
    func createBurn() {
        if burning == false {
            self.burning = true
            let burn = SKAction.colorizeWithColor(UIColor.redColor(), colorBlendFactor: 0.5, duration: 0.1)
            self.runAction(burn)
        }
    }
    
    func removeBurn() {
        if burning == true {
            self.burning = false
            let removeBurn = SKAction.colorizeWithColorBlendFactor(0.0, duration: 0.1)
            self.runAction(removeBurn)
        }
    }
    
    func createElectricBolt(pos: CGPoint) {
        controller.boltEmitter.particlePosition = controller.parentScene.convertPoint(pos, fromNode: self)
        controller.boltEmitter.resetSimulation()
    }
    
    func createSpark(pos: CGPoint) {
        controller.sparkEmitter.particlePosition = controller.parentScene.convertPoint(pos, fromNode: self)
        controller.sparkEmitter.resetSimulation()
    }
    
    func createSmoke_cloud(pos: CGPoint) {
        controller.smokeEmitter.particlePosition = controller.parentScene.convertPoint(pos, fromNode: self)
        controller.smokeEmitter.resetSimulation()
    }
    
    func createSplashExplosion(pos: CGPoint) {
        alreadyTookMissileDamage = true
        
        let explosion = controller.explosionNode.copy() as! SKSpriteNode
        explosion.position = controller.parentScene.convertPoint(pos, fromNode: self)
        explosion.physicsBody = SKPhysicsBody(circleOfRadius: explosion.size.width/2)
        explosion.physicsBody?.categoryBitMask = ColliderType.Explosion.rawValue
        explosion.physicsBody?.contactTestBitMask = ColliderType.Meteor.rawValue
        explosion.physicsBody?.collisionBitMask = ColliderType.Object.rawValue
        explosion.physicsBody?.affectedByGravity = false
        explosion.physicsBody?.dynamic = false
        explosion.hidden = false
        explosion.alpha = 1
        
        self.parentNode.addChild(explosion)
        
        let animate = SKAction.animateWithTextures(controller.missileExplosionFrames, timePerFrame: 0.05, resize: false, restore: false)
        let remove = SKAction.sequence([SKAction.fadeOutWithDuration(0.25), SKAction.runBlock({ explosion.removeFromParent() })])
        explosion.runAction(SKAction.sequence([animate,
                                                    SKAction.runBlock({ explosion.physicsBody?.contactTestBitMask = ColliderType.Object.rawValue})]), completion: { explosion.runAction(remove) })
    }
    
    // Have to make a copy of these in case multiple meteors explode at once
    func createSmoke_explosion(pos: CGPoint) {
        
        let explosionEmitterCopy = controller.explosionEmitter.copy() as! SKEmitterNode
        let explosionEmitterCopy2 = controller.explosionEmitter2.copy() as! SKEmitterNode
        let particleExplosionCopy = controller.particleExplosion.copy() as! SKEmitterNode
        
        explosionEmitterCopy.particlePosition = controller.parentScene.convertPoint(self.position, fromNode: self)
        explosionEmitterCopy2.particlePosition = controller.parentScene.convertPoint(self.position, fromNode: self)
        particleExplosionCopy.particlePosition = controller.parentScene.convertPoint(self.position, fromNode: self)
                
        controller.parentScene.addChild(explosionEmitterCopy)
        controller.parentScene.addChild(explosionEmitterCopy2)
        
        explosionEmitterCopy.resetSimulation()
        explosionEmitterCopy2.resetSimulation()
        
        if self.currencyType != "plain" {
            controller.parentScene.addChild(particleExplosionCopy)
            particleExplosionCopy.particleTexture = controller.particleTextures[currencyType]!
            particleExplosionCopy.resetSimulation()
        }
        
        controller.parentScene.runAction(SKAction.sequence([SKAction.waitForDuration(3.0), SKAction.runBlock({explosionEmitterCopy.removeFromParent()})]))
        controller.parentScene.runAction(SKAction.sequence([SKAction.waitForDuration(3.0), SKAction.runBlock({explosionEmitterCopy2.removeFromParent()})]))
        controller.parentScene.runAction(SKAction.sequence([SKAction.waitForDuration(3.0), SKAction.runBlock({particleExplosionCopy.removeFromParent()})]))
    }
    
    func explode(pos: CGPoint) {
        self.physicsBody = nil
        
        AudioManager.sharedInstance.playSound("meteor_explode")
        
        spawnBits()
        
        let animateBlock = SKAction.runBlock({ self.hidden = true })
        let smoke = SKAction.runBlock({ self.createSmoke_explosion(pos) })
        let stopTailEmitter = SKAction.runBlock({ (self.parentNode.childNodeWithName("tail") as! SKEmitterNode).particleBirthRate = 0 })
        _ = SKAction.runBlock({ self.hidden = true })
        let wait = SKAction.waitForDuration(5)
        let remove = SKAction.removeFromParent()
        
        parentNode.runAction(SKAction.sequence([stopTailEmitter, smoke, animateBlock, wait, remove]))
    }
    
    func spawnBits() {
        
        let rand =  Int(arc4random_uniform(10)) + 5
        let scale_rand = CGFloat(arc4random_uniform(3)) / 10 // 0 - 0.2
        let bit = MeteorShower.bitDictionary[currencyType]!
        bit.zPosition = 40
        let position = (parentNode.parent!.parent as! GameScene).convertPoint(self.position, fromNode: self)
        var someAngle: Double
        var amount = rand / 4
        
        // Apply the multipler for the streak
        if controller.parentScene.multiplierTracker != 0 {
            amount *= controller.parentScene.multiplierTracker
        }
        
        // Don't want the ground to get too cluttered now
        if controller.debrisArray.count > 40 {
            controller.collectDebris()
        }
        
        for _ in 0...amount {
            
            var clone = bit.copy() as! Bit
            clone.name = "\(currencyType)"
            clone.setScale((controller.parentScene)._scale + scale_rand)
            clone.position = position
            
            clone.physicsBody = SKPhysicsBody(circleOfRadius: clone.size.width/10)
            clone.physicsBody?.affectedByGravity = true
            clone.physicsBody?.categoryBitMask = ColliderType.DontTouchMe.rawValue
            clone.physicsBody?.collisionBitMask = ColliderType.Bit.rawValue
            clone.physicsBody?.angularDamping = 0.3
            clone.physicsBody?.linearDamping = 0.05
            clone.physicsBody?.friction = 0.8
            clone.physicsBody?.restitution = 0
            
            // change rotation
            someAngle = Double(arc4random_uniform(360))
            let radians = someAngle / 180.0 * M_PI
            clone.zRotation = CGFloat(radians)
            
            controller.parentScene.addChild(clone)
            controller.debrisArray.append(clone)
            fallToGround(&clone)
        }
    }
    // Create a path for the bit to follow, and make it simulate a bounce once it hits the ground
    func fallToGround(inout node: Bit) {
       
        let randomOffset = NSTimeInterval( (CGFloat(arc4random_uniform(3)) / 10) * controller._scale)
        let someAngle = Double(arc4random_uniform(180)) + 180
        let radians = CGFloat(someAngle / 180.0 * M_PI)
        let bit_fall_timer = getTimeToFall()
        
        // if it's gonna fall further back reduce the scale
        if randomOffset < 0.3 {
            node.setScale((controller.parentScene)._scale)
        }
        
        // A little sumpin' sumpin' to make it look more dynamic
        let rand = arc4random_uniform(2)
        
        var dx: UInt32
        var dy: UInt32
        var d_velocityY: CGFloat
        var torque: CGFloat
        
        if (controller.parentScene.IS_IPAD == true || controller.parentScene._scale == 1.0) && controller.parentScene.IS_SUPER_HIGH_RES == false {
            dx = 9
            dy = 6
            d_velocityY = 40
            torque = 0.005
        }
        else if controller.parentScene.IS_SUPER_HIGH_RES == true && controller.parentScene.IS_IPAD == true {
            dx = 15
            dy = 6
            d_velocityY = 40
            torque = 0.0005
        }
        else if controller.parentScene.IS_SUPER_HIGH_RES == true {
            dx = 9
            dy = 6
            d_velocityY = 40
            torque = 0.00009
        }
        else {
            dx = 5
            dy = 2
            d_velocityY = 60
            torque = 0.001
        }
        
        if controller.parentScene._scale == 1.0 {
            torque = 0.0005
        }
        
        var rand_dx = (CGFloat(arc4random_uniform(dx)) / 10) + (CGFloat(arc4random_uniform(9)) / 100)
        let rand_dy = (CGFloat(arc4random_uniform(dy)) / 10) + (CGFloat(arc4random_uniform(9)) / 100)
        
        if rand == 0 && node.position.x > 20 {
            rand_dx = -rand_dx
        }
        else if node.position.x < 20 {  // so it doesn't go out of bounds on the left
            rand_dx *= 1.5
        }
        else if node.position.x > controller.parentScene.size.width - 50 { // so it doesn't go out of bounds on the right
            rand_dx  *= -1.5
        }
        
        let impulse = SKAction.runBlock({ node.physicsBody?.applyImpulse(CGVectorMake(rand_dx, rand_dy)) })
        let fall = SKAction.runBlock({ self.physicsBody?.affectedByGravity = true })
        let rotate = SKAction.rotateByAngle(radians, duration: bit_fall_timer + randomOffset)
        let timer = SKAction.waitForDuration(bit_fall_timer + randomOffset)
        let stopGracefully = SKAction.sequence([timer, SKAction.runBlock({ node.physicsBody!.affectedByGravity = false })])
        let outOfBoundsCheck = SKAction.runBlock({ self.outOfBoundsCheck(&node) })
        let floatUpwards = SKAction.runBlock({ node.physicsBody?.velocity = CGVector(dx: 0, dy: -node.physicsBody!.velocity.dy / d_velocityY);
            node.physicsBody?.applyTorque(torque) })
        let createEffect = SKAction.runBlock({ self.controller.createFallParticle(node) })
        node.runAction(SKAction.group([rotate, SKAction.sequence([impulse, fall, stopGracefully, outOfBoundsCheck, createEffect, floatUpwards])]))
        
    }
    
    // Honestly just winging it. Should've paid more attention in physics :c
    func getTimeToFall() -> NSTimeInterval {
        var adj_scale: CGFloat
        if controller.parentScene.IS_SUPER_HIGH_RES == true && controller.parentScene.IS_IPAD == false { // i6 plus
            adj_scale = 0.95
        }
        else if controller.parentScene._scale == 1.0 {
            adj_scale = 0.9
        }
        else if controller.parentScene.IS_IPHONE_4 == true { //i4
            adj_scale = 0.75
        }
        else if controller.parentScene.IS_SUPER_HIGH_RES == true { // ipad retina
            adj_scale = 0.9
        }
        else if controller.parentScene.IS_IPAD == true {
            adj_scale = 0.7
        }
        else {
            adj_scale = controller.parentScene._scale
        }
        switch y_tier {
        case 0:
            return NSTimeInterval(1.25 * adj_scale)
        case 1:
            return NSTimeInterval(1.35 * adj_scale)
        case 2:
            return NSTimeInterval(1.5 * adj_scale)
        case 3:
            return NSTimeInterval(1.65 * adj_scale)
        default:
            return NSTimeInterval(1.75 * adj_scale)
        }
    }
    
    func outOfBoundsCheck(inout bit: Bit) {
        if bit.position.x < 0 || bit.position.x > controller.parentScene.size.width {
            bit.removeAllActions()
            bit.removeFromParent()
            let index = controller.debrisArray.indexOf(bit)
            controller.debrisArray.removeAtIndex(index!)
        }
    }
    
    func travelAndRotate(path: UIBezierPath, meteorSpeed: NSTimeInterval, angle: CGFloat) {
        let rotateAction = SKAction.rotateByAngle(angle, duration: 25)
        self.runAction(rotateAction)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}