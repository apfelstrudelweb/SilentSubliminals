//
//  TimerViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 19.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit

class TimerViewController: UIViewController {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var endtimeContainerView: UIView!
    @IBOutlet weak var durationContainerView: UIView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        segmentedControl.backgroundColor = PlayerControlColor.darkGrayColor
        segmentedControl.selectedSegmentTintColor = PlayerControlColor.lightColor
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: PlayerControlColor.darkGrayColor], for: UIControl.State.selected)
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: PlayerControlColor.lightGrayColor], for: UIControl.State.normal)
        
        setActiveView()
    }
    
    fileprivate func setActiveView() {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            endtimeContainerView.isHidden = false
            durationContainerView.isHidden = true
        case 1:
            endtimeContainerView.isHidden = true
            durationContainerView.isHidden = false
        default:
            break
        }
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: Any) {
        
        setActiveView()
    }
    
    @IBAction func closeButtonTouched(_ sender: Any) {
        self.dismiss(animated: true) {
            
        }
    }
    
}
