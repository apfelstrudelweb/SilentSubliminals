//
//  ShadowView.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 18.10.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit

final class ShadowView: UIView {

    private var shadowLayer: CAShapeLayer!
    
    var opacity: Float = 0.8
    var size: Double = 4
    

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.shadowOpacity = opacity
        layer.shadowOffset = CGSize(width: size, height: size)
        layer.shadowRadius = cornerRadius
        layer.shadowColor = UIColor.black.cgColor
    }

}
