//
//  PulseImageView.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 30.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit

@IBDesignable
final class PulseImageView: UIImageView {
    
    let animationKey = "growingAnimation"
    
    @IBInspectable var symbolAlias: Int = LeadInLeadOutSymbols.chair.rawValue
    
    override func layoutSubviews() {
        super.layoutSubviews()

        self.tintColor = lightColor
    }
    
    func animate() {
        
        DispatchQueue.main.async {
            
            if PlayerStateMachine.shared.introState == .chair && self.symbolAlias == LeadInLeadOutSymbols.chair.rawValue {
                self.layer.add(getLayerAnimation(), forKey: self.animationKey)
            } else if PlayerStateMachine.shared.introState == .bed && self.symbolAlias == LeadInLeadOutSymbols.bed.rawValue {
                self.layer.add(getLayerAnimation(), forKey: self.animationKey)
            } else if PlayerStateMachine.shared.outroState == .day && self.symbolAlias == LeadInLeadOutSymbols.day.rawValue {
                self.layer.add(getLayerAnimation(), forKey: self.animationKey)
            } else if PlayerStateMachine.shared.outroState == .night && self.symbolAlias == LeadInLeadOutSymbols.night.rawValue {
                self.layer.add(getLayerAnimation(), forKey: self.animationKey)
            } else if PlayerStateMachine.shared.introductionState == .some && self.symbolAlias == LeadInLeadOutSymbols.introduction.rawValue {
                self.layer.add(getLayerAnimation(), forKey: self.animationKey)
            }
        }
    }
    
    func stopAnimation() {
        
        DispatchQueue.main.async {
            self.layer.removeAllAnimations()
        }
        
    }

}
