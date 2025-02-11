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
    func skip()
}

class CommandCenter {
    
    weak var delegate : CommandCenterDelegate?
    
    static let shared = CommandCenter()
    let commandCenter = MPRemoteCommandCenter.shared()
    
    var elapsedTime: TimeInterval = 0
    var totalDuration: TimeInterval = 0

    private init() {

    }
    
    func addCommandCenter() {
        
        commandCenter.pauseCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            print("PAUSE")
            //self.updateTime(elapsedTime: self.elapsedTime, totalDuration: self.totalDuration)
            self.delegate?.startPlaying()
            return .success
        }
        commandCenter.playCommand.addTarget { [self] (_) -> MPRemoteCommandHandlerStatus in
            print("PLAY")
            //self.updateTime(elapsedTime: self.elapsedTime, totalDuration: self.totalDuration)
            self.delegate?.startPlaying()
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            print("BEGIN")
            self.delegate?.stopPlaying()
            self.commandCenter.previousTrackCommand.isEnabled = false
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            print("NEXT")
            self.delegate?.skip()
            return .success
        }
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
    }
    
    func displayElapsedTime() {
        //MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 20
        //updateTime(elapsedTime: 30, totalDuration: 40)
    }
    
    func enableSkipButtons(flag: Bool) {
        self.commandCenter.previousTrackCommand.isEnabled = flag
        self.commandCenter.nextTrackCommand.isEnabled = flag
        
        if !flag {
            updateTime(elapsedTime: 0, totalDuration: 0)
        }
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
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "FREE UR SPIRIT",
            MPMediaItemPropertyAlbumTitle: "Jaw Relaxation",
            MPMediaItemPropertyArtist: "Maren",
            MPMediaItemPropertyArtwork: mediaArtwork
        ]
    }
    
    func updateTime(elapsedTime: TimeInterval, totalDuration: TimeInterval) {
        
        self.elapsedTime = elapsedTime
        self.totalDuration = totalDuration
        
        let image = UIImage(named: "schmettering_1024")!
        let mediaArtwork = MPMediaItemArtwork(boundsSize: image.size) { (size: CGSize) -> UIImage in
            return image
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "FREE UR SPIRIT",
            MPMediaItemPropertyAlbumTitle: "Jaw Relaxation",
            MPMediaItemPropertyArtist: "Maren",
            MPMediaItemPropertyArtwork: mediaArtwork,
            MPMediaItemPropertyPlaybackDuration: totalDuration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsedTime
        ]
    }
}
