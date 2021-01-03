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
    var size: Double = 2.0

    override func layoutSubviews() {
        super.layoutSubviews()

        if shadowLayer == nil {
            shadowLayer = CAShapeLayer()
            shadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath

            shadowLayer.shadowColor = UIColor.black.cgColor
            shadowLayer.shadowPath = shadowLayer.path
            shadowLayer.shadowOffset = CGSize(width: size, height: size)
            shadowLayer.shadowOpacity = opacity
            shadowLayer.shadowRadius = cornerRadius

            layer.insertSublayer(shadowLayer, at: 0)
            //layer.insertSublayer(shadowLayer, below: nil) // also works
        }
    }

}
