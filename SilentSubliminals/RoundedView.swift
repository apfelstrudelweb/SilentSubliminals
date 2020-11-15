//
//  RoundedView.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 15.11.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit

class RoundedView: UIView {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = cornerRadius
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.addBlurEffect(frame: self.globalFrame!)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }

}

extension UIView {
    
    var globalFrame: CGRect? {
        let rootView = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.view
        return self.superview?.convert(self.frame, to: rootView)
    }
    
    func addBlurEffect(frame: CGRect) {
        let imageView: UIImageView = self.superview?.superview?.superview?.subviews.filter{$0 is UIImageView}.first as! UIImageView
        imageView.makeBlurImage(targetImageView:imageView, frame: frame)
    }
}

extension UIImageView {
    
    func makeBlurImage(targetImageView:UIImageView?, frame: CGRect) {
        let blurEffect = UIBlurEffect(style: .light)
        //let blurEffectView = PSORoundedVisualEffectView(effect: blurEffect)
        let blurEffectView = CustomIntensityVisualEffectView(effect: blurEffect, intensity: 0.5)
        blurEffectView.frame = frame
        blurEffectView.layer.cornerRadius = cornerRadius
        blurEffectView.alpha = 1

        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight] // for supporting device rotation
        targetImageView?.addSubview(blurEffectView)
        targetImageView?.layer.cornerRadius = cornerRadius
    }
}

class CustomIntensityVisualEffectView: UIVisualEffectView {

    /// Create visual effect view with given effect and its intensity
    ///
    /// - Parameters:
    ///   - effect: visual effect, eg UIBlurEffect(style: .dark)
    ///   - intensity: custom intensity from 0.0 (no effect) to 1.0 (full effect) using linear scale
    init(effect: UIVisualEffect, intensity: CGFloat) {
        super.init(effect: nil)
        animator = UIViewPropertyAnimator(duration: 1, curve: .linear) { [unowned self] in self.effect = effect }
        animator.fractionComplete = intensity
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateMaskLayer()
        //self.backgroundColor = .lightGray
    }

    func updateMaskLayer(){
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: cornerRadius).cgPath
        self.layer.mask = shapeLayer
    }

    // MARK: Private
    private var animator: UIViewPropertyAnimator!

}
