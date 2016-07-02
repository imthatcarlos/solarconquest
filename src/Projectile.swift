//
//  Projectile.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 4/11/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

class Projectile: SKSpriteNode {
    
    enum ProjectileType: UInt32 {
        case Missile = 0x01
        case Beam = 0x02
        case Bullet = 0x04
        case Elec = 0x08
        case Explosion = 0x16
    }
    
    var damage:Double!
    var type: UInt32!
    var isReady: Bool! // for now, for railgun projectiles
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        self.isReady = false
    }
    
    convenience init(texture: SKTexture!, color: UIColor!, size: CGSize, damage: Double, type: UInt32) {
        self.init(texture: texture, color: color, size: size)
        self.damage = damage
        self.type = type
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Rotate to face direction of tap
    func rotateToFaceTouch(vector: CGPoint) {
        let dy = vector.y
        let dx = vector.x
        let angle_degrees = atan2f(Float(dy), Float(dx))
        self.zRotation = CGFloat(angle_degrees - Float(M_PI_2))
    }
}