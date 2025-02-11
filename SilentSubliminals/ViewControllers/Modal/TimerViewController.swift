//
//  TimerViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 19.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit

class TimerViewController: UIViewController, TimerDelegate {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var endtimeContainerView: UIView!
    @IBOutlet weak var durationContainerView: UIView!
 
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var durationLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setTitleColor(lightColor, for: .normal)
        durationLabel.textColor = lightColor
        
        segmentedControl.backgroundColor = darkGrayColor
        segmentedControl.selectedSegmentTintColor = lightColor
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: darkGrayColor], for: UIControl.State.selected)
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: lightGrayColor], for: UIControl.State.normal)
        
        setActiveView()
        
        self.durationLabel.text = TimerManager.shared.remainingTime?.stringFromTimeInterval()
    }
    
    fileprivate func setActiveView() {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            NotificationCenter.default.post(name: Notification.Name(notification_durationViewControllerCalled), object: nil)
            endtimeContainerView.isHidden = false
            durationContainerView.isHidden = true
        case 1:
            NotificationCenter.default.post(name: Notification.Name(notification_endtimeViewControllerCalled), object: nil)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination
        
        if vc.isKind(of: SetDurationViewController.self) {
            let vc1 = vc as! SetDurationViewController
            vc1.delegate = self
        } else if vc.isKind(of: SetEndtimeViewController.self) {
            let vc1 = vc as! SetEndtimeViewController
            vc1.delegate = self
        }
    }
    
    func timeIntervalChanged(time: TimeInterval) {
        //self.durationLabel.text = time.stringFromTimeInterval()
        self.durationLabel.text = TimerManager.shared.remainingTime?.stringFromTimeInterval()
    }
}


extension TimeInterval {

        func stringFromTimeInterval() -> String {

            let time = NSInteger(self)

            let minutes = (time / 60) % 60
            let hours = (time / 3600)

            return String(format: "%0.2dh %0.2dm",hours,minutes)
        }
    }
