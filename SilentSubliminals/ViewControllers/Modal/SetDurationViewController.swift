//
//  SetDurationViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 19.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit

protocol TimerDelegate : AnyObject {
    
    func timeIntervalChanged(time: TimeInterval)
    func stopTimeChanged(date: Date)
}

class SetDurationViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timerPicker: UIDatePicker!
    @IBOutlet var activeTimeView: UIView!
    
    weak var delegate : TimerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.textColor = PlayerControlColor.lightColor
        
        timerPicker.setValue(PlayerControlColor.lightColor, forKeyPath: "textColor")
        timerPicker.setValue(true, forKey: "highlightsToday")
        activeTimeView.backgroundColor = PlayerControlColor.darkGrayColor.withAlphaComponent(0.75)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // we need it, otherwise datepicker's valuechanged does not update the first spin
        self.timerPicker.countDownDuration = 5 * 60
    }

    @IBAction func timePickerValueChanged(_ sender: Any) {
        
        print(timerPicker.countDownDuration)
        TimerManager.shared.countdownSet = true
        TimerManager.shared.remainingTime = timerPicker.countDownDuration
        delegate?.timeIntervalChanged(time: timerPicker.countDownDuration)
    }
    
}
