//
//  LoudspeakerSymbolView.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 31.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation

class LoudspeakerSymbolView: SymbolImageView {
    
    var timer: Timer? = nil {
        willSet {
            timer?.invalidate()
        }
    }
    var index = 0
    var stopTimer: Bool = false

    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    @objc func runTimedCode() {
        self.tintColor = index % 2 == 0 ? .red : .clear
        index += 1
        if index == UInt8.max {
            index = 0
        }
    }
    
    func showExceedWarning(flag: Bool) {
        if flag == true {
            index = 0
            stopTimer = false
            timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
            timer?.fire()
        } else {
            if index > 4 {
                timer = nil
                index = 0
                self.tintColor = PlayerControlColor.darkGrayColor
            }
        }
    }

}
