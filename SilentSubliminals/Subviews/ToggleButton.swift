//
//  ToggleButton.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 23.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit

class ToggleButton: UIButton {

    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func setState(active: Bool) {
        self.backgroundColor = active ? PlayerControlColor.lightColor : PlayerControlColor.lightGrayColor
        self.tintColor = active ? PlayerControlColor.darkGrayColor : PlayerControlColor.lightColor
    }

}
