//
//  AddAffirmationViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 03.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit

protocol AddAffirmationTextDelegate : AnyObject {

    func addAffirmation(text: String)
}

class AddAffirmationViewController: UIViewController {

    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textviewBottomSpace: NSLayoutConstraint!
    
    weak var delegate : AddAffirmationTextDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.layer.cornerRadius = cornerRadius
        textView.clipsToBounds = true
        textView.contentInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        textView.placeholder = "Your affirmation goes here ..."
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handle(keyboardShowNotification:)),
                                               name: UIResponder.keyboardDidShowNotification,
                                               object: nil)
    }
    
    
    @IBAction func doneButtonTouched(_ sender: Any) {
        delegate?.addAffirmation(text: textView.text)
        self.dismiss(animated: true, completion: nil)
    }
    

    @objc
    private func handle(keyboardShowNotification notification: Notification) {
        if let userInfo = notification.userInfo, let keyboardRectangle = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            print(keyboardRectangle.height)
            textviewBottomSpace.constant = keyboardRectangle.height
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}


extension UITextView: UITextViewDelegate {
    
    /// Resize the placeholder when the UITextView bounds change
    override open var bounds: CGRect {
        didSet {
            self.resizePlaceholder()
        }
    }
    
    /// The UITextView placeholder text
    public var placeholder: String? {
        get {
            var placeholderText: String?
            
            if let placeholderLabel = self.viewWithTag(100) as? UILabel {
                placeholderText = placeholderLabel.text
            }
            
            return placeholderText
        }
        set {
            if let placeholderLabel = self.viewWithTag(100) as! UILabel? {
                placeholderLabel.text = newValue
                placeholderLabel.sizeToFit()
            } else {
                self.addPlaceholder(newValue!)
            }
        }
    }
    
    /// When the UITextView did change, show or hide the label based on if the UITextView is empty or not
    ///
    /// - Parameter textView: The UITextView that got updated
    public func textViewDidChange(_ textView: UITextView) {
        if let placeholderLabel = self.viewWithTag(100) as? UILabel {
            placeholderLabel.isHidden = !self.text.isEmpty
        }
    }
    
    /// Resize the placeholder UILabel to make sure it's in the same position as the UITextView text
    private func resizePlaceholder() {
        if let placeholderLabel = self.viewWithTag(100) as! UILabel? {
            let labelX = self.contentInset.left
            let labelY = self.contentInset.top
            let labelWidth = self.frame.width - (labelX * 2)
            let labelHeight = placeholderLabel.frame.height

            placeholderLabel.frame = CGRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight)
        }
    }
    
    /// Adds a placeholder UILabel to this UITextView
    private func addPlaceholder(_ placeholderText: String) {
        let placeholderLabel = UILabel()
        
        placeholderLabel.text = placeholderText
        placeholderLabel.sizeToFit()
        
        placeholderLabel.font = self.font
        placeholderLabel.textColor = UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1.0)
        placeholderLabel.tag = 100
        
        placeholderLabel.isHidden = !self.text.isEmpty
        
        self.addSubview(placeholderLabel)
        self.resizePlaceholder()
        self.delegate = self
    }
    
}
