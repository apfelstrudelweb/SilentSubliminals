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
        
        guard let sandboxFileLoud = self.filenameLoud, let sandboxFileSilent = self.filenameSilent else {
            print("************** Fatal Error: no sandbox file for \(String(describing: self.title)) *****************")
            return
        }
        
        do {
            self.audioFileLoud = try AVAudioFile(forReading: getFileFromSandbox(filename: sandboxFileLoud))
            self.audioFileSilent = try AVAudioFile(forReading: getFileFromSandbox(filename: sandboxFileSilent))
            self.duration = self.audioFileLoud?.duration
            self.exists = self.audioFileLoud != nil
        } catch {
            print("File read error", error)
        }
    }
    
}
