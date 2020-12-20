//
//  ShadowLabel.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 17.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit

class ShadowLabel: UILabel {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 1.0
        self.layer.shadowOpacity = 0.3
        self.layer.shadowOffset = CGSize(width: 1, height: 1)
    }
    
}
