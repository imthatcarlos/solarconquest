//
//  PlanetBase.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 4/11/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit

// As the player makes progress on the planet, the buildings are built
class PlanetBase {
    
    var placementDictionary = [String: CGPoint]()
    
    var dome:SKSpriteNode!
    var lab: SKSpriteNode!
    var hangar: SKSpriteNode!
    var ground_road: SKSpriteNode!
    
    var baseStates: [String: Int]?
    var scale: CGFloat!
    var pointConversion: CGFloat!
    var _offset:CGFloat!
    
    var domeNumber:Int!
    var hangarNumber:Int!
    var labNumber:Int!
    var numberArray:[Int] = []
    
    var parentScene:GameScene!
    var spacemenController: SpacemenController!
    
    init(base_states: [String: Int], scene: GameScene, scale: CGFloat) {
        self.baseStates = base_states
        self.parentScene = scene
        self.scale = scale
        
        if parentScene.IS_IPAD == true {
            pointConversion = 1.0
        }
        else {
            pointConversion = 2.0
        }
        
        readPlacements()
    }
    
    func readPlacements() {
        var fileName:String
        
        if parentScene.IS_IPAD == true {
            fileName = "basePlacements_ipad"
        }
        else {
            fileName = "basePlacements"
        }
        
        if let fileReader = FileReader(path: NSBundle.mainBundle().pathForResource(fileName, ofType: ".txt")!) {
            
            while let line = fileReader.nextLine() {
                if line == "\n" {
                    break
                }
                
                var data = line.componentsSeparatedByString(",")
                let point = CGPointMake(CGFloat(NSNumberFormatter().numberFromString(data[1])!), CGFloat(NSNumberFormatter().numberFromString(data[2])!))
                placementDictionary[data[0]] = point;
            }
            
            fileReader.close()
        }

    }
    
    // Adds all the buildings for the base, as well as the boxes
    func initBase() {
        
        let gameData = GameData.sharedInstance
        
        ground_road = SKSpriteNode(texture: parentScene.atlas.textureNamed("planet_ground"))
        ground_road.name = "ground_road"
        ground_road.userInteractionEnabled = false
        ground_road.anchorPoint = CGPointMake(0.5, 0)
        
        if parentScene._scale == 1.0 {
            _offset = ground_road.size.height * 0.15
        }
        else if parentScene.IS_IPAD == true {
            _offset = ground_road.size.height * 0.22
        }
        else if parentScene.IS_SUPER_HIGH_RES == true {
            _offset = ground_road.size.height * 0.17
        }
        else {
            _offset = ground_road.size.height * 0.12
        }
        
        ground_road.position = CGPointMake(parentScene.frame.midX, _offset)
        
        ground_road.setScale(scale)
        ground_road.zPosition = -1
        parentScene.shakeLayer.addChild(ground_road)
        
        domeNumber = baseStates!["dome"]
        
        if domeNumber != 0 {
            let domeString = "dome-\(domeNumber!)"
            let domeTexture = parentScene.atlas.textureNamed(domeString)
            dome = SKSpriteNode(texture: domeTexture)
            dome.position = getCorrectPosition(placementDictionary["dome-\(domeNumber)"]!)
            dome.name = "dome"
            dome.setScale(scale)
            dome.zPosition = 20
            parentScene.shakeLayer.addChild(dome)
        }
        
        labNumber = baseStates!["lab"]
        
        if labNumber != 0 {
            let labString = "lab-\(labNumber)"
            let labTexture = parentScene.atlas.textureNamed(labString)
            lab = SKSpriteNode(texture: labTexture)
            lab.position = getCorrectPosition(placementDictionary["lab-\(labNumber)"]!)
            lab.name = "lab"
            lab.setScale(scale)
            lab.zPosition = 20
            parentScene.shakeLayer.addChild(lab)
        }
        
        hangarNumber = baseStates!["hangar"]
        if hangarNumber != 0 {
            let hangarString = "hangar" + "-\(hangarNumber!)"
            let hangarTexture = parentScene.atlas.textureNamed(hangarString)
            hangar = SKSpriteNode(texture: hangarTexture)
            hangar.position = getCorrectPosition(placementDictionary["hangar-\(hangarNumber)"]!)
            hangar.name = "hangar"
            hangar.setScale(scale)
            hangar.zPosition = 20
            parentScene.shakeLayer.addChild(hangar)
        }
        
        var boxesArray = [SKSpriteNode]()

        // We know the amount of boxes per planet. Just create an array of all the boxes
        switch gameData.currentPlanet! {
            case "firstPlanet":
                createAndAppend(6, planetName: "firstPlanet", scale: scale, boxesArray: &boxesArray)
            case "secondPlanet":
                createAndAppend(8, planetName: "secondPlanet", scale: scale, boxesArray: &boxesArray)
            case "thirdPlanet":
                createAndAppend(7, planetName: "thirdPlanet", scale: scale, boxesArray: &boxesArray)
            default:
                print("Error")
        }
        
        // Now this guy decides which boxes we actually add on screen
        addBoxesToScreen(&boxesArray)

        numberArray.append(domeNumber)
        numberArray.append(hangarNumber)
        numberArray.append(labNumber)
    }
    
    func createAndAppend(range: Int, planetName: String, scale: CGFloat, inout boxesArray: [SKSpriteNode]) {
        for index in 1...range {
            let name = "box-\(index)_\(planetName)"
            let box = SKSpriteNode(texture: parentScene.atlas.textureNamed(name))
            box.setScale(scale)
            box.position = getCorrectPosition(placementDictionary[name]!)
            box.name = "box"
            box.zPosition = 4
            boxesArray.append(box)
        }
    }
    
    func addBoxesToScreen(inout array: [SKSpriteNode]) {
        array.shuffle()
        var amountToDisplay: Int
        let progress = GameData.sharedInstance.currentProgress!
        
        switch progress {
        case 0...2:
            amountToDisplay = array.count / 6
        case 3...4:
            amountToDisplay = array.count / 4
        case 5...6:
            amountToDisplay = array.count / 3
        case 7...9:
            amountToDisplay = array.count / 2
        default:
            amountToDisplay = array.count - 1
        }
        
        for index in 0...amountToDisplay {
            let node = array[index]
            parentScene.shakeLayer.addChild(node)
        }
    }
    
    // Sets up the spacemen based on what planet this is
    func initSpacemen() {
        spacemenController = SpacemenController(planet: GameData.sharedInstance.currentPlanet!, base: self, scale: scale, progress: GameData.sharedInstance.currentProgress!)
        spacemenController.addSpacemen()
    }
    
    // Return the position the platform should be in
    func getCorrectPosition() -> CGPoint {
        return CGPointMake(parentScene.frame.midX + ground_road.size.width * 0.007, (ground_road.frame.height/2) + (ground_road.size.height * 0.3) + _offset)
    }
    
    func chooseNextBaseUpgrade() -> String {
        var rand:Int!

        // are we fully upgraded?
        if numberArray[0] == 4 && numberArray[1] == 4 && numberArray[2] == 4 {
            return "forceField"
        }
        
        repeat {
            rand = Int(arc4random_uniform(3))
        } while numberArray[rand] == 4
        
        switch rand {
        case 0:
            return "dome"
        case 1:
            return "hangar"
        case 2:
            return "lab"
        default:
            return "forceField"
        }
    }
    
    // Assign the new texture, update the next one to be upgraded, and return the info so the menu can be updated
    func upgradeBase(inout baseStatesDictionary: [String: Int]) -> (String, String) {
        
        var string: String
        let upgraded = GameData.sharedInstance.nextBaseUpgrade!
        
        switch upgraded {
        case "dome":
            string = "dome-\((++numberArray[0]))"
            dome?.removeFromParent()
            dome = SKSpriteNode(texture: parentScene.atlas.textureNamed(string))
            dome.position = getCorrectPosition(placementDictionary[string]!)
            dome.name = "dome"
            dome.setScale(scale)
            dome.zPosition = 20
            parentScene.shakeLayer.addChild(dome)
            
            baseStatesDictionary.updateValue((numberArray[0]), forKey: "dome")
            break
        case "hangar":
            string = "hangar-\(++(numberArray[1]))"
            hangar?.removeFromParent()
            hangar = SKSpriteNode(texture: parentScene.atlas.textureNamed(string))
            hangar.position = getCorrectPosition(placementDictionary[string]!)
            hangar.name = "hangar"
            hangar.setScale(scale)
            hangar.zPosition = 20
            parentScene.shakeLayer.addChild(hangar)
            baseStatesDictionary.updateValue((numberArray[1]), forKey: "hangar")
            break
        case "lab":
            string = "lab-\((++numberArray[2]))"
            lab?.removeFromParent()
            lab = SKSpriteNode(texture: parentScene.atlas.textureNamed(string))
            lab.position = getCorrectPosition(placementDictionary[string]!)
            lab.name = "lab"
            lab.setScale(scale)
            lab.zPosition = 20
            parentScene.shakeLayer.addChild(lab)
            baseStatesDictionary.updateValue((numberArray[2]), forKey: "lab")
            break
        default: // forcefield
            parentScene.showEndGame()
            return ("done", "done")
        }
        
        GameData.sharedInstance.nextBaseUpgrade! = chooseNextBaseUpgrade()
        GameData.sharedInstance.currentProgress!++
        
        return (upgraded, GameData.sharedInstance.nextBaseUpgrade!)
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
            adj_scale = scale
        }
        
        let adjustedPosition = positionScale(position, scale: adj_scale)
        return CGPointMake(adjustedPosition.x / pointConversion, adjustedPosition.y / pointConversion)
    }
}