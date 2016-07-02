//
//  MeteorShower.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 3/27/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

// MeteorShower takes care of the process of spawning Meteors, removing them if or if they 
// explode, runnning waves of meteors, and waiting for a period of time before beginning
// the next wave
// @param GameData.sharedInstance.currentProgress tells the class what kinds of waves to spawn and how much
//        health each meteor should have (an int range from 0 - 100)
// @param parentScene is the scene which this class belongs to
// @param previousWaitTime is there to ensure there's no repeat
// @param breakCount is there to give the player a break after... 5 waves
class MeteorShower {
    
    static var bitDictionary = ["plain": Bit(imageNamed: "bit-plain"),
                                "lilac": Bit(imageNamed: "bit-lilac"),
                                "silver": Bit(imageNamed: "bit-silver"),
                                "gold": Bit(imageNamed: "bit-gold")]
     
    // MARK: Properties
    var controller: SKNode!
    var parentScene: GameScene!
    var previousWaitTime: NSTimeInterval = 0
    var boostCounter: Int = 0
    var breakCount = Int()
    var _scale:CGFloat!
    var is_iphone_4:Bool!
    var currentMeteorYTier:Int!
    var queuedCurrencyShowers: Int = 0
    
    var meteorTextures = [String: SKTexture]()
    var tailEmitter: SKEmitterNode!
    
    var missileExplosionFrames = [SKTexture]()
    var explosionNode: SKSpriteNode!
    
    // All particle effects
    var smokeEmitter: SKEmitterNode!
    var sparkEmitter: SKEmitterNode!
    var boltEmitter: SKEmitterNode!
    var explosionEmitter: SKEmitterNode!
    var explosionEmitter2: SKEmitterNode!
    var particleExplosion:SKEmitterNode!
    
    var collectParticle: SKEmitterNode!
    
    var fallParticle: SKEmitterNode!
    
    var whoseTurnIsIt_fall = 0
    var whoseTurnIsIt_collect = 0
    
    var debrisArray = [SKSpriteNode]()
    var particleTextures = [String: SKTexture]()
    
    // MARK: Functions
    
    init(parentScene: GameScene, scale: CGFloat, is_i4: Bool, meteorAtlasToUse: String) {
        self.parentScene = parentScene
        self._scale = scale
        self.is_iphone_4 = is_i4
        self.currentMeteorYTier = -1
        self.queuedCurrencyShowers = 0
        
        // See if this can run al of our actions, instead of the parent scene
        controller = SKNode()
        parentScene.addChild(controller)
        
        // Preload all particle effects
        preLoadAllParticles()
        
        // Preload all the meteor textures
        let meteorAtlas = SKTextureAtlas(named: meteorAtlasToUse)
        for textureName in meteorAtlas.textureNames {
            var name = textureName 
            name = substring(name, delim: "@")
            meteorTextures[name] = meteorAtlas.textureNamed(name)
        }
        
        // Create explosion animation for missile launcher
        var explosionAtlas: SKTextureAtlas
        if parentScene.meteorAtlasToUse == "atlas_meteors@2x" {
            explosionAtlas = SKTextureAtlas(named: "explosion@2x")
        }
        else {
            explosionAtlas = SKTextureAtlas(named: "explosion@3x")
        }
        
        for index in 1...explosionAtlas.textureNames.count {
            let name = "explosion-\(index)"
            missileExplosionFrames.append(explosionAtlas.textureNamed(name))
        }
        
        explosionNode = SKSpriteNode(texture: missileExplosionFrames.first! as SKTexture)
        explosionNode.setScale(scale + 0.5)
        explosionNode.zPosition = 15
    }
    
    // Begins a wave of asteroids
    // Chooses a health for all the meteors in this wave
    // Chooses the amount of sequences of meteors spawns to occur
    //
    // Chooses the rate at which the meteors waves begin
    // Makes a call to waitForNextWave once the wave ends
    func beginWave() {
        
        if queuedCurrencyShowers != 0 {
            // this random should only happen if we could not start this shower earlier, or if this
            // was rewarded at launch time
            self.beginCurrencyShower("random")
            return
        }
        
        let health = chooseHealth()
        let amountOfSequences = chooseAmount()
        let rate = chooseRateofSpawn()
        
        let spawnAction = chooseTypeOfSpawn(health, amount: amountOfSequences);
        
        let waitAction = SKAction.waitForDuration(rate)
        let actionSequence = SKAction.repeatAction(SKAction.sequence([spawnAction, waitAction]), count: amountOfSequences)
        
        controller.runAction(actionSequence, completion: { self.waitForNextWave() })
    }
    
    // Waits for a certain amount of time before the next wave can begin
    func waitForNextWave() {
        let waitTime = chooseWaitTime()
        let waitAction = SKAction.waitForDuration(waitTime)
        
        controller.runAction(waitAction, completion: { self.beginWave() })
    }
    
    // Stops the current wave and begins the currency shower triggered by nativex
    func beginCurrencyShower(currency: String) {
        
        // If there's one going on already, back out
        if controller.actionForKey("currencyWave") != nil {
            return
        }
        
        queuedCurrencyShowers -= 1
        controller.removeAllActions()
        
        let health = chooseHealth() - 5
        var currencyToUse: String
        
        if currency != "random" {
            currencyToUse = currency
        }
        else {
            currencyToUse = chooseCurrency()
        }
        
        let spawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 2, currency: currencyToUse)} )
        let spawn2 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 2, currency: currencyToUse)} )
        let spawn3 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 2, currency: currencyToUse)} )
        let spawn4 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 2, currency: currencyToUse)} )
        let spawn5 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 2, currency: currencyToUse)} )
        let spawn6 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 2, currency: currencyToUse)} )
        let wait = SKAction.waitForDuration(3.0)
        let spawnActions = SKAction.sequence([ spawn, wait, spawn2, wait, spawn3, wait, spawn4, wait, spawn5, wait, spawn6 ])
        let currencyWave = SKAction.sequence([spawnActions, SKAction.waitForDuration(5.0)])
        let waitForNextWave = SKAction.runBlock({ self.waitForNextWave() })
        
        controller.runAction(SKAction.sequence([currencyWave, waitForNextWave]), withKey: "currencyWave")
    }
    
    // Creates a Meteor object
    // The meteor runs an action which is to move across the screen, and then remove itself
    // Each meteor's health is determined by the player's GameData.sharedInstance.currentProgress
    // Each meteor spawned has a chance at being a normal, silver, gold, or lilac
    func spawnMeteor(health: Double, yPosition: Int, boost:Bool = false, currency: String = "random") {
                
        let node = SKNode()
        
        var currencyString:String
        
        if currency != "random" {
            currencyString = currency
        }
        else {
            currencyString = chooseCurrency()
        }
        
        if boost == true {
            switch boostCounter {
            case 0:
                boostCounter++
                currencyString = "lilac"
                break
            case 1:
                boostCounter++
                currencyString = "silver"
                break
            default:
                boostCounter = 0
                currencyString = "gold"
                break
            }
        }
        
        let textureString = chooseTexture(currencyString)
        
        let meteorTexture = meteorTextures[textureString]!
        let meteor = Meteor(texture: meteorTexture, color: UIColor.clearColor(), size: meteorTexture.size(), health: health, currencyType: currencyString, pN: node, controller: self)
        meteor.name = "meteor"
        meteor.setScale(_scale)
        meteor.zPosition = 6
        if parentScene.IS_IPAD == true {
            meteor.physicsBody = SKPhysicsBody(circleOfRadius: (meteorTexture.size().width * 3.5) * 0.25)
        }
        else if parentScene._scale == 1.0 {
            meteor.physicsBody = SKPhysicsBody(circleOfRadius: meteorTexture.size().width * 0.45)
        }
        else if parentScene.IS_SUPER_HIGH_RES {
            meteor.physicsBody = SKPhysicsBody(circleOfRadius: meteorTexture.size().width * 0.6)
        }
        else {
            meteor.physicsBody = SKPhysicsBody(circleOfRadius: meteorTexture.size().width * 0.3)
        }
        
        meteor.physicsBody?.categoryBitMask = ColliderType.Meteor.rawValue
        meteor.physicsBody?.contactTestBitMask = ColliderType.Projectile.rawValue | ColliderType.Explosion.rawValue
        meteor.physicsBody?.collisionBitMask = 0
        meteor.physicsBody?.affectedByGravity = false
        meteor.physicsBody?.allowsRotation = true
        
        // Path to follow
        var y: CGFloat
        if yPosition == -1 {
            y = chooseYPosition(is_iphone_4, picker: -1)
        }
        else {
            y = chooseYPosition(is_iphone_4, picker: yPosition)
        }
        
        meteor.y_tier = currentMeteorYTier
        
        let beginPosition = CGPointMake(self.parentScene.frame.maxX + meteor.size.width, y)
        let endPosition = CGPointMake(parentScene.frame.minX - meteor.size.width*2, y)
        let controlPoint = CGPointMake(parentScene.frame.midX, y + 60)
        let path = UIBezierPath()
        path.moveToPoint(beginPosition)
        path.addQuadCurveToPoint(endPosition, controlPoint: controlPoint)
        path.moveToPoint(beginPosition)
        
        let meteorSpeed = chooseSpeed()
        
        node.position = beginPosition
        
        // Only do the following to set the color of the particle for rail gun
        if parentScene.equippedWeapon.weaponName == "rail_gun" {
            setBoltColor(getBoltColor())
        }
        
        // fire tail emitter
        let emitterNode = tailEmitter.copy() as! SKEmitterNode
        emitterNode.particlePosition = CGPointMake(meteor.size.width/2, 0)

        node.addChild(emitterNode)
        node.addChild(meteor)
        
        meteor.travelAndRotate(path, meteorSpeed: meteorSpeed, angle: chooseAngleToRotate())
        controller.addChild(node)
        let pathToTravelAction = SKAction.followPath(path.CGPath, asOffset: false, orientToPath: false, duration: meteorSpeed)
        node.runAction(pathToTravelAction, completion: { node.removeFromParent() })
    }
    
    // Removes any "burning" actions from meteors for the laser
    func removeAllBurning() {
        for contact in parentScene.currentContacts {
            var meteor:Meteor?
            
            if contact.bodyA.categoryBitMask == ColliderType.Projectile.rawValue {
                meteor = contact.bodyB.node as? Meteor
            }
            else {
                meteor = contact.bodyA.node as? Meteor
            }
            if meteor?.burning == true {
                meteor?.removeBurn()
                meteor?.removeActionForKey("takingDamage")
            }
        }
        
        parentScene.currentContacts.removeAll(keepCapacity: false)
    }
    
    // Sets the color of the bolt for the rail gun
    func getBoltColor() -> UIColor {
        switch parentScene.equippedWeapon.level {
        case 1:
            return UIColor.cyanColor()
        case 2:
            return UIColor.greenColor()
        default:
            return UIColor.yellowColor()
        }
    }
    
    func collectDebris() {
        for var index = debrisArray.count - 1; index >= 0; --index {
            var node = debrisArray.removeAtIndex(index) as! Bit
            moveToCorrespondingCurrency(&node, playerTriggered: false)
        }
    }
    
    func moveToCorrespondingCurrency(inout node: Bit, playerTriggered: Bool = true, effectDelay: NSTimeInterval = 0.0) {
        
        // so it's not processed twice because of the pan gesture recognizer
        if node.tagged == false {
            node.tagged = true
        }
        else {
            return
        }
        
        // CollectDebris() calls this function, and it removes for us
        if playerTriggered {
            let index = debrisArray.indexOf(node)
            debrisArray.removeAtIndex(index!)
        }
        
        var positionToTravelTo: CGPoint
        
        switch node.name! {
        case "lilac":
            positionToTravelTo = parentScene.convertPoint(parentScene.currencyNode.childNodeWithName("lilac-icon")!.position, fromNode: parentScene.currencyNode)
        case "silver":
            positionToTravelTo = parentScene.convertPoint(parentScene.currencyNode.childNodeWithName("silver-icon")!.position, fromNode: parentScene.currencyNode)
        case "gold":
            positionToTravelTo = parentScene.convertPoint(parentScene.currencyNode.childNodeWithName("gold-icon")!.position, fromNode: parentScene.currencyNode)
        default:
            node.runAction(SKAction.sequence([SKAction.scaleTo(0.2, duration: 0.5), SKAction.removeFromParent()]))
            return
        }
       
        // adjust the position since their anchor point is 0,1
        let iconSize = (parentScene.currencyNode.childNodeWithName("lilac-icon") as! SKSpriteNode).size
        positionToTravelTo = CGPointMake(positionToTravelTo.x + iconSize.width/2, positionToTravelTo.y - iconSize.height/2)
        
        let travelAction = SKAction.moveTo(positionToTravelTo, duration: 0.4)
        
        // pretty particle effect
        if playerTriggered == true {
            parentScene.runAction(SKAction.sequence([SKAction.waitForDuration(effectDelay), SKAction.runBlock({ self.createCollectParticle(node)})]))
        }
        
        // the amount they are awarded per bit
        let amount = Int(arc4random_uniform(3)) + 2
        
        node.runAction(SKAction.sequence([travelAction, SKAction.removeFromParent()]), completion: { self.parentScene.updateCurrency(node.name!, value: amount, animate: true) })
    }
    
    func createFallParticle(bit: Bit) {
        
        if whoseTurnIsIt_fall == 0 {
            whoseTurnIsIt_fall++
            let particle = fallParticle.copy() as! SKEmitterNode
            particle.particlePosition = CGPointMake(bit.position.x, bit.position.y)
            self.parentScene.addChild(particle)
            particle.resetSimulation()
            controller.runAction(SKAction.sequence([SKAction.waitForDuration(2.0), SKAction.runBlock({particle.removeFromParent()})]))
        }
        else if whoseTurnIsIt_fall == 1{
            whoseTurnIsIt_fall++
            let particle = fallParticle.copy() as! SKEmitterNode
            particle.particlePosition = CGPointMake(bit.position.x, bit.position.y)
            self.parentScene.addChild(particle)
            particle.resetSimulation()
            controller.runAction(SKAction.sequence([SKAction.waitForDuration(2.0), SKAction.runBlock({particle.removeFromParent()})]))
        }
        else {
            whoseTurnIsIt_fall = 0
            let particle = fallParticle.copy() as! SKEmitterNode
            particle.particlePosition = CGPointMake(bit.position.x, bit.position.y)
            self.parentScene.addChild(particle)
            particle.resetSimulation()
            controller.runAction(SKAction.sequence([SKAction.waitForDuration(2.0), SKAction.runBlock({particle.removeFromParent()})]))
            
        }
    }
    
    func createCollectParticle(bit: Bit) {
        
        switch whoseTurnIsIt_collect {
        case 0:
            whoseTurnIsIt_collect++
            let particle = collectParticle.copy() as! SKEmitterNode
            particle.particlePosition = bit.position
            self.parentScene.addChild(particle)
            particle.resetSimulation()
            controller.runAction(SKAction.sequence([SKAction.waitForDuration(2.0), SKAction.runBlock({particle.removeFromParent()})]))
            
            if AudioManager.sharedInstance.sounds["bit_collect_1"]!.playing == false {
                AudioManager.sharedInstance.playSound("bit_collect_1")
            }
            
            break
        case 1:
            whoseTurnIsIt_collect++
            let particle = collectParticle.copy() as! SKEmitterNode
            particle.particlePosition = bit.position
            self.parentScene.addChild(particle)
            particle.resetSimulation()
            controller.runAction(SKAction.sequence([SKAction.waitForDuration(2.0), SKAction.runBlock({particle.removeFromParent()})]))
            
            if AudioManager.sharedInstance.sounds["bit_collect_2"]!.playing == false {
                AudioManager.sharedInstance.playSound("bit_collect_2")
            }
            
            break
        case 2:
            whoseTurnIsIt_collect++
            let particle = collectParticle.copy() as! SKEmitterNode
            particle.particlePosition = bit.position
            self.parentScene.addChild(particle)
            particle.resetSimulation()
            controller.runAction(SKAction.sequence([SKAction.waitForDuration(2.0), SKAction.runBlock({particle.removeFromParent()})]))
            
            if AudioManager.sharedInstance.sounds["bit_collect_3"]!.playing == false {
                AudioManager.sharedInstance.playSound("bit_collect_3")
            }
            
            break
        case 3:
            whoseTurnIsIt_collect++
            let particle = collectParticle.copy() as! SKEmitterNode
            particle.particlePosition = bit.position
            self.parentScene.addChild(particle)
            particle.resetSimulation()
            controller.runAction(SKAction.sequence([SKAction.waitForDuration(2.0), SKAction.runBlock({particle.removeFromParent()})]))
            
            if AudioManager.sharedInstance.sounds["bit_collect_4"]!.playing == false {
                AudioManager.sharedInstance.playSound("bit_collect_4")
            }
            
            break
        default:
            whoseTurnIsIt_collect = 0
            let particle = collectParticle.copy() as! SKEmitterNode
            particle.particlePosition = bit.position
            self.parentScene.addChild(particle)
            particle.resetSimulation()
            controller.runAction(SKAction.sequence([SKAction.waitForDuration(2.0), SKAction.runBlock({particle.removeFromParent()})]))
            
            if AudioManager.sharedInstance.sounds["bit_collect_5"]!.playing == false {
                AudioManager.sharedInstance.playSound("bit_collect_5")
            }
            
            break
        }
    }
    
    func setBoltColor(color: UIColor) {
        boltEmitter.particleColor = color
        boltEmitter.particleColorSequence = nil
    }
    
    func preLoadAllParticles() {
        // Effects for when a projectile collides with the meteor
        
        let smokeEmitterPath:NSString = NSBundle.mainBundle().pathForResource("Smoke", ofType: "sks")!
        smokeEmitter = NSKeyedUnarchiver.unarchiveObjectWithFile(smokeEmitterPath as String) as! SKEmitterNode
        smokeEmitter.particleZPosition = 50
        
        let sparkEmitterPath: NSString = NSBundle.mainBundle().pathForResource("Spark", ofType: "sks")!
        sparkEmitter = NSKeyedUnarchiver.unarchiveObjectWithFile(sparkEmitterPath as String) as! SKEmitterNode
        sparkEmitter.particleZPosition = 50
        
        let boltEmitterPath: NSString = NSBundle.mainBundle().pathForResource("ElectricBolt", ofType: "sks")!
        boltEmitter = NSKeyedUnarchiver.unarchiveObjectWithFile(boltEmitterPath as String) as! SKEmitterNode
        boltEmitter.particleZPosition = 50
        
        let explosionEmitterPath:NSString = NSBundle.mainBundle().pathForResource("Smoke_explosion", ofType: "sks")!
        explosionEmitter = NSKeyedUnarchiver.unarchiveObjectWithFile(explosionEmitterPath as String) as! SKEmitterNode
        explosionEmitter.particleZPosition = 50
        
        explosionEmitter2 = NSKeyedUnarchiver.unarchiveObjectWithFile(explosionEmitterPath as String) as! SKEmitterNode
        explosionEmitter2.emissionAngle = 180
        explosionEmitter2.particleZPosition = 50
        
        particleExplosion = SKEmitterNode(fileNamed: "Particle_explosion")
        particleExplosion.particleZPosition = 55
        
        // For the particle explosion
        particleTextures["lilac"] = parentScene.gameMenu.textures["lilac-icon"]!
        particleTextures["silver"] = parentScene.gameMenu.textures["silver-icon"]!
        particleTextures["gold"] = parentScene.gameMenu.textures["gold-icon"]!
        
        // Particle effect for when a meteor bit is collected
        collectParticle = SKEmitterNode(fileNamed: "bit_collect.sks")
        collectParticle.targetNode = parentScene
        collectParticle.particleZPosition = 35
                
        // Particles effect for when a meteor bit hits the forcefield
        fallParticle = SKEmitterNode(fileNamed: "bit_fall.sks")
        fallParticle.targetNode = parentScene
        fallParticle.particleZPosition = 35
        
        // Fire tail particle
        let emitterPath:NSString = NSBundle.mainBundle().pathForResource("Meteor_tail", ofType: "sks")!
        tailEmitter = NSKeyedUnarchiver.unarchiveObjectWithFile(emitterPath as String) as! SKEmitterNode
        tailEmitter.name = "tail"
        
        // adjust particle scales for ipad
        if parentScene.IS_IPAD == true {
            smokeEmitter.particleScale *= 2
            sparkEmitter.particleScale *= 2
            boltEmitter.particleScale *= 2
            tailEmitter.particleScale *= 1.85
            fallParticle.particleScale *= 1.85
            explosionEmitter.particleScale *= 1.5
            explosionEmitter2.particleScale *= 1.5
            particleExplosion.particleScale *= 1.5
            collectParticle.particleScale *= 1.85
        }
        else if parentScene.IS_SUPER_HIGH_RES == true {
            smokeEmitter.particleScale *= 1.5
            sparkEmitter.particleScale *= 1.5
            boltEmitter.particleScale *= 1.5
            tailEmitter.particleScale *= 1.45
            fallParticle.particleScale *= 1.45
            explosionEmitter.particleScale *= 1.1
            explosionEmitter2.particleScale *= 1.1
            particleExplosion.particleScale *= 1.1
            collectParticle.particleScale *= 1.45
        }
        
        // If it's an i6
        if parentScene._scale == 1.0 {
            tailEmitter.particleScale *= 1.4
        }
        
        smokeEmitter.targetNode = parentScene
        sparkEmitter.targetNode = parentScene
        explosionEmitter.targetNode = parentScene
        explosionEmitter2.targetNode = parentScene
        particleExplosion.targetNode = parentScene
        boltEmitter.targetNode = parentScene
        
        smokeEmitter.advanceSimulationTime(3.0)
        sparkEmitter.advanceSimulationTime(3.0)
        boltEmitter.advanceSimulationTime(3.0)
//        explosionEmitter.advanceSimulationTime(3.0)
//        explosionEmitter2.advanceSimulationTime(3.0)
//        particleExplosion.advanceSimulationTime(3.0)
        
        parentScene.addChild(smokeEmitter)
        parentScene.addChild(sparkEmitter)
        parentScene.addChild(boltEmitter)
//        parentScene.addChild(explosionEmitter)
//        parentScene.addChild(explosionEmitter2)
//        parentScene.addChild(particleExplosion)
    }
    
    // MARK: -
    
    // Returns a string describing the kind of currency this meteor drops
    // Chances:
    // Gold: 1/11
    // Silver: 2/11
    // Lilac: 3/11
    // None: 5/11
    func chooseCurrency() -> String {
        let currencyPicker = Int(arc4random_uniform(11))
        
        switch currencyPicker {
        case 0...4:
            return "plain"
        case 5...7:
            return "lilac"
        case 8...9:
            return "silver"
        case 10:
            return "gold"
        default:
            return "plain"
        }
    }
    
    func chooseSpeed() -> NSTimeInterval {
        var number:UInt32
        switch GameData.sharedInstance.currentProgress! {
        case 0...3:
            number = arc4random_uniform(6) + 10
        case 4...7:
            number = arc4random_uniform(4) + 10
        default:
            number = arc4random_uniform(3) + 8
        }
        return NSTimeInterval(number)
    }
    
    func chooseTypeOfSpawn(health: Double, amount: Int) -> SKAction {
        var action:SKAction
        switch GameData.sharedInstance.currentProgress! {
        case 0...2:
            action = earlyProgressSpawn(health, amount: amount)
            return action
        case 3...5:
            action = mediumProgressSpawn(health, amount: amount)
            return action
        case 6...8:
            action = highProgressSpawn(health, amount: amount)
            return action
        default:
            action = advancedProgressSpawn(health, amount: amount)
        }
        
        return action
    }
    
    // Returns an SKAction with a unique pattern of meteor spawns
    func earlyProgressSpawn(health: Double, amount: Int) -> SKAction {
        var number:Int
        if amount == 2 {
            number = 4
        }
        else {
            number = Int(arc4random_uniform(4))
        }
        
        var action:SKAction
        
        switch number {
        case 0:
            action = SKAction.runBlock({ self.spawnMeteor(health, yPosition: -1) })
            break
        case 1:
            let firstSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let wait = SKAction.waitForDuration(5)
            let secondSpawn = SKAction.runBlock({ self.spawnMeteor(health, yPosition: -1) })
            action = SKAction.sequence([firstSpawn, wait, secondSpawn ])
            break
        case 2:
            let firstSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let wait = SKAction.waitForDuration(3)
            let secondSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            action = SKAction.sequence([firstSpawn, wait, secondSpawn])
            break
        case 3:
            let firstSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let wait1 = SKAction.waitForDuration(3)
            let secondSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let wait2 = SKAction.waitForDuration(5)
            let thirdSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            action = SKAction.sequence([firstSpawn, wait1, secondSpawn, wait2, thirdSpawn])
            break
        default:
            let firstSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1, boost: true)} )
            let secondSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1, boost: true)} )
            let thirdSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1, boost: true)} )
            let fourthSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1, boost: true)} )
            let fifthSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1, boost: true)} )
            let wait = SKAction.waitForDuration(4)
            
            action = SKAction.sequence([firstSpawn, wait, secondSpawn, wait, thirdSpawn, wait, fourthSpawn, wait, firstSpawn, wait, fifthSpawn])
            break
        }
        
        return action
    }
    
    // Returns an SKAction with a unique pattern of meteor spawns
    func mediumProgressSpawn(health: Double, amount: Int) -> SKAction {
        var number:Int
        if amount == 2 {
            number = 4
        }
        else {
            number = Int(arc4random_uniform(4))
        }
        
        var action:SKAction
        
        switch number {
        case 0:
            action = SKAction.runBlock({ self.spawnMeteor(health, yPosition: -1) })
            break
        case 1:
            let firstSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let wait = SKAction.waitForDuration(2)
            let secondSpawn = SKAction.runBlock({ self.spawnMeteor(health, yPosition: -1) })
            action = SKAction.sequence([firstSpawn, wait, secondSpawn ])
            break
        case 2:
            let firstSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let wait = SKAction.waitForDuration(4)
            let secondSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            action = SKAction.sequence([firstSpawn, wait, secondSpawn, wait, firstSpawn, secondSpawn, wait, firstSpawn, secondSpawn])
            break
        case 3:
            let firstSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let wait1 = SKAction.waitForDuration(2)
            let secondSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let wait2 = SKAction.waitForDuration(4)
            let thirdSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            action = SKAction.sequence([firstSpawn, wait1, secondSpawn, wait2, thirdSpawn, wait1, wait2, firstSpawn, secondSpawn, wait1, thirdSpawn])
            break
        default:
            let firstSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1, boost: true)} )
            let secondSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1, boost: true)} )
            let thirdSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1, boost: true)} )
            let fourthSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1, boost: true)} )
            let fifthSpawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1, boost: true)} )
            let wait = SKAction.waitForDuration(2.5)
            
            action = SKAction.sequence([firstSpawn, wait, secondSpawn, wait, thirdSpawn, wait, fourthSpawn, wait, firstSpawn, wait, fifthSpawn])
            break
        }
        
        return action
    }
    
    // Returns an SKAction with a unique pattern of meteor spawns
    func highProgressSpawn(health: Double, amount: Int) -> SKAction {
        var number:Int
        if amount == 2 {
            number = 5
        }
        else {
            number = Int(arc4random_uniform(6))
        }
        
        var action:SKAction
        
        switch number {
        case 0:
            action = SKAction.runBlock({ self.spawnMeteor(health, yPosition: -1) })
            break
        case 1:
            let spawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 0)} )
            let spawn2 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 0)} )
            let spawn3 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 0)} )
            let spawn4 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 0)} )
            let wait = SKAction.waitForDuration(2)
            action = SKAction.sequence([spawn, wait, spawn2, wait, spawn3, spawn4 ])
            break
        case 2:
            let spawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let spawn2 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let spawn3 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let spawn4 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let wait = SKAction.waitForDuration(3)
            let small_delay = SKAction.waitForDuration(2)
            action = SKAction.sequence([spawn, small_delay, spawn3, wait, spawn4, small_delay, spawn, small_delay, spawn2, wait, spawn3, wait, spawn4])
            break
        case 3:
            let spawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let spawn2 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let spawn3 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let spawn4 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let wait = SKAction.waitForDuration(3)
            let small_delay = SKAction.waitForDuration(2)
            action = SKAction.sequence([spawn, wait, spawn2, wait, spawn4, wait, spawn2, spawn3, small_delay, spawn4])
            break
        case 4:
            action = createLineSpawn(health)
            break
        case 5:
            let spawn = SKAction.runBlock( {self.spawnMeteor(30, yPosition: 4, boost: true)} )
            let spawn2 = SKAction.runBlock( {self.spawnMeteor(30, yPosition: 4, boost: true)} )
            let spawn3 = SKAction.runBlock( {self.spawnMeteor(30, yPosition: 4, boost: true)} )
            let spawn4 = SKAction.runBlock( {self.spawnMeteor(30, yPosition: 4, boost: true)} )
            let wait = SKAction.waitForDuration(2)
            action = SKAction.sequence([spawn, wait, spawn2, wait, spawn3, wait, spawn4, wait, spawn, wait, spawn2])
            break
        default:
            let spawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1, boost: true)} )
            let spawn2 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1, boost: true)} )
            let spawn3 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1, boost: true)} )
            let spawn4 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1, boost: true)} )
            let wait = SKAction.waitForDuration(2)
            action = SKAction.sequence([spawn, wait, spawn2, wait, spawn3, wait, spawn4, wait, spawn, wait, spawn2])
            break
        }
        return action
    }
    
    // Returns an SKAction with a unique pattern of meteor spawns
    func advancedProgressSpawn(health: Double, amount: Int) -> SKAction {
        var number:Int
        if amount == 2 {
            number = 5
        }
        else {
            number = Int(arc4random_uniform(5))
        }
        
        var action:SKAction
        
        switch number {
        case 0:
            action = SKAction.runBlock({ self.spawnMeteor(health, yPosition: -1) })
            break
        case 1:
            let spawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 0)} )
            let spawn2 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 0)} )
            let spawn3 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 3)} )
            let spawn4 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 0)} )
            let spawn5 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 0)} )
            let spawn6 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 2)} )
            let wait = SKAction.waitForDuration(2)
            action = SKAction.sequence([ spawn, wait, spawn2, wait, spawn3, wait, spawn4, spawn5, wait, spawn6 ])
            break
        case 2:
            let spawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let spawn2 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let spawn3 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let spawn4 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1)} )
            let wait = SKAction.waitForDuration(2)
            action = SKAction.sequence([spawn, wait, spawn3, wait, spawn4, wait, spawn, wait, spawn2, wait, spawn3, wait, spawn4])
            break
        case 3:
            let spawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 0)} )
            let spawn2 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 2)} )
            let spawn3 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: 4)} )
            let wait = SKAction.waitForDuration(4)
            action = SKAction.sequence([spawn, spawn2, spawn3, wait, spawn, spawn2, spawn3, wait, spawn, spawn2, spawn3])
            break
        case 4:
            action = createLineSpawn(health)
        default:
            let spawn = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1, boost: true)} )
            let spawn2 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1, boost: true)} )
            let spawn3 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1, boost: true)} )
            let spawn4 = SKAction.runBlock( {self.spawnMeteor(health, yPosition: -1, boost: true)} )
            let wait = SKAction.waitForDuration(2.0)
            
            action = SKAction.sequence([spawn, wait, spawn2, wait, spawn3, wait, spawn4, wait, spawn, wait, spawn2])
            break
        }
        return action
        
    }
    
    func createLineSpawn(health: Double) -> SKAction {
        
        let spawn1 = SKAction.runBlock({self.spawnMeteor(health, yPosition: 0)})
        let spawn2 = SKAction.runBlock({self.spawnMeteor(health, yPosition: 1)})
        let spawn3 = SKAction.runBlock({self.spawnMeteor(health, yPosition: 2)})
        let spawn4 = SKAction.runBlock({self.spawnMeteor(health, yPosition: 3)})
        let spawn5 = SKAction.runBlock({self.spawnMeteor(health, yPosition: 4)})
        
        let spawnGroup = SKAction.group([spawn1, spawn2, spawn3, spawn4, spawn5])
        return spawnGroup
        
    }
    
    // Returns an Int describing how much health this meteor should have
    func chooseHealth() -> Double {
        var health: Double
        let lucky = arc4random_uniform(7)
        
        switch GameData.sharedInstance.currentProgress! {
        case 0...3:
            health = 20
            break
        case 4:
            health = 25
            break
        case 5...6:
            health = 30
            break
        case 7:
            health = 35
            break
        case 8:
            health = 45
            break
        case 9:
            health = 50
            break
        case 10...11:
            health = 55
            break
        default:
            health = 55
        }
        
        // Give the player a break
        if lucky == 4 {
            health -= 10
        }
        
        return health
    }
    
    // Returns a String describing the texture to use for a meteor
    // Format : asteroidTexture_currencyName-someNumber(1-6)
    func chooseTexture(currencyString: String) -> String{
        let number = arc4random_uniform(6) + 1
        let textureString = "meteor_" + currencyString + "-" + String(number)
        return textureString
    }
    
    // Returns an Int describing how many sequences of meteors should spawn this wave
    // Chances:
    // 2: 1/6
    // 7: 1/6
    // 3: 2/6
    // 5: 2/6
    func chooseAmount() -> Int {
        let amountPicker = Int(arc4random_uniform(6))
        switch amountPicker {
        case 0:
            return 1
        case 1...2:
            return 2
        case 3...4:
            return 3
        default:
            return 4
        }
    }
    
    // Returns an NSTimeInterval describing the rate at which the meteors should spawn
    // Either 4, 5 or 6 sec... for now
    func chooseRateofSpawn() -> NSTimeInterval {
        let rate = Int(arc4random_uniform(3)) + 4
        return NSTimeInterval(rate)
    }
    
    // Returns an NSTimeInterval describing the amount of time to wait before beginning
    // the next wave of meteors
    // Give the player a longer break after 5 waves
    func chooseWaitTime() -> NSTimeInterval {
        let wait = Int(arc4random_uniform(7))
        switch wait {
        case 0:
            if previousWaitTime != 15.0 {
                previousWaitTime = 15.0
                return 15.0
            }
            else {
                previousWaitTime = 10.0
                return 10.0
            }
        case 1...2:
            if (previousWaitTime != 5.0) {
                previousWaitTime = 5.0
                return 5.0
            } else {
                previousWaitTime = 10.0
                return 10.0
            }
        default:
            previousWaitTime = 10.0
            return 10.0
        }
    }
    
    // Returns some random angle for the meteor to rotate by between -115 and 115
    func chooseAngleToRotate() -> CGFloat {
        let someAngle = Double(arc4random_uniform(30)) + 180.0
        let radians = someAngle / 180.0 * M_PI
        return CGFloat(radians)
    }
    
    // Returns one of 4-5 CGFloats to assign as the Y position of a meteor
    func chooseYPosition(iphone_4: Bool, picker: Int) -> CGFloat {
        var i: Int
        
        if picker == -1 {
            i = Int(arc4random_uniform(5))
        }
        else {
            i = picker
        }
        let baseY = parentScene.frame.height * 0.55
        let frameHeight = parentScene.frame.size.height
        
        switch i {
        case 0:
            if iphone_4 {
                currentMeteorYTier = 0
                return baseY
            }
            else {
                currentMeteorYTier = 4
                return baseY + (frameHeight * 0.3)
            }
        case 1:
            currentMeteorYTier = 3
            return baseY + (frameHeight * 0.23)
        case 2:
            currentMeteorYTier = 2
            return baseY + (frameHeight * 0.16)
        case 3:
            currentMeteorYTier = 1
            return baseY + (frameHeight * 0.09)
        default:
            currentMeteorYTier = 0
            return baseY
        }
    }
}