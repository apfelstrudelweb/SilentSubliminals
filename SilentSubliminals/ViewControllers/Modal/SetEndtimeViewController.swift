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
        self.timerPicker.date += TimeInterval(UserDefaults.standard.integer(forKey: userDefaults_subliminalLoopDuration))
    }
    
    @IBAction func timePickerValueChanged(_ sender: Any) {
        print(timerPicker.date)

        var endtime = timerPicker.date.timeIntervalSinceNow
        if endtime < 0 {
            endtime += dayInSeconds
        }
        
        guard let soundfile = getCurrentSubliminal(), let duration = soundfile.duration else { return }
        if endtime < 2 * duration {
            
            let durationString: String = duration.stringFromTimeInterval(showHours: false)

            let alert = UIAlertController(title: "Error", message: "Your subliminal is exactly \(durationString) long. You need at least set twice the time of this subliminal in order to play the silent part as well.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                self.timerPicker.date = Date()
                self.timerPicker.date += 2 * duration
            }))
            self.present(alert, animated: true)
        }
        
        let availableTime = timerPicker.date.timeIntervalSinceNow - Date().timeIntervalSinceNow
        
        UserDefaults.standard.setValue(Int(availableTime), forKey: userDefaults_subliminalLoopDuration)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
