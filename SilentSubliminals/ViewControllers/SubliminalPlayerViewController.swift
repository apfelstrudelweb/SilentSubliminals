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


class SubliminalPlayerViewController: UIViewController, UIScrollViewDelegate, PlayerStateMachineDelegate, CommandCenterDelegate, BackButtonDelegate, AudioHelperDelegate {

    // 1. section
    @IBOutlet weak var introductionSwitch: UISwitch!
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
    @IBOutlet weak var rewindButton: ShadowButton!
    @IBOutlet weak var playButton: PlayButton!
    @IBOutlet weak var forwardButton: ShadowButton!
    @IBOutlet weak var silentButton: SymbolButton!
    @IBOutlet weak var affirmationTitleLabel: UILabel!
    @IBOutlet weak var timerButton: SymbolButton!
    @IBOutlet weak var loudspeakerLowSymbol: UIImageView!
    @IBOutlet weak var loudspeakerHighSymbol: UIImageView!
    @IBOutlet weak var volumeSlider: UISlider!
    
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

    var introDuration: TimeInterval = 0
    var outroDuration: TimeInterval = 0
    var singleAffirmationDuration: TimeInterval = 0
    var totalLength: TimeInterval = 0
    var elapsedTime: TimeInterval = 0
    
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
        
        PlayerStateMachine.shared.playerState = .ready
        PlayerStateMachine.shared.introState = .chair
        PlayerStateMachine.shared.outroState = .day
        PlayerStateMachine.shared.frequencyState = .loud

        let backButton = BackButton(type: .custom)
        backButton.delegate = self
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)

        self.introDuration = try! AVAudioFile(forReading: getFileFromMainBundle(filename: spokenIntro)!).duration
        self.outroDuration = try! AVAudioFile(forReading: getFileFromMainBundle(filename: spokenOutro)!).duration
        
        let affirmationFile = getFileFromSandbox(filename: spokenAffirmation)
        if affirmationFile.checkFileExist() {
            self.singleAffirmationDuration = try! AVAudioFile(forReading: affirmationFile).duration
        } else {
            let alert = UIAlertController(title: "Warning", message: "You first need to record an affirmation. You're redirected to the previous screen - there please choose the 'Affirmation Maker'.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {_ in
                self.close()
            }))
            self.present(alert, animated: true)
        }
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
        
//        isSilentMode = !isSilentMode
//
//        let buttonImage = isSilentMode ? Button.silentOnImg : Button.silentOffImg
//        self.silentButton.setImage(buttonImage, for: .normal)
//        for audioFile in self.audioFiles {
//            self.switchAndAnalyze(audioFile: audioFile)
//        }
        
    }
    
    @IBAction func playButtonTouchUpInside(_ sender: Any) {
        startPlaying()
    }
    
    @IBAction func resetButtonTouched(_ sender: Any) {
        PlayerStateMachine.shared.togglePlayPauseState()
    }
    
    @IBAction func volumeSliderChanged(_ sender: Any) {
        
        VolumeManager.shared.sliderVolume = Float(volumeSlider.value)
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
                loudNode.volume = VolumeManager.shared.sliderVolume
            case .silent:
                self.silentButton.setImage(Button.silentOnImg, for: .normal)
                silentNode.volume = VolumeManager.shared.sliderVolume
                loudNode.volume = 0
            }
        }
    }
    
    func performAction() {
        
        self.spectrumViewController?.clearGraph()

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
                break
            case .intro:
                switch PlayerStateMachine.shared.introState {
                case .chair, .bed:
                    print("intro")
                    audioHelper.playInduction(type: Induction.Intro)
                    animateIntroButton()
                case .none:
                    print("no intro")
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
            case .outro:
                switch PlayerStateMachine.shared.outroState {
                case .day, .night:
                    print("outro")
                    audioHelper.playInduction(type: Induction.Outro)
                    animateOutroButton()
                case .none:
                    print("no outro")
                }
            }
        }
    }
    
    func animateIntroButton() {
        if PlayerStateMachine.shared.introState == .chair {
            leadInChairPulseImageView.layer.add(getLayerAnimation(), forKey: "growingAnimation")
        } else if PlayerStateMachine.shared.introState == .bed {
            leadInBedPulseImageView.layer.add(getLayerAnimation(), forKey: "growingAnimation")
        }
    }
    
    func animateOutroButton() {
        if PlayerStateMachine.shared.outroState == .day {
            leadOutDayPulseImageView.layer.add(getLayerAnimation(), forKey: "growingAnimation")
            
        } else if PlayerStateMachine.shared.outroState == .night {
            leadOutNightPulseImageView.layer.add(getLayerAnimation(), forKey: "growingAnimation")
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
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        playerView.layoutSubviews()
        soundView.layoutSubviews()
    }
    

    
    func startPlaying() {
        
        PlayerStateMachine.shared.togglePlayPauseState()
        
        switch PlayerStateMachine.shared.pauseState {
        
        case .play:
            playButton.setState(active: true)
            PlayerStateMachine.shared.startPlayer()
        case .pause:
            playButton.setState(active: false)
        }
        
 //       CommandCenter.shared.updateLockScreenInfo()
        
  
//        isStopped = false
//        elapsedTime = 0
//
//        playButton.setImage(Button.playOffImg, for: .normal)
//
//        if isPausing == true {
//
//            for playerNode in activePlayerNodesSet {
//                playerNode.play()
//            }
//
//            isPausing = false
//            return
//        }
        
    }
    
    
    func pausePlaying() {

        CommandCenter.shared.updateLockScreenInfo()
        
//        for playerNode in activePlayerNodesSet {
//            playerNode.pause()
//        }
    }
    
    func stopPlaying() {
        
        //updateLockScreenInfo()
        //removeCommandCenter()
           
//        for playerNode in activePlayerNodesSet {
//            playerNode.stop()
//        }
        //self.audioEngine.stop()
        
//        activePlayerNodesSet = Set<AVAudioPlayerNode>()
        
        self.playButton.setImage(Button.playOnImg, for: .normal)
        //self.rewindButton.isEnabled = false
    }
    
    // MARK: AudioHelperDelegate
    func processAudioData(buffer: AVAudioPCMBuffer) {
        self.volumeViewController?.processAudioData(buffer: buffer)
        self.spectrumViewController?.processAudioData(buffer: buffer)
    }

}
