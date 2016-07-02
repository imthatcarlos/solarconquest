//
//  WeaponData.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 4/8/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation


// Information about each weapon
class WeaponData: NSObject, NSCoding {
    var name: String!
    var level: Int!
    var sublevel:Int!
    var unlocked:Bool!
    
    convenience required init?(coder aDecoder: NSCoder) {
        self.init(name: "error")
        self.name = aDecoder.decodeObjectForKey("name") as? String
        self.level = aDecoder.decodeIntegerForKey("level")
        self.sublevel = aDecoder.decodeIntegerForKey("sublevel")
        self.unlocked = aDecoder.decodeBoolForKey("unlocked")
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.name!, forKey: "name")
        aCoder.encodeInteger(self.level!, forKey: "level")
        aCoder.encodeInteger(self.sublevel!, forKey: "sublevel")
        aCoder.encodeBool(self.unlocked!, forKey: "unlocked")
    }
    
    init(name: String) {
        self.name = name
        self.level = 0
        self.sublevel = 0
        self.unlocked = false
    }
    
    func unlock() {
        self.level = 1
        self.unlocked = true
    }
    
    // Return true if the weapon should be reloaded
    func upgrade() -> Bool {
        var ret = false
        self.sublevel!++
        if sublevel == 4 {
            ret = true
            sublevel = 0
            self.level!++
        }
        
        return ret
    }
}