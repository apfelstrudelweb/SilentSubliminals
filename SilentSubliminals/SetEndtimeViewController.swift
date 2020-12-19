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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.textColor = PlayerControlColor.lightColor
        timerPicker.setValue(PlayerControlColor.lightColor, forKeyPath: "textColor")
        timerPicker.setValue(true, forKey: "highlightsToday")
        activeTimeView.backgroundColor = PlayerControlColor.darkGrayColor.withAlphaComponent(0.75)
    }
    
    @IBAction func timePickerValueChanged(_ sender: Any) {
        print(timerPicker.date)
    }
    

}
