//
//  Switch.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 24.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit

class Switch: UISwitch {

    override func layoutSubviews() {
        super.layoutSubviews()

        self.tintColor = PlayerControlColor.darkGrayColor
        //self.onTintColor = PlayerControlColor.lightColor
        self.backgroundColor = PlayerControlColor.lightGrayColor
        self.layer.cornerRadius = frame.height / 2.0
        
        DispatchQueue.main.async {
            self.isOn = !UserDefaults.standard.bool(forKey: userDefaults_introductionPlayed)
        }
    }
    
    func setEnabled(flag: Bool) {
        
        DispatchQueue.main.async {
            self.isEnabled = flag
        }
    }

}
