//
//  TimerManager.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 20.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation


class TimerManager {
    
    static let shared = TimerManager()
    
    var countdownSet: Bool?
    var remainingTime: TimeInterval?
    var stopTime: Date?
  
    private init() {
        countdownSet = true
        remainingTime = 5 * 60
        stopTime = Date().addingTimeInterval(60 * 60)
    } 
}
