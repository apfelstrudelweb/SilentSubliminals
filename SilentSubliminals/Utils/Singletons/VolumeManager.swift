//
//  VolumeManager.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 24.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import AVFoundation

protocol VolumeManagerDelegate : AnyObject {
    
    func updateVolume(volume: Float)
}

class VolumeManager {
    
    weak var delegate : VolumeManagerDelegate?
    
    static let shared = VolumeManager()
    
    var sliderVolume: Float = defaultSliderVolume {
        didSet {
            //deviceVolume = audioSession.outputVolume * sliderVolume
            delegate?.updateVolume(volume: sliderVolume)
            print(sliderVolume)
        }
    }
    //var deviceVolume: Float = defaultSliderVolume
    
    //let audioSession = AVAudioSession.sharedInstance()

    private init() {
        
        sliderVolume = defaultSliderVolume
        
//        //[[AVAudioSession sharedInstance] addObserver:self forKeyPath:@"outputVolume" options:NSKeyValueObservingOptionNew context:nil]
//        //audioSession.addObserver(<#T##observer: NSObject##NSObject#>, forKeyPath: <#T##String#>, options: <#T##NSKeyValueObservingOptions#>, context: <#T##UnsafeMutableRawPointer?#>)
//
//        do {
//            try audioSession.setActive(true)
//            //deviceVolume = audioSession.outputVolume * sliderVolume
//        } catch {
//            print("Error Setting Up Audio Session")
//        }
    }
}
