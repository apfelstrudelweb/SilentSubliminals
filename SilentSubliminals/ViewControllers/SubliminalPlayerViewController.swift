//
//  SubliminalPlayerViewController.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 15.11.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import CoreAudio
import AVFoundation
import Accelerate
import PureLayout
import MediaPlayer

// https://medium.com/@ian.mundy/audio-mixing-on-ios-4cd51dfaac9a
class SubliminalPlayerViewController: UIViewController, UIScrollViewDelegate, StateMachineDelegate, CommandCenterDelegate, BackButtonDelegate {


    // 1. section
    @IBOutlet weak var introductionSwitch: UISwitch!
    @IBOutlet weak var leadInChairButton: ToggleButton!
    @IBOutlet weak var leadInBedButton: ToggleButton!
    @IBOutlet weak var noLeadInButton: ToggleButton!
    @IBOutlet weak var leadOutDayButton: ToggleButton!
    @IBOutlet weak var leadOutNightButton: ToggleButton!
    @IBOutlet weak var noLeadOutButton: ToggleButton!
    @IBOutlet weak var introductionLabel: ShadowLabel!
    @IBOutlet weak var leadInLabel: ShadowLabel!
    @IBOutlet weak var leadOutLabel: ShadowLabel!
    
    // 2. section
    @IBOutlet weak var rewindButton: ShadowButton!
    @IBOutlet weak var playButton: ShadowButton!
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
    @IBOutlet weak var playerView: RoundedView!
    @IBOutlet weak var soundView: RoundedView!
    
    private var spectrumViewController: SpectrumViewController?
    private var volumeViewController: VolumeViewController?

    private var audioFiles: Array<AudioFileTypes> = [AudioFileTypes(filename: spokenAffirmation, isSilent: false), AudioFileTypes(filename: spokenAffirmationSilent, isSilent: true)]
    
    var activePlayerNodesSet = Set<AVAudioPlayerNode>()
    
    private var silentAffirmationAudioNode = AVAudioPlayerNode()
    private var loudAffirmationAudioNode = AVAudioPlayerNode()
    
    private var audioEngine: AVAudioEngine = AVAudioEngine()
    private var mixer: AVAudioMixerNode = AVAudioMixerNode()
    private var equalizerHighPass: AVAudioUnitEQ = AVAudioUnitEQ(numberOfBands: 1)
    
    var timer: Timer?
    var affirmationLoopDuration = TimerManager.shared.remainingTime
    
    var audioFileBuffer: AVAudioPCMBuffer?
    var audioFrameCount: UInt32?
    
    var introDuration: TimeInterval = 0
    var outroDuration: TimeInterval = 0
    var singleAffirmationDuration: TimeInterval = 0
    var totalLength: TimeInterval = 0
    var elapsedTime: TimeInterval = 0
    
    var introButtons:[ToggleButton : StateMachine.IntroState]?
    var outroButtons:[ToggleButton : StateMachine.OutroState]?
    
    
    let audioQueue: DispatchQueue = DispatchQueue(label: "PlayerQueue", attributes: [])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let commandCenter = CommandCenter.shared
        commandCenter.delegate = self
        commandCenter.addCommandCenter()
        
        scrollView.delegate = self
        StateMachine.shared.delegate = self
        
        introButtons = [leadInChairButton : .chair, leadInBedButton : .bed, noLeadInButton : .none]
        outroButtons = [leadOutDayButton : .day, leadOutNightButton : .night, noLeadOutButton : .none]
        
        StateMachine.shared.introState = .chair
        StateMachine.shared.outroState = .day
        StateMachine.shared.affirmationState = .loud

        let backButton = BackButton(type: .custom)
        backButton.delegate = self
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)

        playerView.imageView = backgroundImageView
        soundView.imageView = backgroundImageView

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
    
    
    // MARK: user interactions
    @IBAction func leadInChairTouched(_ sender: Any) {
        StateMachine.shared.introState = .chair
    }
    
    @IBAction func leadInBedTouched(_ sender: Any) {
        StateMachine.shared.introState = .bed
    }
    
    @IBAction func leadInNoneTouched(_ sender: Any) {
        StateMachine.shared.introState = .none
    }
    
    @IBAction func leadOutDayTouched(_ sender: Any) {
        StateMachine.shared.outroState = .day
    }
    
    @IBAction func leadOutNightTouched(_ sender: Any) {
        StateMachine.shared.outroState = .night
    }
    
    @IBAction func leadOutNoneTouched(_ sender: Any) {
        StateMachine.shared.outroState = .none
    }
    
    @IBAction func silentButtonTouched(_ sender: Any) {
        
        StateMachine.shared.affirmationState = StateMachine.shared.affirmationState.nextState
        
//        isSilentMode = !isSilentMode
//
//        let buttonImage = isSilentMode ? Button.silentOnImg : Button.silentOffImg
//        self.silentButton.setImage(buttonImage, for: .normal)
//        for audioFile in self.audioFiles {
//            self.switchAndAnalyze(audioFile: audioFile)
//        }
        
    }
    
    @IBAction func playButtonTouchUpInside(_ sender: Any) {
        StateMachine.shared.doNextState()
    }
    
    @IBAction func resetButtonTouched(_ sender: Any) {
        StateMachine.shared.toggleState()
    }
    
    @IBAction func volumeSliderChanged(_ sender: Any) {
        
        VolumeManager.shared.sliderVolume = Float(volumeSlider.value)
        
//
//        for playerNode in activePlayerNodesSet {
//            playerNode.volume = VolumeManager.shared.sliderVolume ?? defaultSliderVolume
//            //print(playerNode.volume)
//        }
//        for audioFile in audioFiles {
//            let audioPlayer = audioFile.audioPlayer
//            //audioPlayer.volume = audioFile.isSilent ? (isSilentMode ? masterVolume : 0) : (isSilentMode ? 0 : masterVolume)
//        }
    }

    func updateIntroButtons() {
        
        DispatchQueue.main.async {
            self.introButtons?.forEach {
                $0.key.setState(active: $0.value == StateMachine.shared.introState)
                $0.key.isEnabled = StateMachine.shared.playerState == .ready
            }
        }
    }
    
    func updateOutroButtons() {
        
        DispatchQueue.main.async {
            self.outroButtons?.forEach {
                $0.key.setState(active: $0.value == StateMachine.shared.outroState)
                $0.key.isEnabled = StateMachine.shared.playerState == .ready
            }
        }
    }
    
    
    func toggleSilentMode() {
        
        DispatchQueue.main.async {
            switch StateMachine.shared.affirmationState {
            case .loud:
                self.silentButton.setImage(Button.silentOffImg, for: .normal)
                self.silentAffirmationAudioNode.volume = 0
                self.loudAffirmationAudioNode.volume = VolumeManager.shared.deviceVolume
            case .silent:
                self.silentButton.setImage(Button.silentOnImg, for: .normal)
                self.silentAffirmationAudioNode.volume = VolumeManager.shared.deviceVolume
                self.loudAffirmationAudioNode.volume = 0
            }
        }
    }
    
    func performAction() {
        
        switch StateMachine.shared.pauseState {
        case .pause:
            print("pause")
            break
            
        case .play:
            switch StateMachine.shared.playerState {
            case .ready:
                print("ready")
                break
            case .intro:
                switch StateMachine.shared.introState {
                case .chair, .bed:
                    print("intro")
                    self.playInduction(type: Induction.Intro)
                case .none:
                    print("no intro")
                    StateMachine.shared.doNextState()
                }
                break
            case .affirmation:
                print("affirmation")
                self.playAffirmation(loop: false)
                break
            case .affirmationLoop:
                print("affirmation loop")
                StateMachine.shared.toggleAffirmationState()
                //self.playSilentLoop()
                self.playLoop()
                //self.playAffirmation(loop: true)
                break
            case .outro:
                switch StateMachine.shared.outroState {
                case .day, .night:
                    print("outro")
                    self.playInduction(type: Induction.Outro)
                case .none:
                    print("no outro")
                    StateMachine.shared.doNextState()
                }
            }
        }
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        playerView.layoutSubviews()
        soundView.layoutSubviews()
    }
    

    fileprivate func setAffirmationLoopDuration() {
        
        if TimerManager.shared.countdownSet == true {
            self.affirmationLoopDuration = TimerManager.shared.remainingTime
        } else {
            let stopTime = TimerManager.shared.stopTime
            self.affirmationLoopDuration = stopTime?.timeIntervalSinceNow
            
            guard let duration = self.affirmationLoopDuration else { return }
            if duration < 0 {
                self.affirmationLoopDuration! += 24 * 60 * 60
            }
        }
        
        let hours: Int = Int(self.affirmationLoopDuration! / 3600)
        
//        if hours >= criticalLoopDurationInHours {
//            let alert = UIAlertController(title: "Information", message: "You've set a very long time interval of about \(hours) hours. Are you sure that you want to listen to the silent subliminals for so long?", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { [self]_ in
//                self.startPlaying()
//                self.isPlaying = true
//            }))
//            alert.addAction(UIAlertAction(title: "NO", style: .cancel, handler: nil))
//            self.present(alert, animated: true)
//        } else {
//            self.startPlaying()
//            isPlaying = true
//        }
    }
    
    func startPlaying() {
        
        CommandCenter.shared.updateLockScreenInfo()
  
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
        
        for playerNode in activePlayerNodesSet {
            playerNode.pause()
        }
    }
    
    func stopPlaying() {
        
        //updateLockScreenInfo()
        //removeCommandCenter()
           
        for playerNode in activePlayerNodesSet {
            playerNode.stop()
        }
        self.audioEngine.stop()
        
        activePlayerNodesSet = Set<AVAudioPlayerNode>()
        
        self.playButton.setImage(Button.playOnImg, for: .normal)
        //self.rewindButton.isEnabled = false
        timer?.invalidate()
    }
    
    func playInduction(type: Induction) {
        
        audioQueue.async {
            
            let audioPlayerNode = AVAudioPlayerNode()
            //self.activePlayerNodesSet.insert(audioPlayerNode)
            
            self.audioEngine.attach(self.mixer)
            self.audioEngine.attach(audioPlayerNode)
            
            self.audioEngine.stop()
            
            let filename = type == .Intro ? spokenIntro : spokenOutro
            
            let avAudioFile = try! AVAudioFile(forReading: getFileFromMainBundle(filename: filename)!)
            let format =  AVAudioFormat(standardFormatWithSampleRate: avAudioFile.fileFormat.sampleRate, channels: avAudioFile.fileFormat.channelCount)
            
            self.audioEngine.connect(audioPlayerNode, to: self.mixer, format: format)
            self.audioEngine.connect(self.mixer, to: self.audioEngine.outputNode, format: format)
            
            try! self.audioEngine.start()
              
            audioPlayerNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
                (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                
                DispatchQueue.main.async {
                    
                    self.spectrumViewController?.processAudioData(buffer: buffer)
                    self.volumeViewController?.processAudioData(buffer: buffer)
                }
            }
            
            let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: avAudioFile.processingFormat, frameCapacity: AVAudioFrameCount(avAudioFile.length))!
            try! avAudioFile.read(into: audioFileBuffer)
            
            audioPlayerNode.scheduleBuffer(audioFileBuffer, completionHandler: {
                //self.audioEngine.stop()
                StateMachine.shared.doNextState()
            })
            
            audioPlayerNode.scheduleFile(avAudioFile, at: nil, completionHandler: nil)
            audioPlayerNode.play()
        }
    }
    
    func playAffirmation(loop: Bool) {
        
        audioQueue.async {
            do {
                self.audioEngine.attach(self.mixer)
                
                self.audioEngine.stop()
                
                let audioFile = self.audioFiles.first
                self.loudAffirmationAudioNode = audioFile!.audioPlayer
                self.activePlayerNodesSet.insert(self.loudAffirmationAudioNode)
                self.audioEngine.attach(self.loudAffirmationAudioNode)
                
                let avAudioFile = try AVAudioFile(forReading: getFileFromSandbox(filename: audioFile!.filename))
                let format =  AVAudioFormat(standardFormatWithSampleRate: avAudioFile.fileFormat.sampleRate, channels: avAudioFile.fileFormat.channelCount)
                
                self.loudAffirmationAudioNode.removeTap(onBus: 0)

                self.audioEngine.connect(self.loudAffirmationAudioNode, to: self.mixer, format: format)
                
                self.audioEngine.connect(self.mixer, to: self.audioEngine.outputNode, format: format)
                try self.audioEngine.start()
                
                self.loudAffirmationAudioNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
                    (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                    
                    DispatchQueue.main.async {
                        
                        if loop && self.loudAffirmationAudioNode.current >= 10 {
                            self.loudAffirmationAudioNode.stop()
                            self.audioEngine.stop()
                            StateMachine.shared.doNextState()
                        }
                        
                        if StateMachine.shared.affirmationState == .loud {
                            self.spectrumViewController?.processAudioData(buffer: buffer)
                            self.volumeViewController?.processAudioData(buffer: buffer)
                        }
                    }
                }
                
                let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: avAudioFile.processingFormat, frameCapacity: AVAudioFrameCount(avAudioFile.length))!
                try avAudioFile.read(into: audioFileBuffer)
                
                if loop {
                    self.loudAffirmationAudioNode.scheduleBuffer(audioFileBuffer, at: nil, options:.loops, completionHandler: nil)
                    self.playSilentLoop()
                } else {
                    self.loudAffirmationAudioNode.scheduleBuffer(audioFileBuffer, completionHandler: {
                        self.activePlayerNodesSet.remove(self.loudAffirmationAudioNode)
                        StateMachine.shared.doNextState()
                    })
                }

                self.loudAffirmationAudioNode.play()
 
            } catch {
                print("File read error", error)
            }
        }
    }
    
    func playLoop() {
        
        audioQueue.async {
            do {
                
                let highPass = self.equalizerHighPass.bands[0]
                highPass.filterType = .highPass
                highPass.frequency = modulationFrequency
                highPass.bandwidth = bandwidth
                highPass.bypass = false
                
                self.audioEngine.attach(self.equalizerHighPass)
                self.audioEngine.attach(self.mixer)
                
                // !important - start the engine *before* setting up the player nodes
                //try self.audioEngine.start()
                self.audioEngine.stop()
                
                for audioFile in self.audioFiles {
                    //self.audioEngine.stop()
                    // Create and attach the audioPlayer node for this file
                    let audioPlayerNode = audioFile.audioPlayer
                    self.activePlayerNodesSet.insert(audioPlayerNode)
                    self.audioEngine.attach(audioPlayerNode)
                    
                    let avAudioFile = try AVAudioFile(forReading: getFileFromSandbox(filename: audioFile.filename))
                    let format =  AVAudioFormat(standardFormatWithSampleRate: avAudioFile.fileFormat.sampleRate, channels: avAudioFile.fileFormat.channelCount)
                    
                    audioPlayerNode.removeTap(onBus: 0)
                    
                    if audioFile.isSilent {
                        self.audioEngine.connect(audioPlayerNode, to: self.equalizerHighPass, format: format)
                        self.audioEngine.connect(self.equalizerHighPass, to: self.mixer, format: format)
                        
                    } else {
                        self.audioEngine.connect(audioPlayerNode, to: self.mixer, format: format)
                    }
                    
                    self.audioEngine.connect(self.mixer, to: self.audioEngine.outputNode, format: format)
                    try self.audioEngine.start()
                    
                    audioPlayerNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
                        (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                        
                        DispatchQueue.main.async {
                            
                            if self.loudAffirmationAudioNode.current >= 10 {
                                self.loudAffirmationAudioNode.stop()
                                self.audioEngine.stop()
                                if StateMachine.shared.playerState == .affirmationLoop {
                                    StateMachine.shared.doNextState()
                                }
                            }
                            
                            if StateMachine.shared.affirmationState == .loud {
                                self.spectrumViewController?.processAudioData(buffer: buffer)
                                self.volumeViewController?.processAudioData(buffer: buffer)
                            }
                        }
                    }
                    
                    //self.switchAndAnalyze(audioFile: audioFile)
                    
                    let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: avAudioFile.processingFormat, frameCapacity: AVAudioFrameCount(avAudioFile.length))!
                    try avAudioFile.read(into: audioFileBuffer)
                    
                    audioPlayerNode.scheduleBuffer(audioFileBuffer, at: nil, options:.loops, completionHandler: nil)
                    audioPlayerNode.play()
 
                }
            } catch {
                print("File read error", error)
            }
        }
    }
    
    func playSilentLoop() {
        
        //audioQueue.async {
            do {
                
                let highPass = self.equalizerHighPass.bands[0]
                highPass.filterType = .highPass
                highPass.frequency = modulationFrequency
                highPass.bandwidth = bandwidth
                highPass.bypass = false
                
                self.audioEngine.attach(self.equalizerHighPass)
                self.audioEngine.attach(self.mixer)
                
                //self.audioEngine.stop()
                
                let audioFile = audioFiles.last
                self.silentAffirmationAudioNode = audioFile!.audioPlayer
                self.activePlayerNodesSet.insert(self.silentAffirmationAudioNode)
                self.audioEngine.attach(self.silentAffirmationAudioNode)
                
                let avAudioFile = try AVAudioFile(forReading: getFileFromSandbox(filename: audioFile!.filename))
                let format =  AVAudioFormat(standardFormatWithSampleRate: avAudioFile.fileFormat.sampleRate, channels: avAudioFile.fileFormat.channelCount)
                
                self.silentAffirmationAudioNode.removeTap(onBus: 0)
                
                self.audioEngine.connect(self.silentAffirmationAudioNode, to: self.equalizerHighPass, format: format)
                self.audioEngine.connect(self.equalizerHighPass, to: self.mixer, format: format)
                
                self.audioEngine.connect(self.mixer, to: self.audioEngine.outputNode, format: format)
                try self.audioEngine.start()
                
                self.silentAffirmationAudioNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
                    (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                    
                    DispatchQueue.main.async {
                        
                        if StateMachine.shared.affirmationState == .silent {
                            self.spectrumViewController?.processAudioData(buffer: buffer)
                            self.volumeViewController?.processAudioData(buffer: buffer)
                        }
                       
                        if self.silentAffirmationAudioNode.current >= 4 {
                            self.silentAffirmationAudioNode.stop()
                            self.audioEngine.stop()
                            StateMachine.shared.doNextState()
                        }
                    }
                }

                let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: avAudioFile.processingFormat, frameCapacity: AVAudioFrameCount(avAudioFile.length))!
                try avAudioFile.read(into: audioFileBuffer)
                
                self.silentAffirmationAudioNode.scheduleBuffer(audioFileBuffer, at: nil, options:.loops, completionHandler: nil)
                self.silentAffirmationAudioNode.play()
                
            } catch {
                print("File read error", error)
            }
       // }
    }

    fileprivate func switchAndAnalyze(audioFile: AudioFileTypes) {
        //if !affirmationIsRunning { return }
        if !self.audioEngine.isRunning { return }
        
        let audioPlayer = audioFile.audioPlayer
        let volume = VolumeManager.shared.sliderVolume
        audioPlayer.volume = (audioFile.isSilent ? (StateMachine.shared.affirmationState == .silent ? volume : 0) : (StateMachine.shared.affirmationState == .silent ? 0 : volume))
        
        let audioFilename = getFileFromSandbox(filename: audioFile.filename)
        let avAudioFile = try! AVAudioFile(forReading: audioFilename)
        let format =  AVAudioFormat(standardFormatWithSampleRate: avAudioFile.fileFormat.sampleRate, channels: avAudioFile.fileFormat.channelCount)
        
        //audioPlayer.volume = audioFile.isSilent ? (self.isSilentMode ? self.masterVolume : 0) : (self.isSilentMode ? 0 : self.masterVolume)
        audioPlayer.removeTap(onBus: 0)
        
        
//        if self.isSilentMode && audioFile.isSilent || !self.isSilentMode && !audioFile.isSilent {
//
//            audioPlayer.installTap(onBus: 0, bufferSize: 1024, format: format) {
//                (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
//
//                DispatchQueue.main.async {
//
//                    self.processAudioData(buffer: buffer)
//
//                    let volume = self.getVolume(from: buffer, bufferSize: 1024) * (deviceVolume ?? 0.5) * self.masterVolume
//                    self.displayVolume(volume: volume)
//                }
//            }
//        }
    }
      
    // MARK: BackButtonDelegate
    func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

}
