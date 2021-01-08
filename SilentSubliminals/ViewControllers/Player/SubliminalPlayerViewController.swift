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
    
    @IBOutlet weak var iconImageView: UIImageView! {
        didSet {
            iconImageView.layer.cornerRadius = cornerRadius
            iconImageView.clipsToBounds = true
            
            let overlay = UIView()
            overlay.backgroundColor = .white
            overlay.alpha = 0.4
            iconImageView.addSubview(overlay)
            overlay.autoPinEdgesToSuperviewEdges()
        }
    }
    @IBOutlet weak var iconShadowView: ShadowView! {
        didSet {
            iconShadowView.opacity = 0.4
            iconShadowView.size = 1
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
    
    private var audioHelper = AudioHelper()

    
    var introButtons:[ToggleButton : PlayerStateMachine.IntroState]?
    var outroButtons:[ToggleButton : PlayerStateMachine.OutroState]?
    
    var affirmation: Subliminal?
    
    
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
        
        self.navigationController?.navigationBar.tintColor = .white
        
        backButton.isEnabled = false
        forwardButton.isEnabled = false

        let affirmationFile = getFileFromSandbox(filename: spokenAffirmation)
        if !affirmationFile.checkFileExist() {
            AlertController().showWarningMissingAffirmationFile(vc: self) { (flag) in
                
                self.performSegue(withIdentifier: "makerPlayerSegue", sender: self)
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(volumeChanged(notification:)), name: NSNotification.Name(rawValue: notification_systemVolumeDidChange), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        scrollView.delegate = self
        audioHelper.delegate = self
        PlayerStateMachine.shared.delegate = self
        
        let fetchRequest = NSFetchRequest<LibraryItem> (entityName: "LibraryItem")
        let predicate = NSPredicate(format: "isActive = true")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "creationDate", ascending: false)]
        self.fetchedResultsController = NSFetchedResultsController<LibraryItem> (
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        self.fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("An error occurred")
        }
        
        if let libraryItem = fetchedResultsController.fetchedObjects?.first {
            affirmationTitleLabel.text = libraryItem.title
            iconImageView.image = UIImage(data: libraryItem.icon ?? Data())
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //audioHelper.reset()
        stopPlaying()
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
            AlertController().showInfoLongAffirmationLoop(vc: self) { result in
                if result {
                    self.startPlaying()
                }
            }
        } else {
            self.startPlaying()
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
                timerButton.setEnabled(flag: true)
                introductionSwitch.setEnabled(flag: true)
                CommandCenter.shared.enableSkipButtons(flag: false)
                break
            case .introduction:
                print("introduction")
                backButton.setEnabled(flag: true)
                forwardButton.setEnabled(flag: true)
                audioHelper.playInduction(type: Induction.Introduction)
                introductionPulseImageView.animate()
                break
            case .leadIn:
                switch PlayerStateMachine.shared.introState {
                case .chair:
                    print("intro chair")
                    backButton.setEnabled(flag: true)
                    forwardButton.setEnabled(flag: true)
                    audioHelper.playInduction(type: Induction.LeadInChair)
                    leadInChairPulseImageView.animate()
                case .bed:
                    print("intro bed")
                    backButton.setEnabled(flag: true)
                    forwardButton.setEnabled(flag: true)
                    audioHelper.playInduction(type: Induction.LeadInBed)
                    leadInBedPulseImageView.animate()
                case .none:
                    backButton.setEnabled(flag: true)
                    forwardButton.setEnabled(flag: true)
                    audioHelper.playInduction(type: Induction.Bell)
                    print("bell")
                }
                break
            case .affirmation:
                print("affirmation")
                stopButtonAnimations()
                backButton.setEnabled(flag: true)
                forwardButton.setEnabled(flag: true)
                audioHelper.playSingleAffirmation(instance: .player)
                break
            case .affirmationLoop:
                print("affirmation loop")
                backButton.setEnabled(flag: true)
                forwardButton.setEnabled(flag: true)
                audioHelper.playAffirmationLoop()
                break
            case .consolidation:
                print("consolidation")
                backButton.setEnabled(flag: true)
                forwardButton.setEnabled(flag: true)
                audioHelper.playConsolidation()
                break
            case .leadOut:
                switch PlayerStateMachine.shared.outroState {
                case .day:
                    print("outro day")
                    backButton.setEnabled(flag: true)
                    forwardButton.setEnabled(flag: true)
                    audioHelper.playInduction(type: Induction.LeadOutDay)
                    leadOutDayPulseImageView.animate()
                case .night:
                    print("outro night")
                    backButton.setEnabled(flag: true)
                    forwardButton.setEnabled(flag: true)
                    audioHelper.playInduction(type: Induction.LeadOutNight)
                    leadOutNightPulseImageView.animate()
                case .none:
                    backButton.setEnabled(flag: true)
                    forwardButton.setEnabled(flag: true)
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
        
        CommandCenter.shared.updateLockScreenInfo()
        PlayerStateMachine.shared.togglePlayPauseState()
        backButton.setEnabled(flag: true)
        forwardButton.setEnabled(flag: true)
        introductionSwitch.setEnabled(flag: false)
        timerButton.setEnabled(flag: false)
        
        CommandCenter.shared.enableSkipButtons(flag: true)
        
        switch PlayerStateMachine.shared.pauseState {
        
        case .play:
            if let libraryItem = fetchedResultsController.fetchedObjects?.first {
                CoreDataManager.sharedInstance.setNewTimestamp(item: libraryItem)
            }
            self.playButton.setState(active: true)
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
        
        CommandCenter.shared.enableSkipButtons(flag: false)
        
        introductionSwitch.layoutSubviews()
        TimerManager.shared.reset()
        
        CommandCenter.shared.updateLockScreenInfo()
    }
    
    func skip() {
        audioHelper.skip()
    }
    
    func stepForward() {
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
