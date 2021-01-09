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

        titleLabel.textColor = lightColor
        timerPicker.preferredDatePickerStyle = .wheels
        timerPicker.setValue(lightColor, forKeyPath: "textColor")
        timerPicker.setValue(true, forKey: "highlightsToday")
        activeTimeView.backgroundColor = darkGrayColor.withAlphaComponent(0.75)
        
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
        self.timerPicker.date += TimeInterval(UserDefaults.standard.integer(forKey: userDefaults_loopDuration))
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
        
        UserDefaults.standard.setValue(Int(duration), forKey: userDefaults_loopDuration)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
