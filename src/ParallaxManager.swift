//
//  ParallaxManager.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 7/6/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

class ParallaxManager {
    
    var emitter: SKEmitterNode!
    var secondEmitter:SKEmitterNode?
    var thirdEmitter:SKEmitterNode?
    var runAction:SKAction?
    
    var parentScene: GameScene!
    var currentPlanet: String!
    
    init(currentPlanet: String, parent: GameScene) {
        parentScene = parent
        self.currentPlanet = currentPlanet
        switch currentPlanet {
        case "secondPlanet":
            setupSecondPlanet()
        case "thirdPlanet":
            setupThirdPlanet()
        default:
            break
        }
    }
    
    func beginParallaxEffect() {
        if currentPlanet == "firstPlanet" { return }
        
        parentScene.addChild(emitter)
        
        if currentPlanet == "secondPlanet" {
            parentScene.addChild(secondEmitter!)
            parentScene.addChild(thirdEmitter!)
            secondEmitter!.advanceSimulationTime(15)
            parentScene.runAction(SKAction.repeatActionForever(runAction!), withKey: "parallax")
        }
        
    }

    private func setupSecondPlanet() {
        emitter = SKEmitterNode(fileNamed: "emitter_secondPlanet")
        emitter.position = CGPointMake(-parentScene.frame.width/4, parentScene.frame.height * 0.9)
        emitter.zPosition = -4
        
        secondEmitter = SKEmitterNode(fileNamed: "emitter_secondPlanet")
        secondEmitter!.particleTexture = SKTexture(imageNamed: "cloud3_secondPlanet")
        secondEmitter!.position = CGPointMake(-parentScene.frame.width/4, parentScene.frame.height * 0.7)
        
        thirdEmitter = SKEmitterNode(fileNamed: "emitter_secondPlanet")
        thirdEmitter!.particleTexture = SKTexture(imageNamed: "cloud1_secondPlanet")
        thirdEmitter!.position = CGPointMake(-parentScene.frame.width/4, parentScene.frame.height * 0.8)
        thirdEmitter!.particlePositionRange = CGVectorMake(0, 300)
        thirdEmitter!.particleBirthRate = 1
        thirdEmitter!.numParticlesToEmit = 0
        thirdEmitter?.particleAlpha = 0.4
        
        runAction = SKAction.sequence([SKAction.runBlock({ self.emitter.resetSimulation()}),
                                        SKAction.waitForDuration(5),
                                        SKAction.runBlock({ self.secondEmitter!.resetSimulation()}),
                                            SKAction.waitForDuration(15)])
        
        if parentScene.IS_IPAD == true {
            emitter.particleScale *= 2
            emitter.particleLifetime *= 3
            emitter.particlePositionRange = CGVectorMake(0, emitter.particlePositionRange.dy * 2)
            secondEmitter?.particleLifetime *= 3
            secondEmitter?.particleScale *= 2
            secondEmitter?.particlePositionRange = CGVectorMake(0, emitter.particlePositionRange.dy * 2)
            thirdEmitter?.particleLifetime *= 3
            thirdEmitter?.particleScale *= 2
            thirdEmitter?.particlePositionRange = CGVectorMake(0, emitter.particlePositionRange.dy * 2)
        }
    }
    
    private func setupThirdPlanet() {
        emitter = SKEmitterNode(fileNamed: "emitter_thirdPlanet")
        emitter.position = CGPointMake(parentScene.frame.minX, parentScene.frame.minY)
        emitter.zPosition = -4
        
        if parentScene.IS_IPAD == true {
            emitter.particleLifetime *= 3
            emitter.particleAlphaSpeed = -0.2
            emitter.particleScaleSpeed = -0.4
            emitter.particleScale *= 2
            emitter.particlePositionRange = CGVectorMake(emitter.particlePositionRange.dx * 2, 0)
        }
    }

}