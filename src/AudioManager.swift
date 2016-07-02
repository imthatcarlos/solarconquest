//
//  AudioManager.swift
//  SolarConquest
//
//  Created by Carlos Beltran on 7/23/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

import Foundation
import SpriteKit
import AVFoundation

@objc
class AudioManager: NSObject {
    
    class var sharedInstance: AudioManager {
        struct Singleton {
            static let instance = AudioManager()
        }
        
        return Singleton.instance
    }
    
    let soundNames = [  "button_click",
                        "dismiss_menu",
                        "display_menu",
                        "navPressed_menu",
                        "unlock_weapon",
                        "upgrade_base",
                        "upgrade_weapon",
                        "upgrade_weapon_special",
                        "missile_launcher_shoot",
                        "missile_launcher_hit",
                        "meteor_explode",
                        "rail_gun_charge",
                        "rail_gun_shoot",
                        "rail_gun_hit",
                        "machine_gun_shoot_1",
                        "laser_shoot",
                        "streak_1",
                        "bit_collect_1"]
    
    var sounds = [String: AVAudioPlayer]()
    var backgroundMusic:AVAudioPlayer!
    var soundsArePaused = false
    
    override init() {
        
    }
    
    func initialize() {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
        } catch _ {
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
        }
                
        if GameData.sharedInstance.settings!["sfx"]! == 0 {
            soundsArePaused = true
        }
    }
    
    // Load all the sounds we will need
    func preLoad() {
        
        let volume_sfx = Float(Double(GameData.sharedInstance.settings!["sfx"]!) / 10.0)
        for soundName in soundNames {
            let object = self.setupAudioPlayerWithFile(soundName, type: "caf")
            object.volume = volume_sfx
            sounds[soundName] = object
        }
        
        // bit collect copy instances
        for index in 2...5 {
            let object = self.setupAudioPlayerWithFile("bit_collect_1", type: "caf")
            object.volume = volume_sfx
            sounds["bit_collect_\(index)"] = object
        }
        
        // extra machine gun sounds
        let bullet_sound = self.setupAudioPlayerWithFile("machine_gun_shoot_1", type: "caf")
        bullet_sound.volume = volume_sfx
        sounds["machine_gun_shoot_2"] = bullet_sound
        
        let bullet_sound2 = self.setupAudioPlayerWithFile("machine_gun_shoot_1", type: "caf")
        bullet_sound2.volume = volume_sfx
        sounds["machine_gun_shoot_3"] = bullet_sound2
        
        // extra missile launcher sounds
        let object = self.setupAudioPlayerWithFile("missile_launcher_shoot", type: "caf")
        object.volume = volume_sfx
        sounds["missile_launcher_shoot2"] = object
        
        let object2 = self.setupAudioPlayerWithFile("missile_launcher_shoot", type: "caf")
        object2.volume = volume_sfx
        sounds["missile_launcher_shoot3"] = object2
    }
    
    // Play the given sound
    func playSound(sound: String, loopCount: Int = 0) {
        if soundsArePaused == true {
            return
        }
        
        sounds[sound]!.numberOfLoops = loopCount
        sounds[sound]!.currentTime = 0.05   // apparently CAFs have 0.05 sec delay
                
        // Play this sh*t somewhere NOT on the main thread!
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            sounds[sound]!.play()
        })
    }
    
    func stopSound(sound: String) {
        sounds[sound]!.stop()
    }
    
    func setMusic(newSong: String) {
        backgroundMusic = self.setupAudioPlayerWithFile(newSong, type: "aifc")
        backgroundMusic.numberOfLoops = -1
        backgroundMusic.volume = Float( Double( GameData.sharedInstance.settings!["music"]! ) / 50 )
    }
    
    func beginMusic() {
        if backgroundMusic?.volume != 0 {
            backgroundMusic?.play()
        }
    }
    
    func stopMusic() {
        backgroundMusic?.stop()
    }
    
    func pauseMusic() {
        backgroundMusic?.pause()
    }
    
    func resumeMusic() {
        backgroundMusic?.play()
    }
    
    func updateVolume(newSetting: Int, forSetting: String) {
        switch forSetting {
            case "music":
                if newSetting == 0 {
                    backgroundMusic.pause()
                }
                else if backgroundMusic.playing == false {
                    backgroundMusic.play()
                }
                
                backgroundMusic.volume = Float(Double(newSetting) / 50.0) // since max volume = 0.2... IT WORKS.
                break
            default:
                
                if newSetting == 0 {
                    soundsArePaused = true
                    return
                }
                else {
                    soundsArePaused = false
                }
                
                // Update all their volumes
                let newVolume = Float(Double(newSetting) / 10.0)
                for sound in sounds {
                    (sound.1).volume = newVolume
                }
                
                break
        }
    }
    
    // Returns the avaudioplayer we specify
    func setupAudioPlayerWithFile(file: NSString, type: NSString) -> AVAudioPlayer {
        let path = NSBundle.mainBundle().pathForResource(file as String, ofType: type as String)
        let url = NSURL.fileURLWithPath(path!)
        var audioPlayer: AVAudioPlayer?
        do {
            audioPlayer = try AVAudioPlayer(contentsOfURL: url)
        } catch {
            audioPlayer = nil
        }
        return audioPlayer!
    }
    
}