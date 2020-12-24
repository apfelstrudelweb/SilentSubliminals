//
//  VolumeViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 24.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit

class VolumeViewController: UIViewController {

    let maskView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .red

        let colors = [UIColor.blue, UIColor.green, UIColor.yellow, UIColor.red]
        self.maskView.backgroundColor = .white
        self.view.showGradientColors(colors)
        self.view.addSubview(self.maskView)
        self.view.mask = self.maskView
        self.maskView.frame = .zero//self.view.frame
    }
    
    func displayVolume(volume: Float) {
        
        let w = Double(self.view.frame.size.width)
        let h = Double(self.view.bounds.size.height)
        
        UIView.animate(withDuration: 0.2) {
            self.maskView.frame = CGRect(x: 0.0, y: 0.0, width: Double(5 * volume) * w, height: h)
        }
    }
    
}



extension UIView {
    
    enum GradientColorDirection {
        case vertical
        case horizontal
    }
    
    func showGradientColors(_ colors: [UIColor], opacity: Float = 0.8, direction: GradientColorDirection = .horizontal) {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.opacity = opacity
        gradientLayer.colors = colors.map { $0.cgColor }
        
        if case .horizontal = direction {
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.0)
        }
        
        gradientLayer.locations = [0.0, 0.2, 0.4, 0.6]
        
        gradientLayer.bounds = self.bounds
        gradientLayer.anchorPoint = CGPoint.zero
        gradientLayer.cornerRadius = self.layer.cornerRadius
        self.layer.addSublayer(gradientLayer)
    }
}
