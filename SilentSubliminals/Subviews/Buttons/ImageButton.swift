//
//  ImageButton.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 05.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import UIKit

class ImageButton: UIButton {
    
    var isOverriden: Bool = false

    override func layoutSubviews() {
        super.layoutSubviews()

    }
    
    func setImage(name: String) {
        setImage(UIImage(named: name), for: .normal)
    }
    
//    override func setImage(_ image: UIImage?, for state: UIControl.State) {
//        super.setImage(image, for: state)
//        //imageName = "photo roll" // TODO
//    }
}
