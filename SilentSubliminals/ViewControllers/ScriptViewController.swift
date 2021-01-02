//
//  ScriptViewController.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 18.10.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit

class ScriptViewController: UIViewController {
    

    var affirmation: Affirmation? {
        didSet {
            titleLabel.text = affirmation?.title
            imageView.image = affirmation?.image
            textView.text = affirmation?.text
        }
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var buttonView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textView.layer.cornerRadius = cornerRadius
        buttonView.layer.cornerRadius = cornerRadius
        
        imageView.layer.cornerRadius = cornerRadius
        imageView.clipsToBounds = true
        
        if UIDevice.current.userInterfaceIdiom == .phone {
           textView.textContainerInset = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)
        } else {
           textView.textContainerInset = UIEdgeInsets(top: 40, left: 20, bottom: 40, right: 20)
        }
        
        
        textView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        buttonView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }

}

class Affirmation {
    var title: String?
    var text: String?
    var image: UIImage?
}
