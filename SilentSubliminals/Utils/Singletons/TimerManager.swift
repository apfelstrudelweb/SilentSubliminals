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
    
    var remainingTime: TimeInterval?
  
    private init() {
        remainingTime = 5 * 60
    } 
}
