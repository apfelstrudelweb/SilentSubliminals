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
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveData(_:)), name: NSNotification.Name(notification_endtimeViewControllerCalled), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // we need it, otherwise datepicker's valuechanged does not update the first spin
        reset()
    }
    
    @objc func onDidReceiveData(_ notification:Notification) {
        reset()
    }
    
    func reset() {
        self.timerPicker.date = Date()
        
        guard let singleAffirmationDuration = TimerManager.shared.singleAffirmationDuration else { return }
        var duration = timerPicker.date.timeIntervalSinceNow
        
        if 2 * singleAffirmationDuration > timerPicker.date.timeIntervalSinceNow {
            
            duration += 2 * singleAffirmationDuration
            self.timerPicker.date += duration
        }
        
        TimerManager.shared.remainingTime = duration < 60 ? 60 : duration
        delegate?.timeIntervalChanged(time: duration)
    }
    
    @IBAction func timePickerValueChanged(_ sender: Any) {
        print(timerPicker.date)

        var duration = timerPicker.date.timeIntervalSinceNow
        if duration < 0 {
            duration += dayInSeconds
        }
        
        guard let singleAffirmationDuration = TimerManager.shared.singleAffirmationDuration else { return }
        if duration < 2 * singleAffirmationDuration {
            
            let minutes: Int = Int(singleAffirmationDuration) / minuteInSeconds
            
            let alert = UIAlertController(title: "Error", message: "Your affirmation is about \(minutes) minutes long. You need at least set the double time of the affirmation in order to play the Silent Subliminal as well.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                self.timerPicker.date = Date()
                self.timerPicker.date += 2 * singleAffirmationDuration
            }))
            self.present(alert, animated: true)
        }
        
        TimerManager.shared.remainingTime = duration
        delegate?.timeIntervalChanged(time: duration)
    }
    
    deinit {
        print("Remove NotificationCenter Deinit")
        NotificationCenter.default.removeObserver(self)
    }
}
