//
//  VolumeManager.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 24.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation

class VolumeManager {
    
    static let shared = VolumeManager()
    
    var sliderVolume: Float?

  
    private init() {
        sliderVolume = defaultSliderVolume
    }
}
