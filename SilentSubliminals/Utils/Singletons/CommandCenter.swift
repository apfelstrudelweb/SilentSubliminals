//
//  CommandCenter.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 25.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import MediaPlayer
import AVFoundation

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
    var elapsedTimeForPlaylist: TimeInterval = 0
    
    var elapsedTimeForLoudSubliminal: TimeInterval = 0
    var elapsedTimeForSilentSubliminal: TimeInterval = 0
    var totalDuration: TimeInterval = 0
    
    var node: AVAudioPlayerNode?
    var audioFile: AVAudioFile?
    
    var itemTitle: String?
    var itemIcon: UIImage?
    
    var nowPlayingInfo = [String: Any]()
    
    private init() {
        
    }
    
    func addCommandCenter() {
        
        commandCenter.pauseCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            print("PAUSE")
            //self.updateTime(elapsedTime: self.elapsedTime, totalDuration: self.totalDuration)
            self.delegate?.startPlaying()
            self.commandCenter.nextTrackCommand.isEnabled = false
            return .success
        }
        commandCenter.playCommand.addTarget { [self] (_) -> MPRemoteCommandHandlerStatus in
            print("PLAY")
            //self.updateTime(elapsedTime: self.elapsedTime, totalDuration: self.totalDuration)
            self.delegate?.startPlaying()
            self.commandCenter.nextTrackCommand.isEnabled = true

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
        
        commandCenter.changePlaybackPositionCommand.isEnabled = true
//        commandCenter.changePlaybackPositionCommand.addTarget { event in
//            if let event = event as? MPChangePlaybackPositionCommandEvent {
//                let time = CMTime(seconds: event.positionTime, preferredTimescale: CMTimeScale(1000))
//                print(time)
//
//                //let nodetime: AVAudioTime  = (self.node?.lastRenderTime)!
//                //let playerTime: AVAudioTime = (self.node?.playerTime(forNodeTime: nodetime))!
//                let sampleRate = self.node?.outputFormat(forBus: 0).sampleRate
//                let length = Int(self.totalDuration) - Int(time.seconds)
//                let frameCount = AVAudioFrameCount(Float(sampleRate!) * Float(length))
//
//                let startingFrame = AVAudioFramePosition(sampleRate! * Double(time.seconds))
//
//                self.node?.stop()
//                self.node!.scheduleSegment(self.audioFile!, startingFrame: startingFrame, frameCount: frameCount, at: nil, completionHandler: nil)
//
//                self.updateTime(elapsedTime: time.seconds, totalDuration: self.totalDuration)
//
//                self.node?.play()
//            }
//            return .success
//        }
    }
    
    func displayElapsedTime() {
        //MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 20
        //updateTime(elapsedTime: 30, totalDuration: 40)
    }
    
    func enableForwardButton(flag: Bool) {
        self.commandCenter.nextTrackCommand.isEnabled = flag
    }
    
    func enableBackButton(flag: Bool) {
        self.commandCenter.previousTrackCommand.isEnabled = flag
    }
    
    func removeCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = false
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
    }
    
    func updateLockScreenInfo() {
         
        if let title = itemTitle {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = title
        }
        if let image = itemIcon {
            let mediaArtwork = MPMediaItemArtwork(boundsSize: image.size) { (size: CGSize) -> UIImage in
                return image
            }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = mediaArtwork
        }

        let bundleInfoDict: NSDictionary = Bundle.main.infoDictionary! as NSDictionary
        let appName = bundleInfoDict["CFBundleName"] as! String
        nowPlayingInfo[MPMediaItemPropertyTitle] = appName
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func updateTitleAndIcon() {
        
        let soundfile = getCurrentSubliminal()
        
        if let title = soundfile?.title {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = title
        }
        if let imageData = soundfile?.icon, let image = UIImage(data: imageData) {
            let mediaArtwork = MPMediaItemArtwork(boundsSize: image.size) { (size: CGSize) -> UIImage in
                return image
            }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = mediaArtwork
        }

        let bundleInfoDict: NSDictionary = Bundle.main.infoDictionary! as NSDictionary
        let appName = bundleInfoDict["CFBundleName"] as! String
        nowPlayingInfo[MPMediaItemPropertyTitle] = appName
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func updateTime(elapsedTime: TimeInterval, totalDuration: TimeInterval) {
        
        self.elapsedTime = elapsedTime
        self.totalDuration = totalDuration
        
        if PlayerStateMachine.shared.playerState == .subliminal {
            CommandCenter.shared.elapsedTimeForLoudSubliminal = elapsedTime
        } else if PlayerStateMachine.shared.playerState == .silentSubliminal  {
            CommandCenter.shared.elapsedTimeForSilentSubliminal = elapsedTime
        }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = totalDuration
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
