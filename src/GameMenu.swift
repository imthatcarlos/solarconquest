//
//  WeaponMenu.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 5/13/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit
import Social

struct Placement {
    var name: String
    var position: CGPoint
    var parentNode: String
}

internal func substring(original: String, delim: Character) -> String{
    let start = original.startIndex
    let end = original.characters.indexOf(delim)?.predecessor()
    let name = original[start...end!]
    return name
}

enum MenuState:UInt32 {
    case WeaponMenu = 0x01
    case BaseMenu = 0x02
    case SettingsMenu = 0x04
    case PrestigeMenu = 0x08
}

// Once this object is initialized, all the menus have the proper children, all we need is the signal
// from the GameScene to make the group of children in each menu visible
class GameMenu: SKSpriteNode {
    
    // Constant sizes for nodes (on i6)
    // Scale as needed
    let menuSize = CGSizeMake(631, 850)
    let weaponNodeSize = CGSizeMake(437, 108)
    let settingNodeSize = CGSizeMake(432, 105)
    let menu_bgSize = CGSizeMake(525, 657)
    let currencyNodeSize = CGSizeMake(515, 79)
    
    var MEDAL_NAV_POSITION:CGFloat!
    
    var menuButton: SKSpriteNode!
    
    var parentScene: GameScene!
    var scale: CGFloat!
    var pointConversion: CGFloat!
    var state: MenuState.RawValue!
    var placementGroups = [String: [String:Placement]]()        // for all unique placements
    var placementNodeGroups = [String: [String:Placement]]()    // for placements to be used by other placements
    var spriteGroups = [String: [String: SKSpriteNode]]()       // for all the sprite nodes we could possible need
    var currentMenuSprites = [String: [String: SKSpriteNode]]() // for sprite nodes actually needed in base/medals menu
    var equippedPlate: SKSpriteNode!
    var bgNode: SKSpriteNode!
    var weaponsMenu_currencyNum: BitMapFontLabel!
    var previousSelectedWeapon: String!
    var textures = [String: SKTexture]()
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init(_scale: CGFloat, size: CGSize, parentScene: GameScene, atlasToUse: String) {
        self.init(texture: nil, color: UIColor.clearColor(), size: size)
        
        let bgColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        bgNode = SKSpriteNode(color: bgColor, size: size)
        bgNode.anchorPoint = CGPointMake(0, 0)
        bgNode.alpha = 0
        bgNode.zPosition = 40
        
        self.parentScene = parentScene
        
        // Preload all textures
        let atlas = SKTextureAtlas(named: atlasToUse)
        for textureName in atlas.textureNames {
            var name = textureName 
            name = substring(name, delim: "@")
            textures[name] = atlas.textureNamed(name)
        }
        
        // IPad menus use same scale as iphone6
        if parentScene.IS_IPAD == true {
            scale = 1.65
            pointConversion = 1.0
        }
        else {
            scale = _scale
            pointConversion = 2.0
        }
        
        loadPlacements()
        prepareItems()
        createMenu()
        menuButton = spriteGroups["menuPlacements"]!["menuButton"]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Read all placements
    private func loadPlacements() {
        // The ipad menu isn't scaled, but positioned differently
        if parentScene.IS_IPAD == true {
            readPlacements("menuPlacements_ipad")
        }
        else {
            readPlacements("menuPlacements")
        }
        readPlacements("weaponMenuPlacements")
        readPlacements("baseMenuPlacements")
        readPlacements("settingsMenuPlacements")
        readPlacements("prestigeMenuPlacements")
        readPlacements("settingsSliderPlacements")
        readPlacements("weaponNodePlacements")
        readPlacements("currencyNodePlacements")
    }
    
    // Read the file given, and store the placement in our dictionary
    // Items MUST be anchored at the top, left
    // format: parentNode
    //         groupName
    //         itemName, x, y
    private func readPlacements(file: String) {
        if let fileReader = FileReader(path: NSBundle.mainBundle().pathForResource(file, ofType: ".txt")!) {
            let parentNode = fileReader.nextLine()
            let groupName = fileReader.nextLine()
            
            while let line = fileReader.nextLine() {
                if line == "\n" {
                    break
                }
                
                var data = line.componentsSeparatedByString(",")
                let point = CGPointMake(CGFloat(NSNumberFormatter().numberFromString(data[1])!), CGFloat(NSNumberFormatter().numberFromString(data[2])!))
                
                if groupName!.hasSuffix("-Node") {
                    if placementNodeGroups[groupName!] == nil {
                        placementNodeGroups[groupName!] = [String: Placement]()
                        placementNodeGroups[groupName!]![data[0]] = (Placement(name: data[0], position: point, parentNode: parentNode!))
                    }
                    else {
                        placementNodeGroups[groupName!]![data[0]] = (Placement(name: data[0], position: point, parentNode: parentNode!))
                    }
                }
                else {
                    if placementGroups[groupName!] == nil {
                        placementGroups[groupName!] = [String: Placement]()
                        placementGroups[groupName!]![data[0]] = (Placement(name: data[0], position: point, parentNode: parentNode!))
                    }
                    else {
                        placementGroups[groupName!]![data[0]] = (Placement(name: data[0], position: point, parentNode: parentNode!))
                    }
                }
            }
            
            fileReader.close()
        }
    }
    
    // We are processing one group at a time.... and one placement at a time
    private func prepareItems() {
        for (groupName, placements) in placementGroups {
            
            spriteGroups[groupName] = [String:SKSpriteNode]()
            
            for (placementName, placement) in placements {
                
                // Process the nodes differently, they must read placement info from the proper nodeGroup
                // It could be laser.Weapon, ..., sfx.Setting, soundNode.Setting
                if placementName.hasSuffix("-Node") {
                    
                    let nodeName = substring(placementName, delim: "-")
                    prepareNode(nodeName)
                    
                }
                else {
                    let spriteNode: SKSpriteNode = SKSpriteNode(texture: textures[placementName])
                    spriteNode.name = placementName
                    spriteNode.anchorPoint = CGPointMake(0, 1)
                    spriteNode.position =  getCorrectPosition(placement)
                    
                    // Only the big menu stuff should be scaled - if it's not an ipad menu
                    if groupName == "menuPlacements" && parentScene.IS_IPAD == true {
                        spriteNode.setScale(2.0)
                    }
                    else if parentScene.IS_IPAD == true && placement.parentNode == "menu_bg"{
                        spriteNode.setScale(1.0)
                    }
                    else if parentScene.IS_IPAD == true {
                        spriteNode.setScale(1.65)
                    }
                    else if groupName == "menuPlacements" {
                        spriteNode.setScale(scale)
                    }
                    
                    spriteGroups[groupName]![placementName] = spriteNode
                }
            }
            
        }
    }

    
    // Prepare either the weapon node or the setting node
    private func prepareNode(nodeName: String) {
        if nodeName.hasSuffix(".Weapon") {
            let weaponName = substring(nodeName, delim: ".")
            prepareWeapon(weaponName)
        }
        else if nodeName.hasSuffix(".Setting"){
            let settingName = substring(nodeName, delim: ".")
            prepareSetting(settingName)
        }
        else {
            prepareCurrencyNode()
        }
    }
    
    // Create a node with all the proper information, and add to sprite groups
    private func prepareWeapon(name: String) {
        
        // Create the node needed for other placements, and name it
        var weaponNode = WeaponMenuNode(texture: nil, color: UIColor.clearColor(), size: CGSizeMake(weaponNodeSize.width * scale, weaponNodeSize.height * scale))
        weaponNode.name = name
        weaponNode.anchorPoint = CGPointMake(0, 1)
        weaponNode.position = getCorrectPosition(placementGroups["weaponsMenu"]![name + ".Weapon-Node"]!)
        
        addWeaponNodeChildren(&weaponNode)
        
        spriteGroups["weaponsMenu"]![name] = weaponNode
    }
    
    private func addWeaponNodeChildren(inout weaponNode: WeaponMenuNode) {
        let weaponData = GameData.sharedInstance.weaponInventory![weaponNode.name!]!
        var icon: SKSpriteNode
        var levelLabel: SKSpriteNode
        var levelFrame: SKSpriteNode
        var upgradeButton: SKSpriteNode
        var unlockButton: SKSpriteNode
        
        if weaponData.unlocked! == true {
            
            // Icon
            icon = SKSpriteNode(texture: textures[weaponNode.name! + "-icon"])
            icon.name = "icon"
            icon.anchorPoint = CGPointMake(0, 1)
            icon.position = getCorrectPosition(placementNodeGroups["weapon-Node"]!["icon"]!)
            icon.zPosition = 5
            weaponNode.addChild(icon)
            
            // Lvl label
            levelLabel = SKSpriteNode(texture: textures["lvlLabel"])
            levelLabel.anchorPoint = CGPointMake(0, 1)
            levelLabel.position = getCorrectPosition(placementNodeGroups["weapon-Node"]!["lvlLabel"]!)
            levelLabel.zPosition = 5
            weaponNode.addChild(levelLabel)
            
            // Level frame
            levelFrame = SKSpriteNode(texture: textures["weaponLevelFrame"])
            levelFrame.anchorPoint = CGPointMake(0, 1)
            levelFrame.position = getCorrectPosition(placementNodeGroups["weapon-Node"]!["w_levelFrame"]!)
            levelFrame.zPosition = 5
            weaponNode.addChild(levelFrame)
            
            createLevelFills(&weaponNode)
            
            // UpgradeButton
            upgradeButton = SKSpriteNode(texture: textures["weaponUpgradeButton"])
            upgradeButton.name = "upgradeButton"
            upgradeButton.anchorPoint = CGPointMake(0, 1)
            upgradeButton.position = getCorrectPosition(placementNodeGroups["weapon-Node"]!["weaponUpgradeButton"]!)
            upgradeButton.zPosition = 5
            weaponNode.addChild(upgradeButton)
            
            // upgrade label
            let upgradeLabel = SKSpriteNode(imageNamed: "upgrade_label")
            upgradeLabel.name = "upgrade_label"
            upgradeLabel.userInteractionEnabled = false
            upgradeLabel.position = CGPointMake(upgradeButton.size.width/2, -upgradeButton.size.height/2)
            upgradeButton.addChild(upgradeLabel)
            
            // If it's fully upgraded, the button should be hidden
            if weaponData.level == 3 && weaponData.sublevel == 3 {
                upgradeButton.hidden = true
            }
            
            // If this is the weapon currently equipped, create and add the equipped plate.. NO! ADD LATER!
            // Also, allow touches
            if weaponNode.name! == GameData.sharedInstance.equippedWeaponName! {
                equippedPlate = SKSpriteNode(texture: textures["weapon_equipped"])
                equippedPlate.name = "weapon_equipped"
                equippedPlate.anchorPoint = CGPointMake(0, 1)
                equippedPlate.position = getCorrectPosition(placementNodeGroups["weapon-Node"]!["weapon_equipped"]!)
                
                spriteGroups["weaponsMenu"]!["currentlyEquipped"] = equippedPlate
                previousSelectedWeapon = name
                weaponNode.wasSelected = true
                
            }
            else {
                changeNodeAlpha(&weaponNode, value: 0.6)
            }
        }
        else {
            
            // Icon
            icon = SKSpriteNode(texture: textures["locked-icon"])
            icon.name = "locked-icon"
            icon.anchorPoint = CGPointMake(0, 1)
            icon.position = getCorrectPosition(placementNodeGroups["weapon-Node"]!["icon"]!)
            icon.zPosition = 5
            weaponNode.addChild(icon)
            
            // Unlock button
            unlockButton = SKSpriteNode(texture: textures["weaponUnlockButton"])
            unlockButton.name = "unlockButton"
            unlockButton.anchorPoint = CGPointMake(0, 1)
            unlockButton.position = getCorrectPosition(placementNodeGroups["weapon-Node"]!["weaponUnlockButton"]!)
            unlockButton.zPosition = 5
            weaponNode.addChild(unlockButton)
            
            // Label
            let unlockLabel = SKSpriteNode(imageNamed: "unlock_label")
            unlockLabel.name == "unlock_label"
            unlockLabel.userInteractionEnabled = false
            unlockLabel.position = CGPointMake(unlockButton.size.width/2, -unlockButton.size.height/2)
            unlockButton.addChild(unlockLabel)
            
            changeNodeAlpha(&weaponNode, value: 0.6)
        }
    }
    
    private func createLevelFills(inout weaponNode: WeaponMenuNode) {
        
        // Clear out any old ones
        weaponNode.childNodeWithName("fill-0")?.removeFromParent()
        weaponNode.childNodeWithName("fill-1")?.removeFromParent()
        weaponNode.childNodeWithName("fill-2")?.removeFromParent()
        
        // Level fill
        let levelFill = SKSpriteNode(texture: textures["weaponLevelFill"])
        levelFill.anchorPoint = CGPointMake(0, 1)
        levelFill.position = getCorrectPosition(placementNodeGroups["weapon-Node"]!["w_levelFill"]!)
        levelFill.zPosition = 5
        
        // Place a levelFill for each sublevel of the weapon
        for var i = 0 ; i < GameData.sharedInstance.weaponInventory![weaponNode.name!]!.sublevel; ++i {
            let copyFill = levelFill.copy() as! SKSpriteNode
            copyFill.name = "fill-\(i)"
            let newX = CGFloat((copyFill.size.width * 1.52) * CGFloat(i))
            copyFill.position.x += newX
            
            /*var levelColor: UIColor
            switch data.weaponInventory![weaponNode.name!]!.level {
            case 1:
                levelColor = UIColor(red: 0.905, green: 0, blue: 0.552, alpha: 1.0)
            case 2:
                levelColor = UIColor.blueColor()
            default:
                levelColor = UIColor.yellowColor()
            }
            
            copyFill.color = levelColor
            copyFill.colorBlendFactor = 1*/
            
            weaponNode.addChild(copyFill)
        }
    }
    
    private func prepareSetting(name: String) {
        
        // Setting node
        let node = SettingMenuNode(texture: nil, color: UIColor.clearColor(), size: settingNodeSize, parentScene: parentScene)
        node.anchorPoint = CGPointMake(0, 1)
        node.position = getCorrectPosition(placementGroups["settingsMenu"]![name + ".Setting-Node"]!)
        node.userInteractionEnabled = true
        node.name = name
        
        // slider
        let slider_back = SKSpriteNode(texture: textures["slider_back"])
        slider_back.anchorPoint = CGPointMake(0, 1)
        slider_back.position = getCorrectPosition(placementNodeGroups["setting-Node"]!["slider_back"]!)
        node.addChild(slider_back)
        node.slider_back = slider_back
        
        // icon
        let iconName = "\(name)-icon"
        let icon = SKSpriteNode(texture: textures[iconName])
        icon.anchorPoint = CGPointMake(0, 1)
        icon.position = getCorrectPosition(placementNodeGroups["setting-Node"]!["icon"]!)
        node.addChild(icon)
        node.icon = icon
        
        // slider thumb
        let slider_thumb = SKSpriteNode(texture: textures["slider"])
        slider_thumb.anchorPoint = CGPointMake(0, 1)
        slider_thumb.position = getCorrectPosition(placementNodeGroups["setting-Node"]!["slider"]!)
        slider_thumb.name == "slider"
        slider_thumb.zPosition = 5
        node.addChild(slider_thumb)
        node.slider = slider_thumb
        
        node.setSlider(slider_back.position.x, maxX: slider_back.position.x + slider_back.size.width * (3/4))
        
        if currentMenuSprites["settingsMenu"] == nil {
            currentMenuSprites["settingsMenu"] = [String: SKSpriteNode]()
        }
        
        spriteGroups["settingsMenu"]![name] = node
    }
    
    func prepareCurrencyNode() {
        
        // node
        let currencyNode = SKSpriteNode(texture: nil, color: UIColor.clearColor(), size: CGSizeMake(currencyNodeSize.width, currencyNodeSize.height))
        currencyNode.anchorPoint = CGPointMake(0, 1)
        currencyNode.position = getCorrectPosition(placementGroups["menuPlacements"]!["currency-Node"]!)
        currencyNode.zPosition = 100
        
        // bg
        let bg = SKSpriteNode(texture: textures["currency-bg"])
        bg.anchorPoint = CGPointMake(0, 1)
        bg.position = getCorrectPosition(placementNodeGroups["currency-Node"]!["currency-bg"]!)
        
        if parentScene.IS_IPAD == true {
            bg.setScale(2.0)
        }
        else {
            bg.setScale(scale)
        }
        
        currencyNode.addChild(bg)
        
        // lilac 
        let lilacIcon = SKSpriteNode(texture: textures["lilac-icon"])
        lilacIcon.name = "lilac-icon"
        lilacIcon.anchorPoint = CGPointMake(0, 1)
        lilacIcon.position = getCorrectPosition(placementNodeGroups["currency-Node"]!["lilac-icon"]!)
        lilacIcon.setScale(scale)
        lilacIcon.zPosition = 5
        currencyNode.addChild(lilacIcon)
        
        let lilacNum = GameData.sharedInstance.currency!["lilac"]!
        let lilacAmount = BitMapFontLabel(text: "\(lilacNum)", fontName: "number_", usingAtlas: "atlas_fonts.atlas")
        lilacAmount.name = "lilac"
        lilacAmount.position = getCorrectPosition(placementNodeGroups["currency-Node"]!["lilac-num"]!)
        lilacAmount.setScale(scale)
        currencyNode.addChild(lilacAmount)
        
        // silver
        let silverIcon = SKSpriteNode(texture: textures["silver-icon"])
        silverIcon.name = "silver-icon"
        silverIcon.anchorPoint = CGPointMake(0, 1)
        silverIcon.position = getCorrectPosition(placementNodeGroups["currency-Node"]!["silver-icon"]!)
        silverIcon.setScale(scale)
        silverIcon.zPosition = 5
        currencyNode.addChild(silverIcon)
        
        let silverNum = GameData.sharedInstance.currency!["silver"]!
        let silverAmount = BitMapFontLabel(text: "\(silverNum)", fontName: "number_", usingAtlas: "atlas_fonts.atlas")
        silverAmount.name = "silver"
        silverAmount.position = getCorrectPosition(placementNodeGroups["currency-Node"]!["silver-num"]!)
        silverAmount.setScale(scale)
        currencyNode.addChild(silverAmount)
        
        // gold
        let goldIcon = SKSpriteNode(texture: textures["gold-icon"])
        goldIcon.name = "gold-icon"
        goldIcon.anchorPoint = CGPointMake(0, 1)
        goldIcon.position = getCorrectPosition(placementNodeGroups["currency-Node"]!["gold-icon"]!)
        goldIcon.setScale(scale)
        goldIcon.zPosition = 5
        currencyNode.addChild(goldIcon)
        
        let goldNum = GameData.sharedInstance.currency!["gold"]!
        let goldAmount = BitMapFontLabel(text: "\(goldNum)", fontName: "number_", usingAtlas: "atlas_fonts.atlas")
        goldAmount.name = "gold"
        goldAmount.position = getCorrectPosition(placementNodeGroups["currency-Node"]!["gold-num"]!)
        goldAmount.setScale(scale)
        currencyNode.addChild(goldAmount)
        
        spriteGroups["menuPlacements"]!["currency-Node"] = currencyNode
        
        // Particle Effects
        let lilacParticles = SKEmitterNode(fileNamed: "CurrencyUp")
        lilacParticles!.name = "lilacParticles"
        lilacParticles!.particleColor = UIColor(red: 0.905, green: 0, blue: 0.552, alpha: 1.0)
        lilacParticles!.particleColorSequence = nil
        lilacParticles!.position = CGPointMake(lilacIcon.frame.midX, lilacIcon.frame.midY)
        lilacParticles!.advanceSimulationTime(3.0)
        currencyNode.addChild(lilacParticles!)
        
        let silverParticles = SKEmitterNode(fileNamed: "CurrencyUp")
        silverParticles!.name = "silverParticles"
        silverParticles!.position = CGPointMake(silverIcon.frame.midX, silverIcon.frame.midY)
        silverParticles!.particleColor = UIColor.blueColor()
        silverParticles!.particleColorSequence = nil
        silverParticles!.advanceSimulationTime(3.0)
        currencyNode.addChild(silverParticles!)
        
        let goldParticles = SKEmitterNode(fileNamed: "CurrencyUp")
        goldParticles!.name = "goldParticles"
        goldParticles!.position = CGPointMake(goldIcon.frame.midX, goldIcon.frame.midY)
        goldParticles!.particleColor = UIColor.yellowColor()
        goldParticles!.particleColorSequence = nil
        goldParticles!.advanceSimulationTime(3.0)
        currencyNode.addChild(goldParticles!)
        
        if parentScene.IS_IPAD == true {
            lilacParticles!.particleScale *= 2
            silverParticles!.particleScale *= 2
            goldParticles!.particleScale *= 2
        }
    }
    
    func createMenu() {
        for (spriteName, sprite) in spriteGroups["menuPlacements"]! {
            if spriteName != "menuButton" && spriteName != "currency-Node" {
                self.addChild(sprite)
            }
            
            if spriteName != "menu_bg" && spriteName != "right_nav" && spriteName != "menuButton" && spriteName != "left_nav" && spriteName != "currency-Node"{
                sprite.alpha = 0.5
            }
        }
        
        // Set up last minute currency stuff for the weapons menu
        loadWeaponCurrencyInfo()
        spriteGroups["weaponsMenu"]!["footer"]!.addChild(weaponsMenu_currencyNum)
    }
    
    func createBaseMenu() {
        
        currentMenuSprites["baseMenu"] = [String: SKSpriteNode]()
        
        // base
        let base = spriteGroups["baseMenu"]!["menu_base"]!
        currentMenuSprites["baseMenu"]!["base"] = base
        
        // dome
        var domeNumber = GameData.sharedInstance.baseStates!["dome"]
        if GameData.sharedInstance.nextBaseUpgrade == "dome" && domeNumber != 4 {
            domeNumber!++
        }
        if domeNumber != 0 {
            let domeString = "menu_dome-" + "\(domeNumber!)"
            let dome = spriteGroups["baseMenu"]![domeString]!
            dome.zPosition = 5
            dome.name = "dome"
            currentMenuSprites["baseMenu"]!["dome"] = dome
        }
        
        createBaseLevelFrames("dome")
        
        // hangar
        var hangarNumber = GameData.sharedInstance.baseStates!["hangar"]
        if GameData.sharedInstance.nextBaseUpgrade == "hangar" && hangarNumber != 4{
            hangarNumber!++
        }
        if hangarNumber != 0 {
            let hangarString = "menu_hangar-" + "\(hangarNumber!)"
            let hangar = spriteGroups["baseMenu"]![hangarString]!
            hangar.zPosition = 5
            hangar.name = "hangar"
            currentMenuSprites["baseMenu"]!["hangar"] = hangar
        }
        
        createBaseLevelFrames("hangar")
        
        // lab
        var labNumber = GameData.sharedInstance.baseStates!["lab"]
        if GameData.sharedInstance.nextBaseUpgrade == "lab" && labNumber != 4 {
            labNumber!++
        }
        if labNumber != 0 {
            let labString = "menu_lab-" + "\(labNumber!)"
            let lab = spriteGroups["baseMenu"]![labString]!
            lab.zPosition = 5
            lab.name = "lab"
            currentMenuSprites["baseMenu"]!["lab"] = lab
        }
        
        createBaseLevelFrames("lab")
        
        // upgradeButton
        let upgradeButton = spriteGroups["baseMenu"]!["baseUpgradeButton"]
        currentMenuSprites["baseMenu"]!["upgradeButton"] = upgradeButton
        
        loadBaseCurrencyInfo()
    }
    
    func createBaseLevelFrames(key: String) {
        // Level frame
        let string = "b_levelFrame-\(key)"
        let levelFrame = SKSpriteNode(texture: textures["baseLevelFrame"])
        levelFrame.anchorPoint = CGPointMake(0, 1)
        levelFrame.position = getCorrectPosition(placementGroups["baseMenu"]![string]!)
        levelFrame.zPosition = 5
        currentMenuSprites["baseMenu"]![string] = levelFrame
        
        // Level fill
        let string2 = "b_levelFill-\(key)"
        let levelFill = SKSpriteNode(texture: textures["baseLevelFill"])
        levelFill.anchorPoint = CGPointMake(0, 1)
        levelFill.position = getCorrectPosition(placementGroups["baseMenu"]![string2]!)
        levelFill.zPosition = 5
        
        // Place a levelFill for each sublevel of the building
        for var i = 0 ; i < GameData.sharedInstance.baseStates![key]; ++i {
            let copyFill = levelFill.copy() as! SKSpriteNode
            let newX = CGFloat((copyFill.size.width * 2.51) * CGFloat(i))
            copyFill.position.x += newX
            
            currentMenuSprites["baseMenu"]!["\(string2)-\(i)"] = copyFill
        }
    }
    
    func createPrestigeMenu() {
        currentMenuSprites["prestigeMenu"] = [String: SKSpriteNode]()
        
        // firstPlanet
        let firstPlanetNum = GameData.sharedInstance.planetStats!["firstPlanet"]!
        if firstPlanetNum != 0 {
            for i in 1...firstPlanetNum{
                
                let medal = spriteGroups["prestigeMenu"]!["firstPlanet_medal-\(i)"]!
                medal.zPosition = 5
                currentMenuSprites["prestigeMenu"]![medal.name!] = medal
                
                if i == 4 {
                    break
                }
            }
        }
        
        // secondPlanet
        let secondPlanetNum = GameData.sharedInstance.planetStats!["secondPlanet"]!
        if secondPlanetNum != 0 {
            for i in 1...secondPlanetNum {
                let medal = spriteGroups["prestigeMenu"]!["secondPlanet_medal-\(i)"]!
                medal.zPosition = 5
                currentMenuSprites["prestigeMenu"]![medal.name!] = medal
                
                if i == 4 {
                    break
                }
            }
        }
        
        // firstPlanet
        let thirdPlanetNum = GameData.sharedInstance.planetStats!["thirdPlanet"]!
        if thirdPlanetNum != 0 {
            for i in 1...thirdPlanetNum {
                let medal = spriteGroups["prestigeMenu"]!["thirdPlanet_medal-\(i)"]!
                medal.zPosition = 5
                currentMenuSprites["prestigeMenu"]![medal.name!] = medal
                
                if i == 4 {
                    break
                }
            }
        }
        
        // silhouette
        let medals_bg = spriteGroups["prestigeMenu"]!["medals_bg"]!
        currentMenuSprites["prestigeMenu"]!["medals_bg"] = medals_bg
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first! 
        let touchLocation = touch.locationInNode(self)        
        var nodeTouched = self.nodeAtPoint(touchLocation)
        
        let minNavPosition = spriteGroups["menuPlacements"]!["menu_bg"]!.position.y - (spriteGroups["menuPlacements"]!["menu_bg"]!.size.height * 1/8)
        let medals_nav_minX = spriteGroups["menuPlacements"]!["medals_nav"]!.position.x
        let medals_nav_maxX = medals_nav_minX + spriteGroups["menuPlacements"]!["medals_nav"]!.size.width
        
        if touchLocation.y > minNavPosition {
            
            // menu_bg consumes touches meant for medals_nav...
            if nodeTouched.name == "menu_bg" && touchLocation.x >= medals_nav_minX && touchLocation.x <= medals_nav_maxX {
                nodeTouched = spriteGroups["menuPlacements"]!["medals_nav"]!
            }
            
            processNav(nodeTouched as! SKSpriteNode)
            return
        }
        
        switch state {
        case MenuState.WeaponMenu.rawValue:
            break
        case MenuState.SettingsMenu.rawValue:
            if nodeTouched.name == "facebookButton" {
                
                colorizeNodeTouched(nodeTouched as! SKSpriteNode)
                AudioManager.sharedInstance.playSound("button_click")

                let waitAndPost = SKAction.sequence([SKAction.waitForDuration(0.5), SKAction.runBlock({ self.postToFacebook() })])
                self.runAction(SKAction.runBlock({ self.dismissMenu() }), completion: { self.runAction(waitAndPost) })
            }
            else if nodeTouched.name == "twitterButton" {
                
                colorizeNodeTouched(nodeTouched as! SKSpriteNode)
                AudioManager.sharedInstance.playSound("button_click")
                
                let waitAndPost = SKAction.sequence([SKAction.waitForDuration(0.5), SKAction.runBlock({ self.postToTwitter() })])
                self.runAction(SKAction.runBlock({ self.dismissMenu() }), completion: { self.runAction(waitAndPost) })
            }
            
            break
        case MenuState.BaseMenu.rawValue:
            if nodeTouched.name == "baseUpgradeButton" && currentMenuSprites["baseMenu"]!["upgradeButton"]!.childNodeWithName("label")!.hidden == false {
                colorizeNodeTouched(nodeTouched as! SKSpriteNode)
                AudioManager.sharedInstance.playSound("upgrade_base")
                upgradeBase()
            }
            else if nodeTouched.parent?.name == "baseUpgradeButton" && currentMenuSprites["baseMenu"]!["upgradeButton"]!.childNodeWithName("label")!.hidden == false {
                nodeTouched = nodeTouched.parent as! SKSpriteNode
                colorizeNodeTouched(nodeTouched as! SKSpriteNode)
                AudioManager.sharedInstance.playSound("upgrade_base")
                upgradeBase()
            }
            break
        default:
            // maybe stuff?
            break
        }
    }
    
    func postToFacebook() {
        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
            let facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
            facebookSheet.setInitialText("Harvesting some asteroids in Solar Conquest!")
            facebookSheet.addImage(takeScreenShotToShare())
            parentScene.viewController.presentViewController(facebookSheet, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Accounts", message: "Please login to a Facebook account to share.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            parentScene.viewController.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func postToTwitter() {
        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
            let twitterSheet = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            twitterSheet.setInitialText("Harvesting some asteroids in Solar Conquest!")
            twitterSheet.addImage(takeScreenShotToShare())
            parentScene.viewController.presentViewController(twitterSheet, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController(title: "Accounts", message: "Please log in to a Twitter account to share", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            parentScene.viewController.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // Takes a screenshot for the player to share
    func takeScreenShotToShare() -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(UIScreen.mainScreen().bounds.size, false, 0);
        parentScene.viewController.view.drawViewHierarchyInRect(parentScene.viewController.view.bounds, afterScreenUpdates: true)
        let image:UIImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return image
    }
    
    private func colorizeNodeTouched(node: SKSpriteNode) {
        let colorize = (SKAction.colorizeWithColor(UIColor.blackColor(), colorBlendFactor: 0.7, duration: 0.05))
        let reverse = SKAction.colorizeWithColorBlendFactor(0.0, duration: 0.05)
        node.runAction(SKAction.sequence([colorize, reverse]))
        
        for child in node.children {
            child.runAction(SKAction.sequence([colorize, reverse]))
        }
    }
    
    func switchWeaponFocus(nodeTouched: WeaponMenuNode) {
        spriteGroups["weaponsMenu"]!["currentlyEquipped"]!.removeFromParent()
        nodeTouched.addChild(spriteGroups["weaponsMenu"]!["currentlyEquipped"]!)
        
        var oldSelectedNode = spriteGroups["weaponsMenu"]![previousSelectedWeapon]! as! WeaponMenuNode
        oldSelectedNode.wasSelected = false
        previousSelectedWeapon = nodeTouched.name
        
        changeNodeAlpha(&oldSelectedNode, value: 0.6)
        
        if GameData.sharedInstance.weaponInventory![nodeTouched.name!]!.unlocked! == true {
            parentScene.swapWeapon(nodeTouched.name!)
        }
        
        refreshWeaponCurrencyInfo(nodeTouched.name!)
    }
    
    private func processNav(nodeTouched: SKSpriteNode) {
        
        if nodeTouched.name == "right_nav" {
            dismissMenu()
            return
        }
        
        if nodeTouched.name == "left_nav" {
            return
        }
        
        AudioManager.sharedInstance.playSound("navPressed_menu")
        
        if nodeTouched.name == "base_nav" {
            if state != MenuState.BaseMenu.rawValue {
                removeCurrentMenu()
                changeNavAlpha("base_nav")
                displayBaseMenu()
            }
        }
        else if nodeTouched.name == "settings_nav" {
            if state != MenuState.SettingsMenu.rawValue {
                removeCurrentMenu()
                changeNavAlpha("settings_nav")
                displaySettingsMenu()
            }
        }
        else if nodeTouched.name == "medals_nav" {
            if state != MenuState.PrestigeMenu.rawValue {
                removeCurrentMenu()
                changeNavAlpha("medals_nav")
                displayPrestigeMenu()
            }
        }
        else if nodeTouched.name == "weapons_nav" {
            if state != MenuState.WeaponMenu.rawValue {
                removeCurrentMenu()
                changeNavAlpha("weapons_nav")
                displayWeaponsMenu()
            }
        }
    }
    
    func displayMenu() {
        self.hidden = false
        spriteGroups["menuPlacements"]!["weapons_nav"]!.alpha = 1
        displayWeaponsMenu()
    }
    
    func displayCurrencyNode() {
        self.parentScene.currencyNode = spriteGroups["menuPlacements"]!["currency-Node"]!
        self.parentScene.addChild(self.parentScene.currencyNode)
    }
    
    func displayWeaponsMenu() {
        state = MenuState.WeaponMenu.rawValue
        
        previousSelectedWeapon = GameData.sharedInstance.equippedWeaponName!
        
        for (spriteName, sprite) in spriteGroups["weaponsMenu"]! {
            
            if spriteName != "currentlyEquipped" {
                
                if spriteName == "laser" || spriteName == "machine_gun" || spriteName == "rail_gun" || spriteName == "missile_launcher" {
                    
                    var menuNode = sprite as! WeaponMenuNode
                    if spriteName != previousSelectedWeapon {
                        changeNodeAlpha(&menuNode, value: 0.6)
                        menuNode.wasSelected = false
                    }
                    else {
                        changeNodeAlpha(&menuNode, value: 1.0)
                        menuNode.wasSelected = true
                    }
                    
                    if GameData.sharedInstance.weaponInventory![spriteName]!.unlocked! == true {
                        if checkUpgradeAvailability(spriteName) == false {
                            sprite.childNodeWithName("upgradeButton")!.hidden = true
                        }
                        if checkUpgradeAvailability(spriteName) {
                            sprite.childNodeWithName("upgradeButton")!.hidden = false
                        }
                    }
                    else {
                        if checkUpgradeAvailability(spriteName) == false {
                            sprite.childNodeWithName("unlockButton")!.hidden = true
                        }
                        if checkUpgradeAvailability(spriteName) {
                            sprite.childNodeWithName("unlockButton")!.hidden = false
                        }
                    }
                    
                    spriteGroups["menuPlacements"]!["menu_bg"]!.addChild(sprite)

                }
                else if spriteName == "currency-icon" {
                    spriteGroups["weaponsMenu"]!["footer"]!.addChild(sprite)
                }
                else {
                    spriteGroups["menuPlacements"]!["menu_bg"]!.addChild(sprite)
                }
            }
            
            MEDAL_NAV_POSITION = spriteGroups["weaponsMenu"]!["machine_gun"]!.position.y
        }
        
        spriteGroups["weaponsMenu"]![previousSelectedWeapon]!.addChild(equippedPlate)
        refreshWeaponCurrencyInfo(previousSelectedWeapon)
        
        spriteGroups["weaponsMenu"]!["missile_launcher"]!.userInteractionEnabled = true
        spriteGroups["weaponsMenu"]!["rail_gun"]!.userInteractionEnabled = true
        spriteGroups["weaponsMenu"]!["machine_gun"]!.userInteractionEnabled = true
        spriteGroups["weaponsMenu"]!["laser"]!.userInteractionEnabled = true
    }
    
    func refreshWeaponsMenu() {
        for (spriteName, sprite) in spriteGroups["weaponsMenu"]! {
            if spriteName == "laser" || spriteName == "machine_gun" || spriteName == "rail_gun" || spriteName == "missile_launcher" {
                
                var menuNode = sprite as! WeaponMenuNode
                if spriteName != previousSelectedWeapon {
                    changeNodeAlpha(&menuNode, value: 0.6)
                    menuNode.wasSelected = false
                }
                else {
                    changeNodeAlpha(&menuNode, value: 1.0)
                    menuNode.wasSelected = true
                }
                
                if GameData.sharedInstance.weaponInventory![spriteName]!.unlocked! == true {
                    if checkUpgradeAvailability(spriteName) == false {
                        sprite.childNodeWithName("upgradeButton")!.hidden = true
                    }
                    if checkUpgradeAvailability(spriteName) {
                        sprite.childNodeWithName("upgradeButton")!.hidden = false
                    }
                }
                else {
                    if checkUpgradeAvailability(spriteName) == false {
                        sprite.childNodeWithName("unlockButton")!.hidden = true
                    }
                    if checkUpgradeAvailability(spriteName) {
                        sprite.childNodeWithName("unlockButton")!.hidden = false
                    }
                }
            }
        }
    }
    
    func displayBaseMenu() {
        state = MenuState.BaseMenu.rawValue
        
        if currentMenuSprites["baseMenu"] == nil {
            createBaseMenu()
        }
        
        for (_, sprite) in currentMenuSprites["baseMenu"]! {
            spriteGroups["menuPlacements"]!["menu_bg"]!.addChild(sprite)
        }
        
        if checkBaseUpgradeAvailability() == true {
            currentMenuSprites["baseMenu"]!["upgradeButton"]!.childNodeWithName("label")!.hidden = false
        }
    }
    
    func refreshBaseMenu(justUpgraded: String, nextToUpgrade: String) {
        
        refreshBaseLevelFrame(justUpgraded)
        
        refreshBaseCurrencyInfo()
        
        if nextToUpgrade == "forceField" {
            // do something special
        }
        else {
            // update the next guy's texture
            let number = (GameData.sharedInstance.baseStates![nextToUpgrade]!) + 1
            let string = "menu_\(nextToUpgrade)-" + "\(number)"
            let newSrite = spriteGroups["baseMenu"]![string]!
            newSrite.zPosition = 5
            newSrite.name = nextToUpgrade
            currentMenuSprites["baseMenu"]![nextToUpgrade]?.removeFromParent()
            currentMenuSprites["baseMenu"]![nextToUpgrade] = newSrite
            spriteGroups["menuPlacements"]!["menu_bg"]!.addChild(newSrite)
        }
        
        if checkBaseUpgradeAvailability() == false {
            currentMenuSprites["baseMenu"]!["upgradeButton"]!.childNodeWithName("label")!.hidden = true
        }
    }
    
    func refreshBaseLevelFrame(key: String) {
        let string = "b_levelFill-\(key)"
        
        //remove any old ones
        currentMenuSprites["baseMenu"]!["\(string)-\(0)"]?.removeFromParent()
        currentMenuSprites["baseMenu"]!["\(string)-\(1)"]?.removeFromParent()
        currentMenuSprites["baseMenu"]!["\(string)-\(2)"]?.removeFromParent()
        
        // Level fill
        let levelFill = SKSpriteNode(texture: textures["baseLevelFill"])
        levelFill.anchorPoint = CGPointMake(0, 1)
        levelFill.position = getCorrectPosition(placementGroups["baseMenu"]![string]!)
        levelFill.zPosition = 5
        
        // Place a levelFill for each sublevel of the building
        for var i = 0 ; i < GameData.sharedInstance.baseStates![key]; ++i {
            let copyFill = levelFill.copy() as! SKSpriteNode
            let newX = CGFloat((copyFill.size.width * 2.51) * CGFloat(i))
            copyFill.position.x += newX
            copyFill.name = "\(string)-\(i)"
            
            currentMenuSprites["baseMenu"]!["\(string)-\(i)"] = copyFill
            spriteGroups["menuPlacements"]!["menu_bg"]!.addChild(copyFill)
        }
    }
    
    func displayPrestigeMenu() {
        state = MenuState.PrestigeMenu.rawValue
        
        if currentMenuSprites["prestigeMenu"] == nil {
            createPrestigeMenu()
        }
        
        for (_, sprite) in currentMenuSprites["prestigeMenu"]! {
            spriteGroups["menuPlacements"]!["menu_bg"]!.addChild(sprite)
        }
    }
    
    func displaySettingsMenu() {
        state = MenuState.SettingsMenu.rawValue
        
        for (_, sprite) in spriteGroups["settingsMenu"]! {
            spriteGroups["menuPlacements"]!["menu_bg"]!.addChild(sprite)
        }
    }
    
    func removeWeaponsMenu() {
        
        for (_, sprite) in spriteGroups["weaponsMenu"]! {
            sprite.removeFromParent()
        }
        
        equippedPlate.removeFromParent()
        spriteGroups["menuPlacements"]!["weapons_nav"]!.alpha = 0.5
    }
    
    func removeBaseMenu() {
        for (_, sprite) in currentMenuSprites["baseMenu"]! {
            sprite.removeFromParent()
        }
        
        spriteGroups["menuPlacements"]!["base_nav"]!.alpha = 0.5
    }
    
    func removePrestigeMenu() {
        for (_, sprite) in currentMenuSprites["prestigeMenu"]! {
            sprite.removeFromParent()
        }
        
        spriteGroups["menuPlacements"]!["medals_nav"]!.alpha = 0.5
    }
    
    func removeSettingsMenu() {
        for (_, sprite) in spriteGroups["settingsMenu"]! {
            sprite.removeFromParent()
        }
        
        spriteGroups["menuPlacements"]!["settings_nav"]!.alpha = 0.5        
    }
    
    func dismissMenu(endGame: Bool = false) {
        self.userInteractionEnabled = false
        bgNode.runAction(SKAction.fadeOutWithDuration(0.2))
        let slide = SKAction.moveToX(-40, duration: 0.1)
        let moveAction = SKAction.sequence([slide, SKAction.moveToX(self.parentScene.size.width * 0.8, duration: 0.2)])
        self.runAction(moveAction, completion: { self.actuallyDismissMenu(endGame) } )
        
        AudioManager.sharedInstance.playSound("dismiss_menu")
    }
    
    private func actuallyDismissMenu(endGame: Bool) {
        self.runAction(SKAction.waitForDuration(0.15))
        
        bgNode.removeFromParent()
        self.hidden = true
        if endGame == false {
            menuButton.hidden = false
            parentScene.boostMenuButton.hidden = false
        }
        parentScene.userInteractionEnabled = true
        parentScene.gestureRecognizer.enabled = true
        
        parentScene.state = GameState.GameIdle.rawValue
        
        removeCurrentMenu()
    }
    
    func removeCurrentMenu() {
        switch state {
        case MenuState.WeaponMenu.rawValue:
            
            removeWeaponsMenu()
            break
        
        case MenuState.SettingsMenu.rawValue:
            
            removeSettingsMenu()
            break
        
        case MenuState.BaseMenu.rawValue:
            
            removeBaseMenu()
            break
        
        default:
            removePrestigeMenu()
            break
        }
    }
    
    func makeCurrencyParticles(key: String) {
        (parentScene.currencyNode.childNodeWithName("\(key)Particles") as! SKEmitterNode).resetSimulation()
    }
    
    private func positionScale(position: CGPoint, scale: CGFloat) -> CGPoint {
        return CGPointMake(position.x * scale, position.y * scale)
    }
    
    // For @2x resolution, dividing the pixels by 2 seems to work
    // For ipad, it has to be 1
    // I wonder what @3x will be...
    private func getCorrectPosition(placement: Placement) -> CGPoint {
        if placement.parentNode == "weapon-Node" {
            let adjustedY = placement.position.y - weaponNodeSize.height
            var adj_pointConversion:CGFloat

            if parentScene.IS_IPAD == true {
                adj_pointConversion = 2.0
            }
            else {
                adj_pointConversion = pointConversion
            }
            
            let adjustedPosition = positionScale(CGPointMake(placement.position.x, adjustedY), scale: 1)
            return CGPointMake(adjustedPosition.x / adj_pointConversion, adjustedPosition.y / adj_pointConversion)
        }
        else if placement.parentNode == "setting-Node" {
            var adj_pointConversion:CGFloat
            
            if parentScene.IS_IPAD == true {
                adj_pointConversion = 2.0
            }
            else {
                adj_pointConversion = pointConversion
            }
            
            let adjustedY = placement.position.y - settingNodeSize.height
            let adjustedPosition = positionScale(CGPointMake(placement.position.x, adjustedY), scale: 1)
            return CGPointMake(adjustedPosition.x / adj_pointConversion, adjustedPosition.y / adj_pointConversion)
        }
        else if placement.parentNode == "currency-Node" {
            var adj_scale: CGFloat
            
            // for the ipad
            if pointConversion == 1.0 {
                adj_scale = 1
            }
            else {
                adj_scale = scale
            }
            
            let adjustedY = placement.position.y - currencyNodeSize.height
            let adjustedPosition = positionScale(CGPointMake(placement.position.x, adjustedY), scale: adj_scale)
            return CGPointMake(adjustedPosition.x / pointConversion, adjustedPosition.y / pointConversion)
        }
        else if placement.parentNode == "menu_bg" {
            var adj_pointConversion:CGFloat
            
            if parentScene.IS_IPAD == true {
                adj_pointConversion = 2.0
            }
            else {
                adj_pointConversion = pointConversion
            }
            
            let adjustedY = placement.position.y - menu_bgSize.height
            let adjustedPosition = positionScale(CGPointMake(placement.position.x, adjustedY), scale: 1)
            return CGPointMake(adjustedPosition.x / adj_pointConversion, adjustedPosition.y / adj_pointConversion)
        }
        else {
            // If it's an i4, move stuff down by a fourth the screen size
            if parentScene.IS_IPHONE_4 && placement.name != "currency-Node" {
                let adjustedY = placement.position.y - parentScene.size.height/4
                let adjustedPosition = positionScale(CGPointMake(placement.position.x, adjustedY), scale: scale)
                return CGPointMake(adjustedPosition.x / pointConversion, adjustedPosition.y / pointConversion)
            }
            else {
                var adj_scale: CGFloat
                
                // for the ipad
                if pointConversion == 1.0 {
                    adj_scale = 1
                }
                else {
                    adj_scale = scale
                }
                
                let adjustedPosition = positionScale(placement.position, scale: adj_scale)
                return CGPointMake(adjustedPosition.x / pointConversion, adjustedPosition.y / pointConversion)
            }
        }
    }
    
    // This is what I do when I don't feel like opening photoshop and just exporting new coordinates
    private func getBaseUpgradeButtonPosition(placement: Placement) -> CGPoint {
        var adj_scale: CGFloat
        var adj_pointConversion:CGFloat
        
        if parentScene.IS_IPAD == true {
            adj_pointConversion = 2.5
            adj_scale = 1.0
        }
        else if scale == 1.0 {
            adj_pointConversion = pointConversion
            adj_scale = scale - 0.2
        }
        else if parentScene.IS_SUPER_HIGH_RES == true {
            adj_pointConversion = 2
            adj_scale = scale - 0.3
        }
        else {
            adj_pointConversion = pointConversion
            adj_scale = scale - 0.1
        }
        
        let adjustedY = placement.position.y - spriteGroups["baseMenu"]!["baseUpgradeButton"]!.size.height
        let adjustedPosition = positionScale(CGPointMake(placement.position.x, adjustedY), scale: adj_scale)
        return CGPointMake(adjustedPosition.x / adj_pointConversion, adjustedPosition.y / adj_pointConversion)
    }
    
    private func changeNodeAlpha(inout node: WeaponMenuNode, value: CGFloat) {
        for child in node.children {
            (child as! SKSpriteNode).alpha = value
        }
    }
    
    // change the nav alpha for the current nav and the new one
    private func changeNavAlpha(navTuched: String) {
        switch state {
        case MenuState.WeaponMenu.rawValue:
            spriteGroups["menuPlacements"]!["weapons_nav"]!.alpha = 0.5
            break
            
        case MenuState.SettingsMenu.rawValue:
            
            spriteGroups["menuPlacements"]!["settings_nav"]!.alpha = 0.5
            break
            
        case MenuState.BaseMenu.rawValue:
            
            spriteGroups["menuPlacements"]!["base_nav"]!.alpha = 0.5
            break
            
        default:
            spriteGroups["menuPlacements"]!["medals_nav"]!.alpha = 0.5
        }
        
        spriteGroups["menuPlacements"]![navTuched]!.alpha = 1
    }
    
    func checkUpgradeAvailability(key : String) -> Bool {
        
        let levelNum = GameData.sharedInstance.weaponInventory![key]!.level
        let sublevelNum = GameData.sharedInstance.weaponInventory![key]!.sublevel
        let currencyNum = CurrencyManager.getWeaponCurrencyNum(levelNum, sublevel: sublevelNum)
        
        if GameData.sharedInstance.currency![CurrencyManager.getWeaponCurrencyName(levelNum)] < currencyNum {
            return false
        }
        else if levelNum == 3 && sublevelNum == 3 {
            return false
        }
        else {
            return true
        }
    }
    
    // If the weapon is a new level now, load the new-looking weapon and play the special sound
    func upgradeWeapon(weaponName: String) {
        updateCurrencyNode(weaponName)
        
        if GameData.sharedInstance.weaponInventory![weaponName]!.upgrade() == true {
            parentScene.swapWeapon(weaponName)
            AudioManager.sharedInstance.playSound("upgrade_weapon_special")
        }
        else {
            AudioManager.sharedInstance.playSound("upgrade_weapon")
        }
        
        refreshWeaponsMenu()
        
        refreshWeaponCurrencyInfo(weaponName)
        
        parentScene.equippedWeapon.refreshDamageInfo()
        
        var node = spriteGroups["weaponsMenu"]![weaponName]! as! WeaponMenuNode
        createLevelFills(&node)
        GameData.save()
    }
    
    func unlockWeapon(weaponName: String) {
        
        var node = spriteGroups["weaponsMenu"]![weaponName]! as! WeaponMenuNode
        
        updateCurrencyNode(weaponName)
        
        GameData.sharedInstance.weaponInventory![weaponName]!.unlock()
        GameData.save()
        
        node.childNodeWithName("unlockButton")?.removeFromParent()
        node.childNodeWithName("locked-icon")?.removeFromParent()
        addWeaponNodeChildren(&node)
        previousSelectedWeapon = weaponName
        GameData.sharedInstance.equippedWeaponName = weaponName
        parentScene.swapWeapon(weaponName)
        
        refreshWeaponsMenu()
        refreshWeaponCurrencyInfo(weaponName)
    }
    
    func upgradeBase() {
        let amountNums = CurrencyManager.getBaseCurrencyInfo(GameData.sharedInstance.currentProgress!)
        
        parentScene.updateCurrency("lilac", value: -amountNums.0, animate: false)
        parentScene.updateCurrency("silver", value: -amountNums.0, animate: false)
        parentScene.updateCurrency("gold", value: -amountNums.0, animate: false)
        
        let info = parentScene.planetBase.upgradeBase(&GameData.sharedInstance.baseStates!)
        
        if info.0 != "done" {
            refreshBaseMenu(info.0, nextToUpgrade: info.1)
            GameData.save()
        }
    }
    
    func checkBaseUpgradeAvailability() -> Bool {
        let amountNums = CurrencyManager.getBaseCurrencyInfo(GameData.sharedInstance.currentProgress!)
        
        if GameData.sharedInstance.currency!["lilac"] >= amountNums.0 {
            if GameData.sharedInstance.currency!["silver"] >= amountNums.1 {
                if GameData.sharedInstance.currency!["gold"] >= amountNums.2 {
                    return true
                }
            }
        }
        
        return false
    }
    
    func updateCurrencyNode(forWeapon: String) {
        let levelNum = GameData.sharedInstance.weaponInventory![forWeapon]!.level
        let sublevelNum = GameData.sharedInstance.weaponInventory![forWeapon]!.sublevel
        let currencyNum = CurrencyManager.getWeaponCurrencyNum(levelNum, sublevel: sublevelNum)
        let currencyName = CurrencyManager.getWeaponCurrencyName(levelNum)
        
        parentScene.updateCurrency(currencyName, value: -currencyNum, animate: false)
    }
    
    func refreshWeaponCurrencyInfo(forWeapon: String) {
        let levelNum = GameData.sharedInstance.weaponInventory![forWeapon]!.level
        let sublevelNum = GameData.sharedInstance.weaponInventory![forWeapon]!.sublevel
        let currencyNum = CurrencyManager.getWeaponCurrencyNum(levelNum, sublevel: sublevelNum)
        let iconName = CurrencyManager.getWeaponCurrencyName(levelNum)
        spriteGroups["weaponsMenu"]!["currency-icon"]!.texture = textures["\(iconName)-icon"]
        weaponsMenu_currencyNum.set_Text("\(currencyNum)")
    }
    
    func refreshBaseCurrencyInfo() {
        let amountNums = CurrencyManager.getBaseCurrencyInfo(GameData.sharedInstance.currentProgress!)
        (currentMenuSprites["baseMenu"]!["upgradeButton"]!.childNodeWithName("lilac") as! BitMapFontLabel).set_Text("\(amountNums.0)")
        (currentMenuSprites["baseMenu"]!["upgradeButton"]!.childNodeWithName("silver") as! BitMapFontLabel).set_Text("\(amountNums.1)")
        (currentMenuSprites["baseMenu"]!["upgradeButton"]!.childNodeWithName("gold") as! BitMapFontLabel).set_Text("\(amountNums.2)")
    }
    
    func loadBaseCurrencyInfo() {
        let adjustHeight = spriteGroups["baseMenu"]!["baseUpgradeButton"]!.size.height / 2
        let adjustWidth = spriteGroups["baseMenu"]!["baseUpgradeButton"]!.size.width / 2
        
        let amountNums = CurrencyManager.getBaseCurrencyInfo(GameData.sharedInstance.currentProgress!)
        var adj_scale: CGFloat
        
        if parentScene.IS_IPAD == true {
            adj_scale = 0.9
        }
        else if scale == 1.0 {
            adj_scale = 0.2
        }
        else if parentScene.IS_SUPER_HIGH_RES == true {
            adj_scale = 0.35
        }
        else {
            adj_scale = 0.1
        }
        
        // label
        let label = SKSpriteNode(imageNamed: "build_label")
        label.position = CGPointMake(adjustWidth, -adjustHeight * 0.75)
        label.zPosition = 5
        label.userInteractionEnabled = false
        label.name = "label"
        label.hidden = true
        spriteGroups["baseMenu"]!["baseUpgradeButton"]!.addChild(label)
        
        // lilac
        let lilacIcon = SKSpriteNode(texture: textures["lilac-icon"])
        lilacIcon.anchorPoint = CGPointMake(0, 1)
        lilacIcon.position = getBaseUpgradeButtonPosition(placementNodeGroups["currency-Node"]!["lilac-icon"]!)
        lilacIcon.position = CGPointMake(lilacIcon.position.x, lilacIcon.position.y - adjustHeight)
        lilacIcon.setScale(scale - adj_scale)
        lilacIcon.userInteractionEnabled = false
        lilacIcon.zPosition = 5
        spriteGroups["baseMenu"]!["baseUpgradeButton"]!.addChild(lilacIcon)
        
        let lilacNum = amountNums.0
        let lilacAmount = BitMapFontLabel(text: "\(lilacNum)", fontName: "number_", usingAtlas: "atlas_fonts.atlas")
        lilacAmount.name = "lilac"
        lilacAmount.position = getBaseUpgradeButtonPosition(placementNodeGroups["currency-Node"]!["lilac-num"]!)
        lilacAmount.position = CGPointMake(lilacAmount.position.x, lilacAmount.position.y - adjustHeight)
        lilacAmount.setScale(scale - adj_scale)
        lilacAmount.userInteractionEnabled = false
        spriteGroups["baseMenu"]!["baseUpgradeButton"]!.addChild(lilacAmount)
        
        // silver
        let silverIcon = SKSpriteNode(texture: textures["silver-icon"])
        silverIcon.anchorPoint = CGPointMake(0, 1)
        silverIcon.position = getBaseUpgradeButtonPosition(placementNodeGroups["currency-Node"]!["silver-icon"]!)
        silverIcon.position = CGPointMake(silverIcon.position.x, silverIcon.position.y - adjustHeight)
        silverIcon.setScale(scale - adj_scale)
        silverIcon.zPosition = 5
        silverIcon.userInteractionEnabled = false
        spriteGroups["baseMenu"]!["baseUpgradeButton"]!.addChild(silverIcon)
        
        let silverNum = amountNums.1
        let silverAmount = BitMapFontLabel(text: "\(silverNum)", fontName: "number_", usingAtlas: "atlas_fonts.atlas")
        silverAmount.name = "silver"
        silverAmount.position = getBaseUpgradeButtonPosition(placementNodeGroups["currency-Node"]!["silver-num"]!)
        silverAmount.position = CGPointMake(silverAmount.position.x, silverAmount.position.y - adjustHeight)
        silverAmount.setScale(scale - adj_scale)
        silverAmount.userInteractionEnabled = false
        spriteGroups["baseMenu"]!["baseUpgradeButton"]!.addChild(silverAmount)
        
        // gold
        let goldIcon = SKSpriteNode(texture: textures["gold-icon"])
        goldIcon.anchorPoint = CGPointMake(0, 1)
        goldIcon.position = getBaseUpgradeButtonPosition(placementNodeGroups["currency-Node"]!["gold-icon"]!)
        goldIcon.position = CGPointMake(goldIcon.position.x, goldIcon.position.y - adjustHeight)
        goldIcon.setScale(scale - adj_scale)
        goldIcon.zPosition = 5
        goldIcon.userInteractionEnabled = false
        spriteGroups["baseMenu"]!["baseUpgradeButton"]!.addChild(goldIcon)
        
        let goldNum = amountNums.2
        let goldAmount = BitMapFontLabel(text: "\(goldNum)", fontName: "number_", usingAtlas: "atlas_fonts.atlas")
        goldAmount.name = "gold"
        goldAmount.position = getBaseUpgradeButtonPosition(placementNodeGroups["currency-Node"]!["gold-num"]!)
        goldAmount.position = CGPointMake(goldAmount.position.x, goldAmount.position.y - adjustHeight)
        goldAmount.setScale(scale - adj_scale)
        goldAmount.userInteractionEnabled = false
        spriteGroups["baseMenu"]!["baseUpgradeButton"]!.addChild(goldAmount)
        
    }
    
    // Have to do these two by hand...literally
    func loadWeaponCurrencyInfo() {
        let levelNum = GameData.sharedInstance.weaponInventory![GameData.sharedInstance.equippedWeaponName!]!.level
        let sublevelNum = GameData.sharedInstance.weaponInventory![GameData.sharedInstance.equippedWeaponName!]!.sublevel
        let currencyNum = CurrencyManager.getWeaponCurrencyNum(levelNum, sublevel: sublevelNum)
        
        let iconName = CurrencyManager.getWeaponCurrencyName(levelNum)
        let icon = SKSpriteNode(texture: textures["\(iconName)-icon"])
        icon.name = "currency-icon"
        icon.anchorPoint = CGPointMake(0, 1)
        var adjustedY = placementGroups["weaponsMenu"]!["currency-icon"]!.position.y - 57 // It's 2am and fuck constants
        var adjustedPosition = positionScale(CGPointMake(placementGroups["weaponsMenu"]!["currency-icon"]!.position.x, adjustedY), scale: 1)
        icon.position = CGPointMake(adjustedPosition.x / 2, adjustedPosition.y / 2)
        icon.zPosition = 5
        spriteGroups["weaponsMenu"]!["currency-icon"]! = icon
        
        weaponsMenu_currencyNum = BitMapFontLabel(text: "\(currencyNum)", fontName: "number_", usingAtlas: "atlas_fonts.atlas")
        adjustedY = placementGroups["weaponsMenu"]!["currency-num"]!.position.y - 57 // yeah yeah
        adjustedPosition = positionScale(CGPointMake(placementGroups["weaponsMenu"]!["currency-num"]!.position.x, adjustedY), scale: 1)
        weaponsMenu_currencyNum.position = CGPointMake(adjustedPosition.x / 2, adjustedPosition.y / 2)
        weaponsMenu_currencyNum.zPosition = 5
        spriteGroups["weaponsMenu"]!.removeValueForKey("currency-num")
    }
    
    func addBgNode() {
        parentScene.addChild(bgNode)
        bgNode.runAction(SKAction.fadeInWithDuration(0.05))
    }
}
