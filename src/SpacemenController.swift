//
//  SpacemenController.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 4/26/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

extension Array {
    mutating func shuffle() {
        for i in 0..<(count - 1) {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else { continue }
            swap(&self[i], &self[j])
        }
    }
}

class SpacemenController {

    private struct Spaceman {
        var state: Int              // IDLE | DIG | WELD | WRENCH
        var position: CGPoint       //
        var scale: CGFloat          //
        var xScale: CGFloat         //
        var animationDelay: NSTimeInterval
        var zposition: CGFloat

    }
    
    var planet: String!
    var extraSpacemen: Int!
    var base: PlanetBase!
    var scale: CGFloat!
    var pointConversion: CGFloat!
    var spacemenFrames = [String: [SKTexture]]()
    
    let reversed:CGFloat = -1
    let not_reversed: CGFloat = 1
    
    private var currentSpacemen = [SKSpriteNode]()
    
    init(planet: String, base: PlanetBase, scale: CGFloat, progress: Int) {
        self.planet = planet
        self.base = base
        self.scale = scale
        
        switch progress {
        case 0...2:
            extraSpacemen = 2
        case 3...5:
            extraSpacemen = 4
        case 6...8:
            extraSpacemen = 6
        default:
            extraSpacemen = 8
        }
        
        let digAtlas = SKTextureAtlas(named: "spaceman-1.atlas")
        let idleAtlas = SKTextureAtlas(named: "spaceman-0.atlas")
        let weldAtlas = SKTextureAtlas(named: "spaceman-2.atlas")
        let wrenchAtlas = SKTextureAtlas(named: "spaceman-3.atlas")
        let walkAtlas = SKTextureAtlas(named: "spaceman-4.atlas")
        let waveAtlas = SKTextureAtlas(named: "spaceman-5.atlas")
        
        // Initialize all the texture frames that we'll need to animate the spacemen
        for index in 0...5 {
            var atlas:SKTextureAtlas
            var title:String
            switch index {
            case 0:
                title = "idle-"
                atlas = idleAtlas
            case 1:
                title = "digging-"
                atlas = digAtlas
            case 2:
                title = "welding-"
                atlas = weldAtlas
            case 3:
                title = "wrench-"
                atlas = wrenchAtlas
            case 4:
                title = "walk-"
                atlas = walkAtlas
            default:
                title = "wave-"
                atlas = waveAtlas
            }
            
            var framesArray: [SKTexture] = []
            for index in 0...(atlas.textureNames.count)-1 {
                let string = title + "\(index+1)"
                
                framesArray.append(atlas.textureNamed(string))
            }
            
            let key = "spaceman-\(index)"
            spacemenFrames[key] = framesArray
        }
        
        // Convert pixels to points, but since we are using @2x textures for ipad, gotta do something different
        if base.parentScene.IS_IPAD == true {
            pointConversion = 1.0
        }
        else {
            pointConversion = 2.0
        }
    }
    
    func addSpacemen() {
        
        var spacemen = [Spaceman]()
        
        var flipped: Int
        var x_scale: CGFloat = 1
        var delay: NSTimeInterval = 0
        var zposition: CGFloat = 24
        
        // the first 5 are always the same
        for index in 1...5 {
            flipped = Int(arc4random_uniform(2))
            let position = base.placementDictionary["spaceman-\(index)_\(planet)"]!
            let correctPosition = getCorrectPosition(position)
            
            if index == 1 || index == 2 {   // These are the two guys at the end being idle
                if flipped == 0 {
                    x_scale = reversed
                }
                else {
                    x_scale = not_reversed
                }
                
                zposition = 22
                
                let spaceman = Spaceman(state: 0, position: correctPosition, scale: scale, xScale: x_scale, animationDelay: delay, zposition: zposition)
                spacemen.append(spaceman)
                continue
            }
            else if index == 3 {            // These are the workers
                x_scale = not_reversed
                zposition = 30
                delay = 0.5
            }
            else if index == 4 {
                x_scale = reversed
            }
            else if index == 5 {
                x_scale = reversed
                delay = 0.2
            }
            
            let spaceman = Spaceman(state: 2, position: correctPosition, scale: scale, xScale: x_scale, animationDelay: delay, zposition: zposition)
            spacemen.append(spaceman)
        }
        
        getOtherSpacemen(&spacemen)
        
        putOnScreen(&spacemen)
    }
    
    private func putOnScreen(inout spacemen: [Spaceman]) {
        let amount = Int(arc4random_uniform(UInt32(spacemen.count - 8))) + extraSpacemen
        var randCount: Int
        spacemen.shuffle()
        
        for index in 0...amount {
            
            let spaceman = spacemen[index]
            let type = "spaceman-\(spaceman.state)"
            var node = SKSpriteNode(texture: spacemenFrames[type]![0])
            node.name = type
            node.position = spaceman.position
            node.setScale(spaceman.scale + 0.1) // they're a little too small
            node.zPosition = spaceman.zposition
            
            base.parentScene.shakeLayer.addChild(node)
            currentSpacemen.append(node)
            
            node.xScale *= spaceman.xScale
            
            if spaceman.state == 0 {
                randCount = Int(arc4random_uniform(10)) + 5
                runWalkSequence(&node, spaceman: spaceman, randCount: randCount, xscale: spaceman.xScale)
                continue
            }
            
            let animate = SKAction.animateWithTextures(spacemenFrames[type]!, timePerFrame: 0.2, resize: false, restore: false)
            let animateAndWait = SKAction.sequence([animate, animate.reversedAction(), SKAction.waitForDuration(spaceman.animationDelay)])
            node.runAction(SKAction.repeatActionForever(animateAndWait))
        }
    }
    
    private func getOtherSpacemen(inout array: [Spaceman]) {
        var range: Int
        
        switch planet {
        case "firstPlanet":
            range = 11
            if base.parentScene.IS_IPAD == true {
                range += 3
            }
        case "secondPlanet":
            range = 13
        case "thirdPlanet":
            range = 12
            if base.parentScene.IS_IPAD == true {
                range -= 1
            }
        default:
            return
        }
        
        var dig_or_idle: Int
        var flipped: Int
        var adj_scale: CGFloat
        var x_scale: CGFloat
        let zposition: CGFloat = 25
        
        for index in 6...range - 1 {
            dig_or_idle = Int(arc4random_uniform(2))
            flipped = Int(arc4random_uniform(2))
            let position = base.placementDictionary["spaceman-\(index)_\(planet)"]!
            let correctPosition = getCorrectPosition(position)
            
            if correctPosition.y > base.ground_road.frame.maxY {
                adj_scale = scale - 0.1
            }
            else {
                adj_scale = scale
            }
            
            if flipped == 0 {
                x_scale = reversed
            }
            else {
                x_scale = not_reversed
            }
            
            let spaceman = Spaceman(state: dig_or_idle, position: correctPosition, scale: adj_scale, xScale: x_scale, animationDelay: 0.0, zposition: zposition)
            array.append(spaceman)
        }
    }
    
    // The spaceman has a chance at knowing how to walk
    // Make the spaceman be idle for a bit, walk somewhere, be idle, walk back
    private func runWalkSequence(inout node: SKSpriteNode, spaceman: Spaceman, randCount: Int, xscale: CGFloat) {
        let type = "spaceman-\(spaceman.state)"
        let rand = arc4random_uniform(2)
        let turn = SKAction.runBlock({ node.xScale *= -1 })
        let beIdle = SKAction.animateWithTextures(spacemenFrames[type]!, timePerFrame: 0.2, resize: false, restore: false)
        let turnAndBeIdle = SKAction.group([turn, SKAction.animateWithTextures(spacemenFrames[type]!, timePerFrame: 0.2, resize: false, restore: false)])
        let beIdleLonger = SKAction.repeatAction(beIdle, count: randCount)
        let walkAnimation = SKAction.animateWithTextures(spacemenFrames["spaceman-4"]!, timePerFrame: 0.1, resize: false, restore: true)
        var entireSequence: SKAction
        
        if rand == 1 {
            if xscale == not_reversed {
                let walk = SKAction.moveToX(node.position.x + 5, duration: 0.8)
                let walkGroup = SKAction.group([walk, walkAnimation])
                let walkBack = SKAction.moveToX(node.position.x - 5, duration: 0.8)
                let walkBackGroup = SKAction.group([turn, walkBack, walkAnimation])
                entireSequence = SKAction.sequence([beIdleLonger, walkGroup, beIdleLonger, walkBackGroup, beIdleLonger, turnAndBeIdle])
            }
            else {
                let walk = SKAction.moveToX(node.position.x - 5, duration: 0.8)
                let walkGroup = SKAction.group([walk, walkAnimation])
                let walkBack = SKAction.moveToX(node.position.x + 5, duration: 0.8)
                let walkBackGroup = SKAction.group([turn, walkBack, walkAnimation])
                entireSequence = SKAction.sequence([beIdleLonger, walkGroup, beIdleLonger, walkBackGroup, beIdleLonger, turnAndBeIdle])
            }
        }
        else {
            let animateAndWait = SKAction.sequence([beIdle, SKAction.waitForDuration(spaceman.animationDelay)])
            entireSequence = animateAndWait
        }
        
        node.runAction(SKAction.repeatActionForever(entireSequence))
    }
    
    func makeAllWave() {
        for spaceman in currentSpacemen {
            spaceman.removeAllActions()
            spaceman.runAction(SKAction.repeatActionForever(SKAction.animateWithTextures(spacemenFrames["spaceman-5"]!, timePerFrame: 0.1, resize: true, restore: false)))
        }
    }
    
    private func positionScale(position: CGPoint, scale: CGFloat) -> CGPoint {
        return CGPointMake(position.x * scale, position.y * scale)
    }
    
    func getCorrectPosition(position: CGPoint) -> CGPoint {
        var adj_scale: CGFloat
        
        // for the ipad
        if pointConversion == 1.0 {
            adj_scale = 1.0
        }
        else {
            adj_scale = base.scale
        }
        
        let adjustedPosition = positionScale(position, scale: adj_scale)
        return CGPointMake(adjustedPosition.x / pointConversion, adjustedPosition.y / pointConversion)
    }
}