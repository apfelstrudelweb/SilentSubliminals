//
//  ShadowButton.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 15.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit

class ShadowButton: UIButton {

    override func layoutSubviews() {
        super.layoutSubviews()

        self.tintColor = PlayerControlColor.lightColor
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOffset = CGSize(width: 1, height: 1)
        self.layer.shadowRadius = 2
        self.layer.shadowOpacity = 0.3
    }

}



