//
//  SubliminalPlayerViewController.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 15.11.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import AVFoundation
import PureLayout
import MediaPlayer

class SubliminalPlayerViewController: UIViewController, UIScrollViewDelegate, PlayerStateMachineDelegate, CommandCenterDelegate, BackButtonDelegate, AudioHelperDelegate {

    // 1. section
    @IBOutlet weak var introductionSwitch: Switch!
    @IBOutlet weak var leadInChairButton: ToggleButton!
    @IBOutlet weak var leadInChairPulseImageView: UIImageView! {
        didSet {
            leadInChairPulseImageView.tintColor = PlayerControlColor.lightColor
        }
    }
    @IBOutlet weak var leadInBedButton: ToggleButton!
    @IBOutlet weak var leadInBedPulseImageView: UIImageView!{
        didSet {
            leadInBedPulseImageView.tintColor = PlayerControlColor.lightColor
        }
    }
    @IBOutlet weak var noLeadInButton: ToggleButton! {
        didSet {
            introButtons = [leadInChairButton : .chair, leadInBedButton : .bed, noLeadInButton : .none]
        }
    }
    @IBOutlet weak var leadOutDayButton: ToggleButton!
    @IBOutlet weak var leadOutDayPulseImageView: UIImageView! {
        didSet {
            leadOutDayPulseImageView.tintColor = PlayerControlColor.lightColor
        }
    }
    @IBOutlet weak var leadOutNightButton: ToggleButton!
    @IBOutlet weak var leadOutNightPulseImageView: UIImageView! {
        didSet {
            leadOutNightPulseImageView.tintColor = PlayerControlColor.lightColor
        }
    }
    @IBOutlet weak var noLeadOutButton: ToggleButton! {
        didSet {
            outroButtons = [leadOutDayButton : .day, leadOutNightButton : .night, noLeadOutButton : .none]
        }
    }
    @IBOutlet weak var introductionLabel: ShadowLabel!
    @IBOutlet weak var leadInLabel: ShadowLabel!
    @IBOutlet weak var leadOutLabel: ShadowLabel!
    
    // 2. section
    @IBOutlet weak var rewindButton: RewindButton!
    @IBOutlet weak var playButton: PlayButton!
    @IBOutlet weak var forwardButton: ShadowButton!
    @IBOutlet weak var silentButton: SymbolButton!
    @IBOutlet weak var affirmationTitleLabel: UILabel!
    @IBOutlet weak var timerButton: TimerButton!
    @IBOutlet weak var loudspeakerLowSymbol: UIImageView!
    @IBOutlet weak var loudspeakerHighSymbol: UIImageView!
    @IBOutlet weak var volumeSlider: UISlider! {
        didSet {
            volumeSlider.value = AVAudioSession.sharedInstance().outputVolume
        }
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var graphView: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var playerView: RoundedView! {
        didSet {
            playerView.imageView = backgroundImageView
        }
    }
    @IBOutlet weak var soundView: RoundedView! {
        didSet {
            soundView.imageView = backgroundImageView
        }
    }
    
    private var spectrumViewController: SpectrumViewController?
    private var volumeViewController: VolumeViewController?
    
    private var audioHelper = AudioHelper.shared

//    var introDuration: TimeInterval = 0
//    var outroDuration: TimeInterval = 0
//    var singleAffirmationDuration: TimeInterval = 0
//    var totalLength: TimeInterval = 0
//    var elapsedTime: TimeInterval = 0
    
    var introButtons:[ToggleButton : PlayerStateMachine.IntroState]?
    var outroButtons:[ToggleButton : PlayerStateMachine.OutroState]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let commandCenter = CommandCenter.shared
        commandCenter.delegate = self
        commandCenter.addCommandCenter()
        
        scrollView.delegate = self
        audioHelper.delegate = self
        PlayerStateMachine.shared.delegate = self
        
        PlayerStateMachine.shared.setIntroductionState(isOn: !UserDefaults.standard.bool(forKey: userDefaults_introductionPlayed))
        
        PlayerStateMachine.shared.playerState = .ready
        PlayerStateMachine.shared.introState = .chair
        PlayerStateMachine.shared.outroState = .day
        PlayerStateMachine.shared.frequencyState = .loud

        let backButton = BackButton(type: .custom)
        backButton.delegate = self
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        
        rewindButton.isEnabled = false
        forwardButton.isEnabled = false

        let affirmationFile = getFileFromSandbox(filename: spokenAffirmation)
        if !affirmationFile.checkFileExist() {

            let alert = UIAlertController(title: "Warning", message: "You first need to record an affirmation. You're redirected to the previous screen - there please choose the 'Affirmation Maker'.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {_ in
                self.close()
            }))
            self.present(alert, animated: true)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(volumeChanged(notification:)), name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //stopPlaying()
        audioHelper.stop()
    }
    
    // MARK: Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let vc = segue.destination as? VolumeViewController {
            volumeViewController = vc
        }
        if let vc = segue.destination as? SpectrumViewController {
            spectrumViewController = vc
        }
    }
    
    // MARK: BackButtonDelegate
    func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: user interactions
    @IBAction func introductionSwitchTouched(_ sender: UISwitch) {
        let isOn = self.introductionSwitch.isOn
        PlayerStateMachine.shared.setIntroductionState(isOn: isOn)
    }
    
    @IBAction func leadInChairTouched(_ sender: Any) {
        PlayerStateMachine.shared.introState = .chair
    }
    
    @IBAction func leadInBedTouched(_ sender: Any) {
        PlayerStateMachine.shared.introState = .bed
    }
    
    @IBAction func leadInNoneTouched(_ sender: Any) {
        PlayerStateMachine.shared.introState = .none
    }
    
    @IBAction func leadOutDayTouched(_ sender: Any) {
        PlayerStateMachine.shared.outroState = .day
    }
    
    @IBAction func leadOutNightTouched(_ sender: Any) {
        PlayerStateMachine.shared.outroState = .night
    }
    
    @IBAction func leadOutNoneTouched(_ sender: Any) {
        PlayerStateMachine.shared.outroState = .none
    }
    
    @IBAction func silentButtonTouched(_ sender: Any) {
        PlayerStateMachine.shared.toggleFrequencyState()
    }
    
    @IBAction func playButtonTouchUpInside(_ sender: Any) {
        
        PlayerStateMachine.shared.setIntroductionState(isOn: introductionSwitch.isOn)
        
        if PlayerStateMachine.shared.playerState == .ready {
            askUserForConfirmation(completionHandler: {(result) in
                if result {
                    self.startPlaying()
                }
            })
        } else {
            self.startPlaying()
        }
    }
    
    @IBAction func resetButtonTouched(_ sender: Any) {
        stopPlaying()
    }
    
    @IBAction func volumeSliderChanged(_ sender: Any) {
        MPVolumeView.setVolume(volumeSlider.value)
    }

    func updateIntroButtons() {
        
        DispatchQueue.main.async {
            self.introButtons?.forEach {
                $0.key.setState(active: $0.value == PlayerStateMachine.shared.introState)
                $0.key.isEnabled = PlayerStateMachine.shared.playerState == .ready
            }
        }
    }
    
    func updateOutroButtons() {
        
        DispatchQueue.main.async {
            self.outroButtons?.forEach {
                $0.key.setState(active: $0.value == PlayerStateMachine.shared.outroState)
                $0.key.isEnabled = PlayerStateMachine.shared.playerState == .ready
            }
        }
    }
    
    
    func toggleSilentMode() {
        
        let silentNode = audioHelper.getSilentPlayerNode()
        let loudNode = audioHelper.getLoudPlayerNode()
        
        DispatchQueue.main.async {
            switch PlayerStateMachine.shared.frequencyState {
            case .loud:
                self.silentButton.setImage(Button.silentOffImg, for: .normal)
                silentNode.volume = 0
                loudNode.volume = 1
            case .silent:
                self.silentButton.setImage(Button.silentOnImg, for: .normal)
                silentNode.volume = 1
                loudNode.volume = 0
            }
        }
    }
    
    // MARK: PlayerStateMachineDelegate
    func performAction() {
        
        self.spectrumViewController?.clearGraph()
        //introductionSwitch.isOn = !UserDefaults.standard.bool(forKey: userDefaults_introductionPlayed)

        switch PlayerStateMachine.shared.pauseState {
        case .pause:
            print("pause")
            break
            
        case .play:
            switch PlayerStateMachine.shared.playerState {
            case .ready:
                stopButtonAnimations()
                print("ready")
                playButton.setState(active: false)
                rewindButton.setEnabled(flag: false)
                timerButton.setEnabled(flag: true)
                break
            case .introduction:
                print("introduction")
                audioHelper.playInduction(type: Induction.Introduction)
                break
            case .leadIn:
                switch PlayerStateMachine.shared.introState {
                case .chair:
                    print("intro chair")
                    audioHelper.playInduction(type: Induction.LeadInChair)
                    animateIntroButton()
                case .bed:
                    print("intro bed")
                    audioHelper.playInduction(type: Induction.LeadInBed)
                    animateIntroButton()
                case .none:
                    audioHelper.playInduction(type: Induction.Bell)
                    print("bell")
                }
                break
            case .affirmation:
                print("affirmation")
                stopButtonAnimations()
                audioHelper.playSingleAffirmation(instance: .player)
                break
            case .affirmationLoop:
                print("affirmation loop")
                audioHelper.playAffirmationLoop()
                break
            case .leadOut:
                switch PlayerStateMachine.shared.outroState {
                case .day:
                    print("outro day")
                    audioHelper.playInduction(type: Induction.LeadOutDay)
                    animateOutroButton()
                case .night:
                    print("outro night")
                    audioHelper.playInduction(type: Induction.LeadOutNight)
                    animateOutroButton()
                case .none:
                    audioHelper.playInduction(type: Induction.Bell)
                    print("bell")
                }
            }
        }
    }
    
    // TODO: put logic into image view
    func animateIntroButton() {
        DispatchQueue.main.async {
            if PlayerStateMachine.shared.introState == .chair {
                self.leadInChairPulseImageView.layer.add(getLayerAnimation(), forKey: "growingAnimation")
            } else if PlayerStateMachine.shared.introState == .bed {
                self.leadInBedPulseImageView.layer.add(getLayerAnimation(), forKey: "growingAnimation")
            }
        }
    }
    
    func animateOutroButton() {
        DispatchQueue.main.async {
            if PlayerStateMachine.shared.outroState == .day {
                self.leadOutDayPulseImageView.layer.add(getLayerAnimation(), forKey: "growingAnimation")
            } else if PlayerStateMachine.shared.outroState == .night {
                self.leadOutNightPulseImageView.layer.add(getLayerAnimation(), forKey: "growingAnimation")
            }
        }
    }
    
    func stopButtonAnimations() {
        DispatchQueue.main.async {
            self.leadInChairPulseImageView.layer.removeAllAnimations()
            self.leadInBedPulseImageView.layer.removeAllAnimations()
            self.leadOutDayPulseImageView.layer.removeAllAnimations()
            self.leadOutNightPulseImageView.layer.removeAllAnimations()
        }
    }
    
    func pauseSound() {
        print("Sound paused")
        audioHelper.pauseSound()
    }
    
    func continueSound() {
        print("Sound resumed")
        audioHelper.continueSound()
    }
    
    func terminateSound() {
        print("Sound terminated")
        playButton.setState(active: false)
    }
    
    // MARK: CommandCenterDelegate
    func startPlaying() {
        
        CommandCenter.shared.updateLockScreenInfo()
        PlayerStateMachine.shared.togglePlayPauseState()
        rewindButton.setEnabled(flag: true)
        introductionSwitch.setEnabled(flag: false)
        timerButton.setEnabled(flag: false)
        
        switch PlayerStateMachine.shared.pauseState {
        
        case .play:
            self.playButton.setState(active: true)
            PlayerStateMachine.shared.startPlayer()
        case .pause:
            playButton.setState(active: false)
        }
    }
    
    func pausePlaying() {

        CommandCenter.shared.updateLockScreenInfo()
    }
    
    func stopPlaying() {
        
        AudioHelper.shared.stop()
        playButton.setState(active: false)
        rewindButton.setEnabled(flag: false)
        introductionSwitch.setEnabled(flag: true)
        timerButton.setEnabled(flag: true)
        stopButtonAnimations()
        
        introductionSwitch.layoutSubviews()
        TimerManager.shared.reset()
        
        CommandCenter.shared.updateLockScreenInfo()
        
    }
    
    func askUserForConfirmation(completionHandler: @escaping (Bool) -> Void) {
        
        guard let playTimeInSeconds = TimerManager.shared.remainingTime else {
            completionHandler(true)
            return
        }
        
        if playTimeInSeconds < criticalLoopDurationInSeconds {
            completionHandler(true)
            return
        }
        
        let hours: Int = Int(playTimeInSeconds) / hourInSeconds
        
        let alert = UIAlertController(title: "Information", message: "You've set a very long time interval of about \(hours) hours. Are you sure that you want to listen to the silent subliminals for so long?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "YES", style: .default, handler: {_ in
            completionHandler(true)
        }))
        alert.addAction(UIAlertAction(title: "NO", style: .cancel, handler: { _ in
            completionHandler(false)
        }))
        self.present(alert, animated: true)
    }
    
    
    // MARK: Notification
    @objc func volumeChanged(notification:NSNotification) {
        let volume = notification.userInfo!["AVSystemController_AudioVolumeNotificationParameter"]
        let category = notification.userInfo!["AVSystemController_AudioCategoryNotificationParameter"]
        let reason = notification.userInfo!["AVSystemController_AudioVolumeChangeReasonNotificationParameter"]
        
        self.volumeSlider.value = volume as! Float

        print("volume:      \(volume!)")
        print("category:    \(category!)")
        print("reason:      \(reason!)")
        print("\n")
    }
    
    // MARK: AudioHelperDelegate
    func processAudioData(buffer: AVAudioPCMBuffer) {
        self.volumeViewController?.processAudioData(buffer: buffer)
        self.spectrumViewController?.processAudioData(buffer: buffer)
    }
    
    // MARK: UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        playerView.layoutSubviews()
        soundView.layoutSubviews()
    }

}
