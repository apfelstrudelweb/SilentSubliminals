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
            
            switch self {
            case .ready:
                return .intro
            case .intro:
                return .affirmation
            case .affirmation:
                return .affirmationLoop
            case .affirmationLoop:
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

    enum AffirmationState {
        case loud
        case silent
        var nextState : AffirmationState {
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
    var pauseState : PauseState = .play {
        didSet {
            delegate?.performAction()
        }
    }

    var introState : IntroState = .none {
        willSet {
            delegate?.updateIntroButtons()
        }
        didSet {
            delegate?.updateIntroButtons()
        }
    }

    var outroState : OutroState = .none {
        didSet {
            delegate?.updateOutroButtons()
        }
    }

    var affirmationState : AffirmationState = .loud {
        didSet {
            delegate?.toggleSilentMode()
        }
    }

    func doNextState() {
        playerState = self.playerState.nextState
    }
    
    func toggleAffirmationState() {
        affirmationState = self.affirmationState.nextState
    }

    func toggleState() {
        pauseState = pauseState.nextState
    }
}



//enum PlayerEvent: EventType {
//    case playButtonTapped
//    case pauseButtonTapped
//    case rewindButtonTapped
//    case forwardButtonTapped
//    case timerButtonTapped
//    case silentButtonTapped
//    case loudButtonTapped
//    case introChairButtonTapped
//    case introBedButtonTapped
//    case introNoneButtonTapped
//    case outroDayButtonTapped
//    case outroNightButtonTapped
//    case outroNoneButtonTapped
//}
