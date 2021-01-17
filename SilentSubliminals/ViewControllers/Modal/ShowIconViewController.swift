//
//  ShowIconViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 09.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import AVFoundation

class ShowIconViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var loopDurationTitleLabel: UILabel!
    @IBOutlet weak var remainingTimeTitleLabel: UILabel!
    @IBOutlet weak var loopDurationValueLabel: UILabel!
    @IBOutlet weak var remainingTimeValueLabel: UILabel!
    @IBOutlet weak var loopCompletionTitleLabel: UILabel!
    @IBOutlet weak var loopCompletionImageView: UIImageView!
    @IBOutlet weak var loopCompletionTimeLabel: UILabel!
    
    var itemTitle: String?
    var icon: UIImage?
    
    var timer: Timer? = nil {
        willSet {
            timer?.invalidate()
        }
    }

    var stopTimer: Bool = false
    
    var availableTimeForLoop: TimeInterval = TimeInterval(UserDefaults.standard.integer(forKey: userDefaults_loopDuration))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let audioFile = try AVAudioFile(forReading: getFileFromSandbox(filename: spokenAffirmation))
            availableTimeForLoop -= audioFile.duration
        } catch {
            print("File read error", error)
        }

        titleLabel.text = itemTitle
        imageView.image = icon
        
        
        let loopTerminated: Bool = UserDefaults.standard.bool(forKey: userDefaults_loopTerminated)
        loopCompletionImageView.alpha = loopTerminated ? 1 : 0
        loopCompletionTimeLabel.alpha = loopTerminated ? 1 : 0
        loopCompletionTimeLabel.text = UserDefaults.standard.string(forKey: userDefaults_loopTerminationTime)
        
        loopDurationValueLabel.text = availableTimeForLoop.stringFromTimeInterval(showSeconds: true)
        remainingTimeValueLabel.text = loopDurationValueLabel.text
        
        remainingTimeValueLabel.text = loopTerminated ? TimeInterval(0).stringFromTimeInterval(showSeconds: true) : availableTimeForLoop.stringFromTimeInterval(showSeconds: true)
        
        stopTimer = false
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
        timer?.fire()
    }
    @IBAction func closeButtonTouched(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func runTimedCode() {
        
        if PlayerStateMachine.shared.playerState == .affirmationLoop {
            setRemainingTime()
        }
        if PlayerStateMachine.shared.playerState == .consolidation {
            loopCompletionImageView.alpha = 1
            loopCompletionTimeLabel.alpha = 1
            
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "d.MM.y - HH:mm"
            let dateString = formatter.string(from: now)
            loopCompletionTimeLabel.text = dateString
            
            UserDefaults.standard.setValue(true, forKey: userDefaults_loopTerminated)
            UserDefaults.standard.setValue(dateString, forKey: userDefaults_loopTerminationTime)
            
            stopTimer = true
            timer = nil
        }
    }
    
    func setRemainingTime() {
        DispatchQueue.main.async {
            let remainingTime: TimeInterval = self.availableTimeForLoop - CommandCenter.shared.elapsedTime
            self.remainingTimeValueLabel.text = remainingTime.stringFromTimeInterval(showSeconds: true)
        }
    }
    
    deinit {
        stopTimer = true
        timer = nil
    }
}
