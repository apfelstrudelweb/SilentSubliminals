//
//  MakerStateMachine.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 27.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation

protocol MakerStateMachineDelegate : AnyObject {
    
    func performRecorderAction()
    func performPlayerAction()
}

class MakerStateMachine {
    
    weak var delegate : MakerStateMachineDelegate?
    
    static let shared = MakerStateMachine()
    
    private init() {
        
    }
    
    enum PlayerState {
        
        case play
        case playStopped
        
        var nextState : PlayerState {

            switch self {
            case .play:
                return .playStopped
            case .playStopped:
                return .play
            }
        }
    }
    
    enum RecorderState {
        
        case record
        case recordStopped
        
        var nextState : RecorderState {

            switch self {
  
            case .record:
                return .recordStopped
            case .recordStopped:
                return .record
            }
        }
    }

    var playerState : PlayerState = .playStopped {
        didSet {
            delegate?.performPlayerAction()
        }
    }
    
    func doNextPlayerState() {
        playerState = self.playerState.nextState
    }
    

    func stopPlayer() {
        playerState = .playStopped
    }
    
    var recorderState : RecorderState = .recordStopped {
        didSet {
            delegate?.performRecorderAction()
        }
    }
    
    func doNextRecorderState() {
        recorderState = self.recorderState.nextState
    }
}
