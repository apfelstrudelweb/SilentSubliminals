//
//  DisclaimerDetailView.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 01.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit

protocol DisclaimerDelegate : AnyObject {
    
    func close()
}

class DisclaimerDetailView: UIView {
    
    weak var delegate : DisclaimerDelegate?

    @IBOutlet var contentView: DisclaimerView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var agreeButton: UIButton!
    @IBOutlet weak var agreeLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var closeButton: UIButton!
    
    var agreementDone: Bool = false {
        didSet {
            closeButton.isEnabled = agreementDone
            closeButton.alpha = agreementDone ? 1 : 0.5
            
            let image = agreementDone ? UIImage(named: "checkboxOn") : UIImage(named: "checkboxOff")
            agreeButton.setImage(image, for: .normal)
        }
    }
    
 
    @IBAction func agreeButtonTouched(_ sender: Any) {
        
        agreementDone = !agreementDone
    }
    
    @IBAction func closeButtonTouched(_ sender: Any) {
        delegate?.close()
    }
    
    override init(frame: CGRect) {
          super.init(frame: frame)
          commonInit()
      }
      
      required init?(coder aDecoder: NSCoder) {
          super.init(coder: aDecoder)
          commonInit()
      }
      
      func commonInit() {
          Bundle.main.loadNibNamed("DisclaimerView", owner: self, options: nil)
          contentView.fixInView(self)
        
          closeButton.isEnabled = false
        closeButton.alpha = 0.5
      }
    
}


extension UIView {
    func fixInView(_ container: UIView!) -> Void{
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.frame = container.frame;
        container.addSubview(self);
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
}
