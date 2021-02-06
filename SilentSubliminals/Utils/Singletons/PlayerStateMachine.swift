//
//  StateMachine.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 21.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import UIKit

protocol PlayerStateMachineDelegate : AnyObject {
    
    func performAction()
    func updateIntroButtons()
    func updateOutroButtons()
    func toggleSilentMode()
    func pauseSound()
    func continueSound()
    func terminateSound()
    
    func subliminalDidUpdate()
}

//extension PlayerStateMachineDelegate {
//
//    func updateIntroButtons() { }
//    func updateOutroButtons() { }
//    func toggleSilentMode() { }
//    func pauseSound() { }
//    func continueSound() { }
//    func terminateSound() { }
//}

enum Induction {
    case Introduction
    case LeadInChair
    case LeadInBed
    case LeadOutDay
    case LeadOutNight
    case Bell
}

class PlayerStateMachine {
    
    weak var delegate : PlayerStateMachineDelegate?
    
    static let shared = PlayerStateMachine()
    
    private init() {
        // background thread in AudioHelper
        //NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveData(_:)), name: Notification.Name(notification_player_nextState), object: nil)
    }
    
    @objc func onDidReceiveData(_ notification:Notification) {
        if notification.name.rawValue == notification_player_nextState {
            doNextPlayerState()
        }
    }
    
    
    enum PlayerState {
        
        case ready
        case introduction
        case leadIn
        case subliminal
        case silentSubliminal
        case consolidation
        case leadOut
        
        var nextState : PlayerState {
            
            shared.setLoudMode()
            
            switch self {
            case .ready:
                return shared.introductionState == .some ? .introduction : .leadIn
            case .introduction:
                return .leadIn
            case .leadIn:
                return .subliminal
            case .subliminal:
                shared.setSilentMode()
                return .silentSubliminal
            case .silentSubliminal:
                // in the case we have to do with a playlist
                if let manager = shared.playlistManager {
                    if manager.playNextSubliminal() {
                        shared.delegate?.subliminalDidUpdate()
                        return .subliminal
                    }
                }
                //return .leadOut
                return .consolidation
            case .consolidation:
                return .leadOut
            case .leadOut:
                // reset played items
                if let manager = shared.playlistManager {
                    manager.reset()
                    if manager.playNextSubliminal() {
                        shared.delegate?.subliminalDidUpdate()
                    }
                }
                return .ready
            }
        }
    }
    
    enum PauseState {
        case play
        case pause
        var nextState : PauseState {
            switch self {
            case .play:
                if shared.playerState == .ready {
                    return .play
                }
                return .pause
            case .pause:
                return .play
            }
        }
    }
    
    enum IntroductionState {
        case none
        case some
    }
    
    enum IntroState {
        case chair
        case bed
        case none
    }
    
    enum OutroState {
        case day
        case night
        case none
    }
    
    enum FrequencyState {
        case loud
        case silent
        var nextState : FrequencyState {
            switch self {
            case .loud:
                return .silent
            case .silent:
                return .loud
            }
        }
    }
    
    // TODO
    var playlistManager : PlaylistManager?
    
    var playerState : PlayerState = .ready {
        didSet {
            //playlistManager?.nextSubliminal()
            //serialQueue.sync {
            delegate?.performAction()
            delegate?.updateIntroButtons()
            delegate?.updateOutroButtons()
            //}
        }
    }
    var pauseState : PauseState = .pause {
        didSet {
            if pauseState == .pause {
                delegate?.pauseSound()
            } else {
                if playerState != .ready {
                    delegate?.continueSound()
                }
            }
        }
    }
    
    var introductionState : IntroductionState = .none
    
    var introState : IntroState = .none {
        didSet {
            delegate?.updateIntroButtons()
        }
    }
    
    var outroState : OutroState = .none {
        didSet {
            delegate?.updateOutroButtons()
        }
    }
    
    var frequencyState : FrequencyState = .loud {
        didSet {
            delegate?.toggleSilentMode()
        }
    }
    
    func doNextPlayerState() {
        //serialQueue.sync {
        playerState = self.playerState.nextState
        //}
    }
    
    func repeatSubliminal() {
        playerState = .subliminal
    }
    
    func startPlayer() {
        if playerState == .ready {
            doNextPlayerState()
        }
    }
    
    func setIntroductionState(isOn: Bool) {
        introductionState = isOn ? .some : .none
    }
    
    func toggleFrequencyState() {
        if playerState == .silentSubliminal {
            frequencyState = self.frequencyState.nextState
        }
    }
    
    func setLoudMode() {
        frequencyState = .loud
    }
    
    func setSilentMode() {
        frequencyState = .silent
    }
    
    func togglePlayPauseState() {
        pauseState = pauseState.nextState
    }
}
