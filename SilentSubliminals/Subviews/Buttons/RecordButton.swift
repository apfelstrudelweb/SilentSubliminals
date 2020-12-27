//
//  RecordButton.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 27.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation

class RecordButton: ShadowButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()

        //self.setImage(Button.playOnImg, for: .normal)
    }
    
    func setState(active: Bool) {
        
        DispatchQueue.main.async {
            let image = active ? Button.micOffImg : Button.micOnImg
            self.setImage(image, for: .normal)
        }
    }
    
    func setEnabled(flag: Bool) {
        
        DispatchQueue.main.async {
            self.isEnabled = flag
        }
    }
}
