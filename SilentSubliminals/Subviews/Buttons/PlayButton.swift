//
//  PlayButton.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 26.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation

class PlayButton: ShadowButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()

        //self.setImage(Button.playOnImg, for: .normal)
    }
    
    func setState(active: Bool) {
        
        DispatchQueue.main.async {
            let image = active ? playOffImg : playOnImg
            self.setImage(image, for: .normal)
            self.tintColor = .white
        }
    }
    
    func setEnabled(flag: Bool) {
        
        DispatchQueue.main.async {
            self.isEnabled = flag
        }
    }
}
