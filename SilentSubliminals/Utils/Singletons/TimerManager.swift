//
//  TimerManager.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 20.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import AVFoundation

class TimerManager {
    
    static let shared = TimerManager()
    
    var remainingTime: TimeInterval?
    var singleAffirmationDuration: TimeInterval?
    
    func reset() {
        remainingTime = defaultAffirmationTime
        
        do {
            let audioFile = try AVAudioFile(forReading: getFileFromSandbox(filename: spokenAffirmation))
            singleAffirmationDuration = audioFile.duration
        } catch {
            print("File read error", error)
        }
    }

    private init() {
        reset()
    } 
}
