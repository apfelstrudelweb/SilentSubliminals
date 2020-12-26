//
//  VolumeManager.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 24.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import AVFoundation

class VolumeManager {
    
    static let shared = VolumeManager()
    
    var sliderVolume: Float = defaultSliderVolume
    var deviceVolume: Float = defaultSliderVolume
    
    let audioSession = AVAudioSession.sharedInstance()

    private init() {
        
        sliderVolume = defaultSliderVolume
        
        do {
            try audioSession.setActive(true)
            deviceVolume = audioSession.outputVolume * sliderVolume
        } catch {
            print("Error Setting Up Audio Session")
        }
    }
}
