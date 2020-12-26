//
//  StateMachine.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 21.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation

protocol StateMachineDelegate : AnyObject {
    
    func performAction()
    func updateIntroButtons()
    func updateOutroButtons()
    func toggleSilentMode()
    func pauseSound()
    func continueSound()
}

enum Induction {
    case Intro
    case Outro
}

class StateMachine {
    
    weak var delegate : StateMachineDelegate?
    
    static let shared = StateMachine()

    private init() {

    }
    
    enum PlayerState {
        
        case ready
        case intro
        case affirmation
        case affirmationLoop
        case outro
        
        var nextState : PlayerState {
            
            shared.setLoudMode()
            
            switch self {
            case .ready:
                if shared.introState == .none {
                    return .affirmation
                }
                return .intro
            case .intro:
                return .affirmation
            case .affirmation:
                shared.setSilentMode()
                return .affirmationLoop
            case .affirmationLoop:
                if shared.outroState == .none {
                    return .ready
                }
                return .outro
            case .outro:
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
                return .pause
            case .pause:
                return .play
            }
        }
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

    // MARK: State Handling
    var playerState : PlayerState = .ready {
        didSet {
            delegate?.performAction()
            delegate?.updateIntroButtons()
            delegate?.updateOutroButtons()
        }
    }
    var pauseState : PauseState = .pause {
        didSet {
            //delegate?.performAction()
            if pauseState == .pause {
                delegate?.pauseSound()
            } else {
                delegate?.continueSound()
            }
            
        }
    }

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
        playerState = self.playerState.nextState
    }
    
    func startPlayer() {
        if playerState == .ready {
            doNextPlayerState()
        }
    }
    
    func toggleFrequencyState() {
        if playerState == .affirmationLoop {
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
