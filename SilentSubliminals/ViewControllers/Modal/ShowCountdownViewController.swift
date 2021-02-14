//
//  ShowIconViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 09.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import AVFoundation

class ShowCountdownViewController: UIViewController {
    
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
    
    var currentSubliminal: Soundfile?
    
    var timer: Timer? = nil {
        willSet {
            timer?.invalidate()
        }
    }

    var stopTimer: Bool = false
    var elapsedTime: TimeInterval = 0
    var lastDuration: TimeInterval = 0
    
    var availableTimeForLoop: TimeInterval = TimeInterval(UserDefaults.standard.integer(forKey: userDefaults_subliminalLoopDuration))
    var numberOfRepetitions = UserDefaults.standard.integer(forKey: userDefaults_subliminalNumRepetitions)
    var availableTimeForPlaylist = TimeInterval(UserDefaults.standard.integer(forKey: userDefaults_subliminalPlaylistTotalTime))
    
    //let test = isPlaylist()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = itemTitle
        imageView.image = icon
        
        let loopTerminated: Bool = UserDefaults.standard.bool(forKey: userDefaults_loopTerminated)
        loopCompletionImageView.alpha = loopTerminated ? 1 : 0
        loopCompletionTimeLabel.alpha = loopTerminated ? 1 : 0
        loopCompletionTimeLabel.text = UserDefaults.standard.string(forKey: userDefaults_loopTerminationTime)
        
        loopDurationValueLabel.text = isPlaylist() ? availableTimeForPlaylist.stringFromTimeInterval(showSeconds: true) : availableTimeForLoop.stringFromTimeInterval(showSeconds: true)
        
        
        if isPlaylist() {
            if let subliminal = currentSubliminal, let singleDurantion = subliminal.duration {
                self.lastDuration = TimeInterval(singleDurantion * Double(self.numberOfRepetitions + 1))
                self.loopDurationValueLabel.text = self.lastDuration.stringFromTimeInterval(showSeconds: true)
            } else {
                self.loopDurationValueLabel.text = ""
            }
        } else {
            loopDurationValueLabel.text = availableTimeForLoop.stringFromTimeInterval(showSeconds: true)
        }
        
        remainingTimeValueLabel.text = loopDurationValueLabel.text
        
        if loopTerminated {
            remainingTimeValueLabel.text = TimeInterval(0).stringFromTimeInterval(showSeconds: true)
            loopDurationValueLabel.text = isPlaylist() ? self.lastDuration.stringFromTimeInterval(showSeconds: true) : availableTimeForLoop.stringFromTimeInterval(showSeconds: true)
        }
         
        stopTimer = false
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
        timer?.fire()
    }
    
    @IBAction func closeButtonTouched(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func runTimedCode() {
        
        if PlayerStateMachine.shared.playerState == .subliminal || PlayerStateMachine.shared.playerState == .silentSubliminal {
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
            
            if isPlaylist() {
                
                let subliminal = getCurrentSubliminal()
                if subliminal != self.currentSubliminal {
                    CommandCenter.shared.elapsedTimeForPlaylist = 0
                    self.currentSubliminal = subliminal
                    self.titleLabel.text = subliminal?.title
                    if let singleDurantion = subliminal?.duration {
                        self.loopDurationValueLabel.text = TimeInterval(singleDurantion * Double(self.numberOfRepetitions + 1)).stringFromTimeInterval(showSeconds: true)
                        let remainingTime: TimeInterval = singleDurantion * Double(self.numberOfRepetitions + 1)
                        self.remainingTimeValueLabel.text = remainingTime.stringFromTimeInterval(showSeconds: true)
                    }
                    
                    if let icon = subliminal?.icon {
                        self.imageView.image = UIImage(data: icon)
                    }
                }
                

                CommandCenter.shared.elapsedTimeForPlaylist += 1
                
                guard let singleDurantion = subliminal?.duration else { return }
 
                let remainingTime: TimeInterval = max(singleDurantion * Double(self.numberOfRepetitions + 1) - CommandCenter.shared.elapsedTimeForPlaylist, 0)
                self.remainingTimeValueLabel.text = remainingTime.stringFromTimeInterval(showSeconds: true)
                
            } else {
                let remainingTime: TimeInterval = self.availableTimeForLoop - CommandCenter.shared.elapsedTimeForLoudSubliminal - CommandCenter.shared.elapsedTimeForSilentSubliminal
                self.remainingTimeValueLabel.text = remainingTime.stringFromTimeInterval(showSeconds: true)
            }
        }
    }
    
    deinit {
        stopTimer = true
        timer = nil
    }
}
