//
//  PlaylistManager.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 06.02.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import UIKit


//protocol PlaylistManagerDelegate : AnyObject {
//    func subliminalDidUpdate()
//}


class PlaylistManager {
    
    //weak var delegate : PlaylistManagerDelegate?

    var subliminals: NSOrderedSet?
    var playedSubliminals: Array<String>
    var currentSubliminal: Soundfile?
    
    var isPlaylist: Bool?
    

    init(subliminals: NSOrderedSet) {
        
        self.playedSubliminals = []
        self.subliminals = subliminals
        self.isPlaylist = subliminals.count > 0
    }
    
    func reset() {
        playedSubliminals = []
    }
    
    func getCurrentSubliminal() -> Soundfile? {
        
        // when we play the first item
        if currentSubliminal == nil {
            let _ = playNextSubliminal()
        }
        
        return currentSubliminal
    }
    
    func playNextSubliminal() -> Bool {
        
        if playedSubliminals.count == subliminals?.count {
            return false
        }
        
        for element in self.subliminals?.array ?? [] {
            let item = element as! LibraryItem
            let soundfile = Soundfile(item: item)

            guard let title = soundfile.title else { continue }

            if !playedSubliminals.contains(title) {
                currentSubliminal = soundfile
                playedSubliminals.append(title)
                
                if soundfile.exists {
                    CoreDataManager.sharedInstance.setNewTimestamp(item: item)
                }
                
                SelectionHandler().selectLibraryItem(item)
                CoreDataManager.sharedInstance.save()
                
                return true
            }
        }

        return false
    }
    
    
    func getUnrecordedSoundFileNames() -> Array<String> {
        
        var unrecordedSoundfileNames = Array<String>()
        
        for element in self.subliminals?.array ?? [] {
            let item = element as! LibraryItem
            let soundfile = Soundfile(item: item)
            
            guard let title = soundfile.title else { continue }
            
            if soundfile.audioFileLoud == nil || soundfile.audioFileSilent == nil {
                unrecordedSoundfileNames.append(title)
            }
        }
        
        return unrecordedSoundfileNames
    }
    
    
}
