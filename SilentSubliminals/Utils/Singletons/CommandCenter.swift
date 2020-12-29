//
//  CommandCenter.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 25.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import MediaPlayer

protocol CommandCenterDelegate : AnyObject {
    
    func pausePlaying()
    func startPlaying()
    func stopPlaying()
}

class CommandCenter {
    
    weak var delegate : CommandCenterDelegate?
    
    static let shared = CommandCenter()
    
    let commandCenter = MPRemoteCommandCenter.shared()

  
    private init() {

    }
    
    func addCommandCenter() {
        
        commandCenter.pauseCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            print("PAUSE")
            self.delegate?.startPlaying()
            return .success
        }
        commandCenter.playCommand.addTarget { [self] (_) -> MPRemoteCommandHandlerStatus in
            print("PLAY")
            self.delegate?.startPlaying()
            self.commandCenter.previousTrackCommand.isEnabled = true
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            print("BEGIN")
            self.delegate?.stopPlaying()
            self.commandCenter.previousTrackCommand.isEnabled = false
            return .success
        }
        commandCenter.skipForwardCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            print("NEXT")
            // TODO: next affirmation
            return .success
        }
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
    }

    func removeCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = false
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
    }
    
   func updateLockScreenInfo() {
        
        //let totalDuration = introDuration + (affirmationLoopDuration ?? 5 * 60) + outroDuration
        let image = UIImage(named: "schmettering_1024")!
        let mediaArtwork = MPMediaItemArtwork(boundsSize: image.size) { (size: CGSize) -> UIImage in
            return image
        }
        
        print("updateLockScreenInfo")
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "FREE UR SPIRIT",
            MPMediaItemPropertyAlbumTitle: "Jaw Relaxation",
            MPMediaItemPropertyArtist: "Maren",
            //MPMediaItemPropertyPlaybackDuration: totalDuration,
            //MPNowPlayingInfoPropertyElapsedPlaybackTime: self.elapsedTime,
            MPMediaItemPropertyArtwork: mediaArtwork
        ]
    }
}
