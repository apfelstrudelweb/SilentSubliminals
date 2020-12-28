//
//  SetEndtimeViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 19.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit

class SetEndtimeViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timerPicker: UIDatePicker!
    @IBOutlet weak var activeTimeView: UIView!
    
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
        self.timerPicker.date = Date()
    }
    
    @IBAction func timePickerValueChanged(_ sender: Any) {
        print(timerPicker.date)

        var duration = timerPicker.date.timeIntervalSinceNow
        if duration < 0 {
            duration += 86400
        }
        TimerManager.shared.remainingTime = duration
        delegate?.timeIntervalChanged(time: duration)
    }
}
