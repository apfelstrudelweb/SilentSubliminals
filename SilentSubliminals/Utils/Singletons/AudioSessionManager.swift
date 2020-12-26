//
//  AudioSessionManager.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 25.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

protocol AudioSessionManagerDelegate : AnyObject {
    
    //func enablePlayButton(flag: Bool)
    func showWarning()
}

class AudioSessionManager {
    
    weak var delegate : AudioSessionManagerDelegate?
    
    static let shared = AudioSessionManager()
    
    private init() {
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            //try AVAudioSession.sharedInstance().setCategory(.ambient, options: .allowBluetooth)
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true, options: [])
            let ioBufferDuration = 128.0 / 44100.0
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(ioBufferDuration)
        } catch {
            assertionFailure("AVAudioSession setup error: \(error)")
        }

        //        do {
        //            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        //            //try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        //            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
        //            let ioBufferDuration = 128.0 / 44100.0
        //            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(ioBufferDuration)
        //        } catch {
        //            assertionFailure("AVAudioSession setup error: \(error)")
        //        }
    }
    
    func checkForPermission() {
        
        Manager.recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try Manager.recordingSession.setCategory(AVAudioSession.Category.playAndRecord, options: .defaultToSpeaker)
            
            Manager.recordingSession.requestRecordPermission({ (allowed) in
                if allowed {
                    Manager.micAuthorised = true
                    //self.delegate?.enablePlayButton(flag: true)
                    print("Mic Authorised")
                } else {
                    Manager.micAuthorised = false
                    //self.delegate?.enablePlayButton(flag: false)
                    print("Mic not Authorised")
                    self.delegate?.showWarning()
                }
            })
        } catch {
            print("Failed to set Category", error.localizedDescription)
        }
    }

}
