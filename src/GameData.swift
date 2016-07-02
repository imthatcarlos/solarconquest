//
//  GameData.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 4/6/15.
//  Copyright (c) 2015 Carlos Beltran. All rights reserved.
//

import Foundation

// GameData is a wrapper for all the properties of the game that should be saved
// @param currentPlanet - To set up the right background
// @param currentProgress - To get the current progress
// @param equippedWeaponName - Get the weapon the user has equipped
//
// The amount of currency the player has saved up
// @param goldAmount
// @param silverAmount
// @param platinumAmount
//
// Save the amount of medals the player has for all planets. 
// Each time the player completes a planet, they receive a new medal
// @param planetStats
//
// SettingName:Value
// @param settings
//
// Key: WeaponData
// Information about all the weapons (unlocked, level)
// @param weaponInventory
class GameData: NSObject, NSCoding {
    
    class var sharedInstance: GameData {
        struct Singleton {
            static let instance = GameData()
        }
        
        return Singleton.instance
    }
    
    var currentPlanet: String?
    var currentProgress: Int?
    var equippedWeaponName: String?
    var currency: [String: Int]? // lilac | silver | gold
    var planetStats: [String: Int]?
    var settings : [String: Int]?
    var weaponInventory: [String: WeaponData]?
    var baseStates: [String: Int]?
    var nextBaseUpgrade: String?
    var iap_purchased: [String]?
    var tutorialCompleted: Bool?
    
    // If a file with the information in this class does not exist, create an instance
    override init() {
        super.init()
    }
    
    func initialize(newPlaythrough: Bool = false) {
        self.currentPlanet = "hasYetToChooseNew_"
        self.currentProgress = 0
        self.equippedWeaponName = "machine_gun"
        self.currency = ["lilac": 0, "silver": 0, "gold": 0]
        let weapons = setupWeapons()
        self.weaponInventory = [String:WeaponData]()
        self.baseStates = ["hangar": 0, "dome": 0, "lab": 0]
        self.nextBaseUpgrade = "hangar"
        
        if newPlaythrough == false {
            self.planetStats = ["firstPlanet": 0, "secondPlanet": 0, "thirdPlanet": 0]
            self.settings = ["music" : 5, "sfx": 5]
            iap_purchased = [String]()
            tutorialCompleted = false
        }
        
        for w in weapons {
            self.weaponInventory![w.name!] = w
        }
    }
    
    func reset() {
        initialize(true)
    }
    
    // Sets up the dictionary of weapon data for the first time
    // Unlocks missile_launcher
    func setupWeapons() -> [WeaponData] {
        var array:[WeaponData] = []
        
        let mg1 = WeaponData(name: "machine_gun")

        let m1 = WeaponData(name: "missile_launcher")
        
        let l1 = WeaponData(name: "laser")
        
        let rg1 = WeaponData(name: "rail_gun")
        
        mg1.unlock()
        
        array.append(mg1)
        array.append(m1)
        array.append(l1)
        array.append(rg1)

        return array
    }
    
    required convenience init? (coder aDecoder: NSCoder) {
        
        self.init()
        GameData.sharedInstance.currentPlanet = aDecoder.decodeObjectForKey("currentPlanet") as? String
        GameData.sharedInstance.currentProgress = aDecoder.decodeIntegerForKey("currentProgress")
        GameData.sharedInstance.equippedWeaponName = aDecoder.decodeObjectForKey("equippedWeaponName") as? String
        GameData.sharedInstance.currency = aDecoder.decodeObjectForKey("currency") as? [String: Int]
        GameData.sharedInstance.planetStats = aDecoder.decodeObjectForKey("planetStats") as? [String: Int]
        GameData.sharedInstance.settings = aDecoder.decodeObjectForKey("settings") as? [String: Int]
        GameData.sharedInstance.weaponInventory = aDecoder.decodeObjectForKey("weaponInventory") as? [String: WeaponData]
        GameData.sharedInstance.baseStates = aDecoder.decodeObjectForKey("baseStates") as? [String: Int]
        GameData.sharedInstance.nextBaseUpgrade = aDecoder.decodeObjectForKey("nextBaseUpgrade") as? String
        GameData.sharedInstance.iap_purchased = aDecoder.decodeObjectForKey("iap_purchased") as? [String]
        GameData.sharedInstance.tutorialCompleted = aDecoder.decodeBoolForKey("tutorialCompleted")
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(GameData.sharedInstance.currentPlanet, forKey: "currentPlanet")
        aCoder.encodeInteger(GameData.sharedInstance.currentProgress!, forKey: "currentProgress")
        aCoder.encodeObject(GameData.sharedInstance.equippedWeaponName, forKey: "equippedWeaponName")
        aCoder.encodeObject(GameData.sharedInstance.currency!, forKey: "currency")
        aCoder.encodeObject(GameData.sharedInstance.planetStats, forKey: "planetStats")
        aCoder.encodeObject(GameData.sharedInstance.settings, forKey: "settings")
        aCoder.encodeObject(GameData.sharedInstance.weaponInventory, forKey: "weaponInventory")
        aCoder.encodeObject(GameData.sharedInstance.baseStates, forKey: "baseStates")
        aCoder.encodeObject(GameData.sharedInstance.nextBaseUpgrade!, forKey: "nextBaseUpgrade")
        aCoder.encodeObject(GameData.sharedInstance.iap_purchased!, forKey: "iap_purchased")
        aCoder.encodeBool(GameData.sharedInstance.tutorialCompleted!, forKey: "tutorialCompleted")
    }
    
    // Saves the instance of gameData to a file in the documents directory
    class func save() {
        let filepath = GameData.getFilePath()
        NSKeyedArchiver.archiveRootObject(GameData.sharedInstance, toFile: filepath)
    }
    
    // Should return a path to docs directory
    class func documentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let string = paths[0] as NSString
        return string
    }
    
    class func getFilePath() -> String {
        return documentsDirectory().stringByAppendingPathComponent("gameData/")
    }
    
}