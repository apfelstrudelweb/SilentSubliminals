//
//  TimerButton.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 29.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation

class TimerButton: SymbolButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func setEnabled(flag: Bool) {
        
        DispatchQueue.main.async {
            self.isEnabled = flag
        }
    }
}
