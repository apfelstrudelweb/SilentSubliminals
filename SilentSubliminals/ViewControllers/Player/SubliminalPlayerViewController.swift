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
import CoreData

class SubliminalPlayerViewController: UIViewController, UIScrollViewDelegate, PlayerStateMachineDelegate, CommandCenterDelegate, BackButtonDelegate, AudioHelperDelegate, NSFetchedResultsControllerDelegate {

    var fetchedResultsController: NSFetchedResultsController<LibraryItem>!
    
    // 1. section
    @IBOutlet weak var introductionSwitch: Switch!
    @IBOutlet weak var introductionPulseImageView: PulseImageView!
    @IBOutlet weak var leadInChairButton: ToggleButton!
    @IBOutlet weak var leadInChairPulseImageView: PulseImageView!
    @IBOutlet weak var leadInBedButton: ToggleButton!
    @IBOutlet weak var leadInBedPulseImageView: PulseImageView!
    @IBOutlet weak var noLeadInButton: ToggleButton! {
        didSet {
            introButtons = [leadInChairButton : .chair, leadInBedButton : .bed, noLeadInButton : .none]
        }
    }
    @IBOutlet weak var leadOutDayButton: ToggleButton!
    @IBOutlet weak var leadOutDayPulseImageView: PulseImageView!
    @IBOutlet weak var leadOutNightButton: ToggleButton!
    @IBOutlet weak var leadOutNightPulseImageView: PulseImageView!
    @IBOutlet weak var noLeadOutButton: ToggleButton! {
        didSet {
            outroButtons = [leadOutDayButton : .day, leadOutNightButton : .night, noLeadOutButton : .none]
        }
    }
    @IBOutlet weak var introductionLabel: ShadowLabel!
    @IBOutlet weak var leadInLabel: ShadowLabel!
    @IBOutlet weak var leadOutLabel: ShadowLabel!
    
    // 2. section
    @IBOutlet weak var backButton: SkipButton!
    @IBOutlet weak var playButton: PlayButton!
    @IBOutlet weak var forwardButton: SkipButton!
    @IBOutlet weak var silentButton: SymbolButton!
    @IBOutlet weak var affirmationTitleLabel: UILabel!
    @IBOutlet weak var timerButton: TimerButton!
    @IBOutlet weak var loudspeakerLowSymbol: UIImageView!
    @IBOutlet weak var loudspeakerHighSymbol: LoudspeakerSymbolView!
    @IBOutlet weak var volumeSlider: UISlider! {
        didSet {
            volumeSlider.value = AVAudioSession.sharedInstance().outputVolume
        }
    }
    

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var graphView: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var playerView: RoundedView! {
        didSet {
            playerView.rootView = containerView
            playerView.imageView = backgroundImageView
        }
    }
    @IBOutlet weak var soundView: RoundedView! {
        didSet {
            soundView.rootView = containerView
            soundView.imageView = backgroundImageView
        }
    }
    
    @IBOutlet weak var iconButton: ToggleButton! {
        didSet {
            iconButton.layer.cornerRadius = 10
            iconButton.clipsToBounds = true
            iconButton.alpha = 0.75

//            let overlay = UIView()
//            overlay.backgroundColor = .white
//            overlay.alpha = 0.4
//            iconButton.addSubview(overlay)
//            overlay.autoPinEdgesToSuperviewEdges()
        }
    }
    @IBOutlet weak var iconButtonBackgroundView: UIView! {
        didSet {
            iconButtonBackgroundView.layer.cornerRadius = 10
            iconButtonBackgroundView.clipsToBounds = true
        }
    }
    @IBOutlet weak var subliminalPulseImageView: PulseImageView!
    
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var overlayButton: UIButton!
    @IBOutlet weak var backgroundButton: UIButton!
    
    
    private var spectrumViewController: SpectrumViewController?
    private var volumeViewController: VolumeViewController?
    
    private var audioHelper = AudioHelper()

    
    var introButtons:[ToggleButton : PlayerStateMachine.IntroState]?
    var outroButtons:[ToggleButton : PlayerStateMachine.OutroState]?
    
    
    var currentPlaylist: Playlist?
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    let TEST_MODE = true
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //navigationController?.hidesBarsOnTap = true
        
        overlayView.layer.contents = #imageLiteral(resourceName: "subliminalPlayerBackground.png").cgImage
        overlayButton.isEnabled = false
        
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
        
        self.navigationController?.navigationBar.tintColor = .white
        
        backButton.isEnabled = false
        forwardButton.isEnabled = false

        NotificationCenter.default.addObserver(self, selector: #selector(volumeChanged(notification:)), name: NSNotification.Name(rawValue: notification_systemVolumeDidChange), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appCameToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let subliminal = getCurrentSubliminal()
        affirmationTitleLabel.text = subliminal?.title
        iconButton.setImage(UIImage(data: subliminal?.icon ?? Data()), for: .normal)
        scrollView.contentOffset.y = scrollView.contentOffset.y + 1  // otherwise, glass view appears white
        
        scrollView.delegate = self
        audioHelper.delegate = self
        PlayerStateMachine.shared.delegate = self
        
        //UserDefaults.standard.setValue(false, forKey: userDefaults_loopTerminated)
        CommandCenter.shared.updateLockScreenInfo()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //audioHelper.reset()
        stopPlaying()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
    }
    
    func setTabBar(hidden:Bool) {
        guard let frame = self.tabBarController?.tabBar.frame else {return }
        
        if hidden {
            UIView.animate(withDuration: 1, animations: {
                self.tabBarController?.tabBar.frame = CGRect(x: frame.origin.x, y: frame.origin.y + frame.height, width: frame.width, height: frame.height)
            })
        } else {
            UIView.animate(withDuration: 1, animations: {
                self.tabBarController?.tabBar.frame = UITabBarController().tabBar.frame

            })
        }
    }

    @objc func appCameToForeground() {
        print("app enters foreground")

        if self.overlayView.alpha == 1 {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            setTabBar(hidden: true)
        }
        self.scrollView.layoutSubviews()
        
        switch PlayerStateMachine.shared.pauseState {
        case .pause:
            print("pause")
            break
            
        case .play:
            switch PlayerStateMachine.shared.playerState {
            case .ready:
                stopButtonAnimations()
                break
            case .introduction:
                introductionPulseImageView.animate()
                break
            case .leadIn:
                switch PlayerStateMachine.shared.introState {
                case .chair:
                    leadInChairPulseImageView.animate()
                case .bed:
                    leadInBedPulseImageView.animate()
                case .none:
                    break
                }
                break
            case .subliminal:
                subliminalPulseImageView.animate()
            case .silentSubliminal:
                subliminalPulseImageView.animate()
                break
            case .consolidation:
                subliminalPulseImageView.stopAnimation()
                break
            case .leadOut:
                switch PlayerStateMachine.shared.outroState {
                case .day:
                    leadOutDayPulseImageView.animate()
                case .night:
                    leadOutNightPulseImageView.animate()
                case .none:
                    break
                }
            }
        }
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
        if let vc = segue.destination as? ShowCountdownViewController {
            vc.itemTitle = affirmationTitleLabel.text
            vc.icon = iconButton.image(for: .normal)
        }
        
        if let vc = segue.destination as? RepetitionViewController {
            vc.currentPlaylist = currentPlaylist
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
        
        if currentPlaylist == nil {
            let availableTimeForLoop = TimeInterval(UserDefaults.standard.integer(forKey: userDefaults_subliminalLoopDuration))
            guard let soundfile = getCurrentSubliminal(), let duration = soundfile.duration else { return }
            if availableTimeForLoop < 2 * duration {

                let durationString: String = duration.stringFromTimeInterval(showHours: false)

                let alert = UIAlertController(title: "Error", message: "Your subliminal is exactly \(durationString) long. You need at least set twice the time of this subliminal in order to play the silent part as well. Please correct this now!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                    self.performSegue(withIdentifier: "timerSegue", sender: self)
                }))
                self.present(alert, animated: true)
                return
            }
        }

        PlayerStateMachine.shared.setIntroductionState(isOn: introductionSwitch.isOn)
        
        if PlayerStateMachine.shared.playerState == .ready {
            
            if !TEST_MODE {
                overlayButton.isEnabled = false

                UIView.animate(withDuration: 1) {
                    self.overlayView.alpha = 1
                    //self.navigationController?.navigationBar.alpha = 0.01
                    self.navigationController?.setNavigationBarHidden(true, animated: true)
                    self.setTabBar(hidden: true)
                } completion: { _ in
                    self.overlayButton.isEnabled = true
                }
            }

            AlertController().showInfoLongAffirmationLoop(vc: self) { result in
                if result {
                    self.startPlaying()
                }
            }
        } else {
            self.startPlaying()
            //overlayView.isHidden = false
        }
    }
    
    @IBAction func overlayButtonTouchUpInside(_ sender: Any) {
        
        if TEST_MODE { return }
        
        if !overlayButton.isEnabled {return}
        
        UIView.animate(withDuration: 2) {
            self.overlayView.alpha = 0
            //self.navigationController?.navigationBar.alpha = 1
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.setTabBar(hidden: false)
        }
    }
    
    @IBAction func backgroundButtonsTouched(_ sender: Any) {
        
        if TEST_MODE { return }
        
        overlayButton.isEnabled = false
        
        UIView.animate(withDuration: 1) {
            self.overlayView.alpha = 1
            //self.navigationController?.navigationBar.alpha = 0
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            self.setTabBar(hidden: true)
        } completion: { _ in
            self.overlayButton.isEnabled = true
        }
    }

    
    @IBAction func backwardButtonTouched(_ sender: Any) {
        stopPlaying()
    }
    
    @IBAction func forwardButtonTouched(_ sender: Any) {
        stepForward()
    }
    
    @IBAction func volumeSliderChanged(_ sender: Any) {
        MPVolumeView.setVolume(volumeSlider.value)
    }
    
    @IBAction func iconButtonTouched(_ sender: Any) {
        self.performSegue(withIdentifier: "showIconSegue", sender: sender)
    }
    
    
    @IBAction func timerButtonTouched(_ sender: Any) {
        
        if currentPlaylist != nil {
            performSegue(withIdentifier: "repetitionSegue", sender: self)
        } else {
            performSegue(withIdentifier: "timerSegue", sender: self)
        }
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
                self.silentButton.setImage(silentOffImg, for: .normal)
                silentNode.volume = 0
                loudNode.volume = 1
                self.audioHelper.toggleMode(isSilent: false)
            case .silent:
                self.silentButton.setImage(silentOnImg, for: .normal)
                silentNode.volume = 1
                loudNode.volume = 0
                self.audioHelper.toggleMode(isSilent: true)
            }
        }
    }
    
    // MARK: PlayerStateMachineDelegate
    func subliminalDidUpdate() {
        let subliminal = getCurrentSubliminal()
        affirmationTitleLabel.text = subliminal?.title
        iconButton.setImage(UIImage(data: subliminal?.icon ?? Data()), for: .normal)
    }
    
    func performAction() {
        
        self.spectrumViewController?.clearGraph()
        //introductionSwitch.isOn = !UserDefaults.standard.bool(forKey: userDefaults_introductionPlayed)
        self.introductionPulseImageView.stopAnimation()
        self.loudspeakerHighSymbol.showExceedWarning(flag: false)

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
                backButton.setEnabled(flag: false)
                forwardButton.setEnabled(flag: false)
                CommandCenter.shared.enableForwardButton(flag: false)
                CommandCenter.shared.enableBackButton(flag: false)
                timerButton.setEnabled(flag: true)
                introductionSwitch.setEnabled(flag: true)
                break
            case .introduction:
                print("introduction")
                backButton.setEnabled(flag: true)
                forwardButton.setEnabled(flag: true)
                CommandCenter.shared.enableForwardButton(flag: true)
                CommandCenter.shared.enableBackButton(flag: true)
                audioHelper.playInduction(type: Induction.Introduction)
                introductionPulseImageView.animate()
                break
            case .leadIn:
                switch PlayerStateMachine.shared.introState {
                case .chair:
                    print("intro chair")
                    backButton.setEnabled(flag: true)
                    forwardButton.setEnabled(flag: true)
                    CommandCenter.shared.enableForwardButton(flag: true)
                    CommandCenter.shared.enableBackButton(flag: true)
                    audioHelper.playInduction(type: Induction.LeadInChair)
                    leadInChairPulseImageView.animate()
                case .bed:
                    print("intro bed")
                    backButton.setEnabled(flag: true)
                    forwardButton.setEnabled(flag: true)
                    CommandCenter.shared.enableForwardButton(flag: true)
                    CommandCenter.shared.enableBackButton(flag: true)
                    audioHelper.playInduction(type: Induction.LeadInBed)
                    leadInBedPulseImageView.animate()
                case .none:
                    backButton.setEnabled(flag: true)
                    forwardButton.setEnabled(flag: true)
                    CommandCenter.shared.enableForwardButton(flag: true)
                    CommandCenter.shared.enableBackButton(flag: true)
                    audioHelper.playInduction(type: Induction.Bell)
                    print("bell")
                }
                break
            case .subliminal:
                print("subliminal")
                stopButtonAnimations()
                backButton.setEnabled(flag: true)
                forwardButton.setEnabled(flag: true)
                CommandCenter.shared.enableForwardButton(flag: true)
                CommandCenter.shared.enableBackButton(flag: true)
                audioHelper.playSubliminal(instance: .player)
                subliminalPulseImageView.animate()
                break
            case .silentSubliminal:
                print("silent subliminal")
                backButton.setEnabled(flag: true)
                forwardButton.setEnabled(flag: true)
                CommandCenter.shared.enableForwardButton(flag: true)
                CommandCenter.shared.enableBackButton(flag: true)
                audioHelper.playSubliminalLoop(isInPlaylist: currentPlaylist != nil)
                //subliminalPulseImageView.animate()
                break
            case .consolidation:
                print("consolidation")
                backButton.setEnabled(flag: true)
                forwardButton.setEnabled(flag: true)
                CommandCenter.shared.enableForwardButton(flag: true)
                CommandCenter.shared.enableBackButton(flag: true)
                audioHelper.playConsolidation()
                subliminalPulseImageView.stopAnimation()
                break
            case .leadOut:
                switch PlayerStateMachine.shared.outroState {
                case .day:
                    print("outro day")
                    backButton.setEnabled(flag: true)
                    forwardButton.setEnabled(flag: true)
                    CommandCenter.shared.enableForwardButton(flag: true)
                    CommandCenter.shared.enableBackButton(flag: true)
                    audioHelper.playInduction(type: Induction.LeadOutDay)
                    leadOutDayPulseImageView.animate()
                case .night:
                    print("outro night")
                    backButton.setEnabled(flag: true)
                    forwardButton.setEnabled(flag: true)
                    CommandCenter.shared.enableForwardButton(flag: true)
                    CommandCenter.shared.enableBackButton(flag: true)
                    audioHelper.playInduction(type: Induction.LeadOutNight)
                    leadOutNightPulseImageView.animate()
                case .none:
                    backButton.setEnabled(flag: true)
                    forwardButton.setEnabled(flag: true)
                    CommandCenter.shared.enableForwardButton(flag: true)
                    CommandCenter.shared.enableBackButton(flag: true)
                    audioHelper.playInduction(type: Induction.Bell)
                    print("bell")
                }
            }
        }
    }
    

    func stopButtonAnimations() {
        DispatchQueue.main.async {
            self.introductionPulseImageView.layer.removeAllAnimations()
            self.leadInChairPulseImageView.layer.removeAllAnimations()
            self.leadInBedPulseImageView.layer.removeAllAnimations()
            self.leadOutDayPulseImageView.layer.removeAllAnimations()
            self.leadOutNightPulseImageView.layer.removeAllAnimations()
            self.subliminalPulseImageView.layer.removeAllAnimations()
        }
    }
    
    func pauseSound() {
        print("Sound paused")
        audioHelper.pauseSound()
        //CommandCenter.shared.displayElapsedTime()
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

        UserDefaults.standard.setValue(false, forKey: userDefaults_loopTerminated)
        
        PlayerStateMachine.shared.togglePlayPauseState()
        introductionSwitch.setEnabled(flag: false)
        timerButton.setEnabled(flag: false)
        
        CommandCenter.shared.enableForwardButton(flag: true)
        CommandCenter.shared.elapsedTimeForSilentSubliminal = 0
        
        switch PlayerStateMachine.shared.pauseState {
        
        case .play:
            self.playButton.setState(active: true)
            forwardButton.setEnabled(flag: true)
            PlayerStateMachine.shared.startPlayer()
        case .pause:
            forwardButton.setEnabled(flag: false)
            playButton.setState(active: false)
        }
    }
    
    func pausePlaying() {

        CommandCenter.shared.updateLockScreenInfo()
    }
    
    func stopPlaying() {
        
        audioHelper.reset()
        //playButton.setState(active: false)
        backButton.setEnabled(flag: false)
        forwardButton.setEnabled(flag: false)
        introductionSwitch.setEnabled(flag: true)
        timerButton.setEnabled(flag: true)
        stopButtonAnimations()

        introductionSwitch.layoutSubviews()
        
        CommandCenter.shared.enableForwardButton(flag: false)
        CommandCenter.shared.updateLockScreenInfo()
        //CommandCenter.shared.removeCommandCenter()
    }
    
    func skip() {
        audioHelper.skip()
    }
    
    func stepForward() {
        
        if PlayerStateMachine.shared.playerState == .subliminal {
            guard let soundfile = getCurrentSubliminal(), let duration = soundfile.duration else { return }
            CommandCenter.shared.elapsedTimeForLoudSubliminal = duration
        }
        
        audioHelper.skip()
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
        DispatchQueue.main.async {
            self.volumeViewController?.processAudioData(buffer: buffer)
            self.spectrumViewController?.processAudioData(buffer: buffer)
        }
    }
    
    func alertSilentsTooLoud(flag: Bool) {
        if PlayerStateMachine.shared.frequencyState == .silent {
            self.loudspeakerHighSymbol.showExceedWarning(flag: flag)
        } else {
            self.loudspeakerHighSymbol.showExceedWarning(flag: false)
        }
    }
    
    // MARK: UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        playerView.layoutSubviews()
        soundView.layoutSubviews()
    }
}


extension UINavigationController {
    func getViewController<T: UIViewController>(of type: T.Type) -> UIViewController? {
        return self.viewControllers.first(where: { $0 is T })
    }

    func popToViewController<T: UIViewController>(of type: T.Type, animated: Bool) {
        guard let viewController = self.getViewController(of: type) else { return }
        self.popToViewController(viewController, animated: animated)
    }
}
