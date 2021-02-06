//
//  Subliminal.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 06.02.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import CoreData
import AVFoundation


class Soundfile: NSObject {
    
    var item: LibraryItem?
    var order: Int?
    
    var title: String?
    var icon: Data?
    var duration: TimeInterval?
    
    var filenameLoud: String?
    var filenameSilent: String?
    
    var audioFileLoud: AVAudioFile?
    var audioFileSilent: AVAudioFile?
    
    var exists: Bool = false
    
    
    required init(item: LibraryItem) {
        
        self.item = item

        self.title = item.title
        self.icon = item.icon
        guard let fileName = item.soundFileName else { return }
        
        self.filenameLoud = String(format: audioTemplate, fileName)
        self.filenameSilent = String(format: audioSilentTemplate, fileName)
        
        guard let filenameLoud = self.filenameLoud, let filenameSilent = self.filenameSilent else { return }
        
        let sandboxFileLoud = getFileFromSandbox(filename: filenameLoud)
        let sandboxFileSilent = getFileFromSandbox(filename: filenameSilent)
        
        do {
            self.audioFileLoud = try AVAudioFile(forReading: sandboxFileLoud)
            self.audioFileSilent = try AVAudioFile(forReading: sandboxFileSilent)
            self.duration = self.audioFileLoud?.duration
            self.exists = self.audioFileLoud != nil
        } catch {
            print("File read error", error)
            
            do {
                
//                let settings = [
//                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
//                    AVSampleRateKey: 44100, //48000,
//                    AVNumberOfChannelsKey: 2,
//                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
//                ] as [String : Any]
                
                //self.audioFileLoud = try AVAudioFile(forWriting: sandboxFileLoud, settings: [:])
                //self.audioFileSilent = try AVAudioFile(forWriting: getFileFromSandbox(filename: sandboxFileSilent), settings: [:])
            }  catch {
                print("File write error", error)
            }
            
        }
    }
      
}
