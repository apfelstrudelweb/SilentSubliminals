//
//  VolumeSlider.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 24.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit

class VolumeSlider: UISlider {

    override func layoutSubviews() {
        super.layoutSubviews()

        self.tintColor = darkGrayColor
        self.thumbTintColor = lightColor
    }

}
