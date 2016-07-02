//
//  CurrencyManager.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 6/21/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation

class CurrencyManager {
    var parentScene : GameScene!
    
    init(parentScene: GameScene) {
        self.parentScene = parentScene
    }
    
    // Return the amount needed by the player12/
    static func getBaseCurrencyInfo(currentProgress: Int) -> (Int, Int, Int){
        if currentProgress != 12 {
            let lilacAmnt = 40 * (currentProgress + 1)
            let silverAmnt = 40 * (currentProgress + 1)
            let goldAmnt = 40 * (currentProgress + 1)
            return (lilacAmnt, silverAmnt, goldAmnt)
        }
        else {
            return (600, 600, 600)
        }
    }
    
    // Given a weapon level and sublevel, return the amount necessary to upgrade/unlock
    static func getWeaponCurrencyNum(level: Int, sublevel: Int) -> Int {
        
        if level == 0 {
            return 100
        }
        else {
            return 150 + (sublevel * 50)
        }
    }
    
    // Given a weapon level, return the icon for currency
    static func getWeaponCurrencyName(level: Int) -> String {
        switch level {
        case 0:
            return "lilac"
        case 1:
            return "lilac"
        case 2:
            return "silver"
        default:
            return "gold"
        }
    }
    
}