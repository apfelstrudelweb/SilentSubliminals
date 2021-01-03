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
}

class SetDurationViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timerPicker: UIDatePicker!
    @IBOutlet var activeTimeView: UIView!
    
    weak var delegate : TimerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.textColor = PlayerControlColor.lightColor
        timerPicker.preferredDatePickerStyle = .wheels
        timerPicker.setValue(PlayerControlColor.lightColor, forKeyPath: "textColor")
        timerPicker.setValue(true, forKey: "highlightsToday")
        activeTimeView.backgroundColor = PlayerControlColor.darkGrayColor.withAlphaComponent(0.75)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveData(_:)), name: Notification.Name(notification_durationViewControllerCalled), object: nil)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // we need it, otherwise datepicker's valuechanged does not update the first spin
        self.timerPicker.countDownDuration = defaultAffirmationTime
        
        guard let singleAffirmationDuration = TimerManager.shared.singleAffirmationDuration else { return }
        if 2 * singleAffirmationDuration > defaultAffirmationTime {
            self.timerPicker.countDownDuration = 2 * singleAffirmationDuration
        } else {
            self.timerPicker.countDownDuration = TimerManager.shared.remainingTime ?? defaultAffirmationTime
        }
        
        //update()
    }
    
    @objc func onDidReceiveData(_ notification:Notification) {
        update()
    }
    
    func update() {
        timerPicker.countDownDuration = TimerManager.shared.remainingTime ?? defaultAffirmationTime
        delegate?.timeIntervalChanged(time: TimerManager.shared.remainingTime ?? defaultAffirmationTime)
    }

    @IBAction func timePickerValueChanged(_ sender: Any) {
        
        print(timerPicker.countDownDuration)
        
        guard let singleAffirmationDuration = TimerManager.shared.singleAffirmationDuration else { return }
        if timerPicker.countDownDuration < 2 * singleAffirmationDuration {
            
            let minutes: Int = Int(singleAffirmationDuration) / minuteInSeconds
            
            let alert = UIAlertController(title: "Error", message: "Your affirmation is about \(minutes) minutes long. You need at least set the double time of the affirmation in order to play the Silent Subliminal as well.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                self.timerPicker.countDownDuration = 2 * singleAffirmationDuration
            }))
            self.present(alert, animated: true)
        }
        
        TimerManager.shared.remainingTime = timerPicker.countDownDuration
        delegate?.timeIntervalChanged(time: timerPicker.countDownDuration)
    }
    
    deinit {
        print("Remove NotificationCenter Deinit")
        NotificationCenter.default.removeObserver(self)
    }
    
}
