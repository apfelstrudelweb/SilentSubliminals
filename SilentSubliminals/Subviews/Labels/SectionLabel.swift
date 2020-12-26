//
//  SectionLabel.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 24.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit

class SectionLabel: UILabel {

    override func layoutSubviews() {
        super.layoutSubviews()

        self.textColor = PlayerControlColor.darkGrayColor
    }
}
