//
//  ScriptViewController.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 18.10.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit

class ScriptViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var buttonView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textView.layer.cornerRadius = cornerRadius
        buttonView.layer.cornerRadius = cornerRadius
        
        if UIDevice.current.userInterfaceIdiom == .phone {
           textView.textContainerInset = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)
        } else {
           textView.textContainerInset = UIEdgeInsets(top: 40, left: 20, bottom: 40, right: 20)
        }
        
        
        textView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        buttonView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }

}
