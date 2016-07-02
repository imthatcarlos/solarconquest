//
//  Weapon.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 3/30/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

// An extension of the CGPoint to cover some Vector math
internal extension CGPoint {
    
    // Get the length (a.k.a. magnitude) of the vector
    var length: CGFloat { return sqrt(self.x * self.x + self.y * self.y) }
    
    // Normalize the vector (preserve its direction, but change its magnitude to 1)
    var normalized: CGPoint { return CGPoint(x: self.x / self.length, y: self.y / self.length) }
}

// Vector * scalar
internal func vectorMultiply(point: CGPoint, factor: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * factor, y:point.y * factor)
}

// Vector + vector
internal func vectorAdd(point: CGPoint, point2: CGPoint) -> CGPoint {
    return CGPoint(x: point.x + point2.x, y:point.y + point2.y)
}

// Vector - Vector
internal func vectorSubtract(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

// The angle between two vectors
internal func angleBetweenVector(v1:CGPoint, v2:CGPoint)->CGFloat {
    let cosAngle = (v1.x * v2.x + v1.y * v2.y) / (v1.length * v2.length)
    return acos(cosAngle)
}

// Weapon is the object that spawns projectiles to shoot at the meteors passing by. There
// are 4 categories of weapons, which will be subclasses of this class (MachineGun, Laser, 
// ExplodingCrossbow, and Missile) The main difference between all of these is the type of 
// projectile they spawn.
// All weapons include a subtle crosshair in their texture
// @param level describes the level of the gun, which reflects the amount of damage it does
// @param category is the subclass of weapon this belongs to, for easy storing
// @param weaponName is the name of the weapon, for easy storing and display
class Weapon: SKSpriteNode {
    
    var level: Int!
    var sublevel: Int!
    var weaponName: String!
    var parentScene: GameScene!
    
    var currentVector: CGPoint!
    var currentTouchLocation: CGPoint!
    var levelDamage: Double!
    var sublevelDamage: Double!
    var scale: CGFloat!
    var coolDown:NSTimeInterval!
    var canShoot:Bool = true
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init(texture: SKTexture!, color: UIColor!, size: CGSize, name: String, level: Int, sublevel: Int, parentScene: GameScene) {
        self.init(texture: texture, color: color, size: size)
        self.weaponName = name
        self.level = level
        self.sublevel = sublevel
        self.parentScene = parentScene
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Spawns a projectile. This function will be different for each gun category
    func shoot(touchLocation: CGPoint, vector: CGPoint) {
    }
    
    // Rotate to face direction of tap
    func rotateToFaceTouch(vector: CGPoint) {
        let dy = vector.y
        let dx = vector.x
        let angle_degrees = atan2f(Float(dy), Float(dx))
        self.zRotation = CGFloat(angle_degrees - Float(M_PI_2))
    }
    
    // The weapon data should've been notified, but the weapon on-screen needs to be updated as well
    func upgrade() {
        self.sublevel!++
        if sublevel == 3 {
            sublevel == 0
            self.level!++
        }
    }
    
    // Refresh the information since we just upgraded
    func refreshDamageInfo() {
        let data = GameData.sharedInstance.weaponInventory![weaponName]!
        self.level = data.level
        self.sublevel = data.sublevel
    }
    
    // Return the damage that the weapon should deal per projectile
    func getDamage() -> Double {
        return (self.levelDamage * Double(self.level)) + (self.sublevelDamage * Double(self.sublevel))
    }
    
    // Anything special that the weapon has to do when the player stops touching/holding
    func stopShooting() {
        self.removeActionForKey("shooting")
        
        if self.actionForKey("coolDown") == nil {
            self.runAction(SKAction.sequence([SKAction.waitForDuration(self.coolDown), SKAction.runBlock({ self.canShoot = true })]), withKey: "coolDown")
        }
    }
}