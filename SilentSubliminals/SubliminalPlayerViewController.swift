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

// https://medium.com/@ian.mundy/audio-mixing-on-ios-4cd51dfaac9a
class SubliminalPlayerViewController: UIViewController {
    
    @IBOutlet weak var graphView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var silentButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var playerView: RoundedView!
    @IBOutlet weak var soundView: RoundedView!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var volumeView: UIView!
    let maskView = UIView()
    
    struct AudioFileTypes {
        var filename = ""
        var isSilent = false
        var audioPlayer = AVAudioPlayerNode()
    }
    
    private var audioFiles: Array<AudioFileTypes> = [AudioFileTypes(filename: spokenAffirmation, isSilent: false), AudioFileTypes(filename: spokenAffirmationSilent, isSilent: true)]

    var activePlayerNodesSet = Set<AVAudioPlayerNode>()
    
    private var audioEngine: AVAudioEngine = AVAudioEngine()
    private var mixer: AVAudioMixerNode = AVAudioMixerNode()
    private var equalizerHighPass: AVAudioUnitEQ = AVAudioUnitEQ(numberOfBands: 1)
    
    var fftSetup : vDSP_DFT_Setup?
    
    var isStopped: Bool = false
    var isPlaying: Bool = false
    var isPausing: Bool = false
    var isSilentMode: Bool = false
    var affirmationIsRunning: Bool = false
    var masterVolume: Float = 0.5
    
    var timer: Timer?
    let affirmationLoopDuration = 5 * 60
    
    var audioFileBuffer: AVAudioPCMBuffer?
    var audioFrameCount: UInt32?
    
    let spectrumLayer = CAShapeLayer.init()
    
    var frequencyDomainGraphLayerIndex = 0
    let frequencyDomainGraphLayers = [CAShapeLayer(), CAShapeLayer(),
                                      CAShapeLayer(), CAShapeLayer()]
    
    var introDuration: TimeInterval?
    var outroDuration: TimeInterval?
    var singleAffirmationDuration: TimeInterval?
    var totalLength: TimeInterval?
    var currentTimeInterval: TimeInterval?
    
    let audioQueue: DispatchQueue = DispatchQueue(label: "PlayerQueue", attributes: [])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        frequencyDomainGraphLayers.forEach {
            self.graphView.layer.addSublayer($0)
        }
        
        let backbutton = UIButton(type: .custom)
        backbutton.setImage(UIImage(named: "arrow-left.png"), for: [.normal])
        backbutton.addTarget(self, action: #selector(self.close(_:)), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backbutton)
        
        graphView.layer.cornerRadius = cornerRadius
        graphView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        playerView.imageView = backgroundImageView
        soundView.imageView = backgroundImageView
        
        volumeSlider.value = masterVolume
        
        //resetButton.isEnabled = false
        
        let colors = [UIColor.blue, UIColor.green, UIColor.yellow, UIColor.red]
        self.maskView.backgroundColor = .white
        self.volumeView.showGradientColors(colors)
        self.volumeView.addSubview(self.maskView)
        self.volumeView.mask = self.maskView
        self.maskView.frame = .zero
        
        fftSetup = vDSP_DFT_zop_CreateSetup(nil, 1024, vDSP_DFT_Direction.FORWARD)
        
        checkForPermission()
        
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            let ioBufferDuration = 128.0 / 44100.0
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(ioBufferDuration)
        } catch {
            assertionFailure("AVAudioSession setup error: \(error)")
        }
        
//        do {
//            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
//            //try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
//            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
//            let ioBufferDuration = 128.0 / 44100.0
//            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(ioBufferDuration)
//        } catch {
//            assertionFailure("AVAudioSession setup error: \(error)")
//        }
        

        self.introDuration = try? AVAudioFile(forReading: getFileFromMainBundle(filename: spokenIntro)!).duration
        self.outroDuration = try? AVAudioFile(forReading: getFileFromMainBundle(filename: spokenOutro)!).duration
        self.singleAffirmationDuration = try? AVAudioFile(forReading: getFileFromSandbox(filename: spokenAffirmation)).duration
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlaying()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        frequencyDomainGraphLayers.forEach {
            $0.frame = self.graphView.frame.insetBy(dx: 0, dy: 0)
        }
    }
    
    @IBAction func playButtonTouchUpInside(_ sender: Any) {
        
        if isPlaying == false {
            startPlaying()
            isPlaying = true
        } else {
            pausePlaying()
            isPlaying = false
        }
    }
    
    
    func startPlaying() {
        
        isStopped = false
        
        playButton.setImage(Button.playOffImg, for: .normal)
        
        if isPausing == true {
            
            for playerNode in activePlayerNodesSet {
                playerNode.play()
            }
            
            return
        }
        
        self.playInduction(type: Induction.Intro) {_ in
            print("Intro terminated")
            self.affirmationIsRunning = true
            DispatchQueue.main.async {
                self.resetButton.isEnabled = true
            }
            
            if self.isStopped { return }
            
            self.playAffirmationLoop {_ in
                print("Affirmation terminated")
                self.affirmationIsRunning = false
                self.timer?.invalidate()
                self.timer = nil
                self.playInduction(type: Induction.Outro) { [self]_ in
                    print("Outro terminated")
                    isPausing = false
                    isPlaying = false
                    DispatchQueue.main.async {
                        self.playButton.setImage(Button.playOnImg, for: .normal)
                        self.resetButton.isEnabled = false
                    }
                }
            }
        }
    }
    
    func pausePlaying() {
        
        for playerNode in activePlayerNodesSet {
            playerNode.pause()
        }
        
        self.playButton.setImage(Button.playOnImg, for: .normal)
        isPausing = true
    }
    
    func stopPlaying() {
        
        isStopped = true
        
        for playerNode in activePlayerNodesSet {
            playerNode.stop()
        }
        self.audioEngine.stop()
        
        activePlayerNodesSet = Set<AVAudioPlayerNode>()
        
        self.playButton.setImage(Button.playOnImg, for: .normal)
        self.resetButton.isEnabled = false
        isPausing = false
        isPlaying = false
    }
    
    func playInduction(type: Induction, completion: @escaping (Bool) -> Void) {
        
        audioQueue.async {
            
            let audioPlayerNode = AVAudioPlayerNode()
            self.activePlayerNodesSet.insert(audioPlayerNode)
            
            self.audioEngine.attach(self.mixer)
            self.audioEngine.attach(audioPlayerNode)
            
            self.audioEngine.stop()

            let filename = type == .Intro ? spokenIntro : spokenOutro
            
            let avAudioFile = try! AVAudioFile(forReading: getFileFromMainBundle(filename: filename)!)
            let format =  AVAudioFormat(standardFormatWithSampleRate: avAudioFile.fileFormat.sampleRate, channels: avAudioFile.fileFormat.channelCount)
            
            self.audioEngine.connect(audioPlayerNode, to: self.mixer, format: format)
            self.audioEngine.connect(self.mixer, to: self.audioEngine.outputNode, format: format)
            
            try! self.audioEngine.start()
            
            let audioSession = AVAudioSession.sharedInstance()
            var deviceVolume: Float?
            
            do {
                try audioSession.setActive(true)
                deviceVolume = audioSession.outputVolume
            } catch {
                print("Error Setting Up Audio Session")
            }
            
            audioPlayerNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
                (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in

                DispatchQueue.main.async {

                    self.processAudioData(buffer: buffer)

                    let volume = self.getVolume(from: buffer, bufferSize: 1024) * (deviceVolume ?? 0.5) * self.masterVolume
                    self.displayVolume(volume: volume)
                }
            }
            
            let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: avAudioFile.processingFormat, frameCapacity: AVAudioFrameCount(avAudioFile.length))!
            try! avAudioFile.read(into: audioFileBuffer)
            
            audioPlayerNode.scheduleBuffer(audioFileBuffer, completionHandler: {
                //self.audioEngine.stop()
                self.activePlayerNodesSet.remove(audioPlayerNode)
                completion(true)
            })
            
            audioPlayerNode.scheduleFile(avAudioFile, at: nil, completionHandler: nil)
            audioPlayerNode.play()
        }
    }
    
    func playAffirmationLoop(completion: @escaping (Bool) -> Void) {
        
        var elpasedTime = 0
        
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
                    
                    self.switchAndAnalyze(audioFile: audioFile)
                    
                    let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: avAudioFile.processingFormat, frameCapacity: AVAudioFrameCount(avAudioFile.length))!
                    try avAudioFile.read(into: audioFileBuffer)
                    
                    audioPlayerNode.scheduleBuffer(audioFileBuffer, at: nil, options:.loops, completionHandler: nil)
                    audioPlayerNode.play()
                    
                    var switchedAutomaticallyToSilent = false
                    
                    DispatchQueue.main.async {
                        
                        if self.timer != nil { return }
                        
                        self.timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
                            print(elpasedTime)
                            elpasedTime += 1
                            
                            if audioPlayerNode.current <= self.singleAffirmationDuration! {
                                // loud
                                self.isSilentMode = false
                                for audioFile in self.audioFiles {
                                    self.switchAndAnalyze(audioFile: audioFile)
                                }
                                self.silentButton.setImage(Button.silentOffImg, for: .normal)
                            } else {
                                // silent
                                if !switchedAutomaticallyToSilent {
                                    self.isSilentMode = true
                                    for audioFile in self.audioFiles {
                                        self.switchAndAnalyze(audioFile: audioFile)
                                    }
                                    switchedAutomaticallyToSilent = true
                                    self.silentButton.setImage(Button.silentOnImg, for: .normal)
                                }
                            }

                            
                            if Int(audioPlayerNode.current) >= self.affirmationLoopDuration {
                                self.activePlayerNodesSet = Set<AVAudioPlayerNode>()
                                audioPlayerNode.stop()
                                self.audioEngine.stop()
                                completion(true)
                            }
                        }
                    }
                }
            } catch {
                print("File read error", error)
            }
        }
    }
    
    
    @IBAction func resetButtonTouched(_ sender: Any) {
        
        stopPlaying()
    }
    
    @IBAction func silentButtonTouched(_ sender: Any) {
        
        isSilentMode = !isSilentMode
        
        let buttonImage = isSilentMode ? Button.silentOnImg : Button.silentOffImg
        self.silentButton.setImage(buttonImage, for: .normal)
        for audioFile in self.audioFiles {
            self.switchAndAnalyze(audioFile: audioFile)
        }
    }
    
    fileprivate func switchAndAnalyze(audioFile: SubliminalPlayerViewController.AudioFileTypes) {
        if !affirmationIsRunning { return }
        if !self.audioEngine.isRunning { return }
        
        let audioPlayer = audioFile.audioPlayer
        audioPlayer.volume = audioFile.isSilent ? (isSilentMode ? masterVolume : 0) : (isSilentMode ? 0 : masterVolume)
        
        let audioFilename = getFileFromSandbox(filename: audioFile.filename)
        let avAudioFile = try! AVAudioFile(forReading: audioFilename)
        let format =  AVAudioFormat(standardFormatWithSampleRate: avAudioFile.fileFormat.sampleRate, channels: avAudioFile.fileFormat.channelCount)
        
        audioPlayer.volume = audioFile.isSilent ? (self.isSilentMode ? self.masterVolume : 0) : (self.isSilentMode ? 0 : self.masterVolume)
        audioPlayer.removeTap(onBus: 0)
        
        let audioSession = AVAudioSession.sharedInstance()
        var deviceVolume: Float?
        
        do {
            try audioSession.setActive(true)
            deviceVolume = audioSession.outputVolume
        } catch {
            print("Error Setting Up Audio Session")
        }

        if self.isSilentMode && audioFile.isSilent || !self.isSilentMode && !audioFile.isSilent {

            audioPlayer.installTap(onBus: 0, bufferSize: 1024, format: format) {
                (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
  
                DispatchQueue.main.async {
                    
                    self.processAudioData(buffer: buffer)

                    let volume = self.getVolume(from: buffer, bufferSize: 1024) * (deviceVolume ?? 0.5) * self.masterVolume
                    self.displayVolume(volume: volume)
                }
            }
        }
    }
    
    func displayVolume(volume: Float) {
            
            let w = Double(self.volumeView.frame.size.width)
            let h = Double(self.volumeView.bounds.size.height)
     
            UIView.animate(withDuration: 0.2) {
                self.maskView.frame = CGRect(x: 0.0, y: 0.0, width: Double(5 * volume) * w, height: h)
            }
            
        }
    
    @IBAction func volumeSliderChanged(_ sender: Any) {
        
        masterVolume = Float(volumeSlider.value)
        

        for playerNode in activePlayerNodesSet {
            playerNode.volume = masterVolume
            //print(playerNode.volume)
        }
        for audioFile in self.audioFiles {
            let audioPlayer = audioFile.audioPlayer
            audioPlayer.volume = audioFile.isSilent ? (isSilentMode ? masterVolume : 0) : (isSilentMode ? 0 : masterVolume)
        }
    }
    
    @IBAction func close(_ sender: UIButton) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    private func getVolume(from buffer: AVAudioPCMBuffer, bufferSize: Int) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else {
            return 0
        }
        
        let channelDataArray = Array(UnsafeBufferPointer(start:channelData, count: bufferSize))
        
        var outEnvelope = [Float]()
        var envelopeState:Float = 0
        let envConstantAtk:Float = 0.16
        let envConstantDec:Float = 0.003
        
        for sample in channelDataArray {
            let rectified = abs(sample)
            
            if envelopeState < rectified {
                envelopeState += envConstantAtk * (rectified - envelopeState)
            } else {
                envelopeState += envConstantDec * (rectified - envelopeState)
            }
            outEnvelope.append(envelopeState)
        }
        
        // 0.007 is the low pass filter to prevent
        // getting the noise entering from the microphone
        if let maxVolume = outEnvelope.max(),
           maxVolume > Float(0.015) {
            return maxVolume
        } else {
            return 0.0
        }
    }
    
    func processAudioData(buffer: AVAudioPCMBuffer){
        
        guard let channelData = buffer.floatChannelData?[0] else {return}
        let frames = buffer.frameLength
        
        let rmsValue = SignalProcessing.rms(data: channelData, frameLength: UInt(frames))
        
        if rmsValue == -.infinity { return }
        
        spectrumLayer.removeFromSuperlayer()
        
        
        //fft
        let fftMagnitudes: [Float] =  SignalProcessing.fft(data: channelData, setup: fftSetup!)
        
        let path = UIBezierPath.init()
        let width = graphView.frame.size.width
        let height = graphView.frame.size.height
        
        var maxFFT: Float = 0
        
        for magn in fftMagnitudes {
            if magn.magnitude > maxFFT {
                maxFFT = magn.magnitude
            }
        }
        
        if maxFFT == 0 { return }
        
        path.move(to: CGPoint(x: 0, y: height))
        
        var x1: CGFloat = 0
        var y1: CGFloat = height
        var x2: CGFloat = 0
        var y2: CGFloat = height
        
        for (index, element) in fftMagnitudes.enumerated() {
            //print("Item \(index): \(element)")
            
            x2 = x1
            y2 = y1
            
            //            if index == fftMagnitudes.count / 4 {
            //                break
            //            }
            
            let xUnit = width / log10(1000)
            
            x1 = CGFloat(log10f(Float(index + 1))) * xUnit //CGFloat(4 * index) * width / CGFloat(fftMagnitudes.count)
            y1 = height - CGFloat(rmsValue / 80) * CGFloat(element.magnitude) * height / CGFloat(maxFFT)
            
            if y1 < 0 {
                y1 = 0
            }
            
            //path.addLine(to: CGPoint(x: x, y: y))
            
            if x1 > width {
                break
            }
            
            path.addQuadCurve(to: CGPoint(x: x1, y: y1), controlPoint: CGPoint(x: x2, y: y2))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        
        path.close()
        
        spectrumLayer.path = path.cgPath
        spectrumLayer.fillColor = UIColor.green.cgColor
        graphView.layer.addSublayer(spectrumLayer)
    }
    
    func checkForPermission() {
        Manager.recordingSession = AVAudioSession.sharedInstance()
        do {
            try Manager.recordingSession.setCategory(AVAudioSession.Category.playAndRecord, options: .defaultToSpeaker)
            
            Manager.recordingSession.requestRecordPermission({ (allowed) in
                if allowed {
                    Manager.micAuthorised = true
                    DispatchQueue.main.async {
                        self.playButton.alpha = 1
                        self.playButton.isEnabled = true
                    }
                    print("Mic Authorised")
                } else {
                    Manager.micAuthorised = false
                    print("Mic not Authorised")
                }
            })
        } catch {
            print("Failed to set Category", error.localizedDescription)
        }
    }
    
}


extension UIView {
    
    enum GradientColorDirection {
        case vertical
        case horizontal
    }
    
    func showGradientColors(_ colors: [UIColor], opacity: Float = 0.8, direction: GradientColorDirection = .horizontal) {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.opacity = opacity
        gradientLayer.colors = colors.map { $0.cgColor }
        
        if case .horizontal = direction {
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.0)
        }
        
        gradientLayer.locations = [0.0, 0.2, 0.4, 0.6]
        
        gradientLayer.bounds = self.bounds  //CGRect(x: 0, y: 0, width: 100, height: 20)//self.bounds
        gradientLayer.anchorPoint = CGPoint.zero
        gradientLayer.cornerRadius = self.layer.cornerRadius
        self.layer.addSublayer(gradientLayer)
    }
    
}


extension AVMutableCompositionTrack {
    
    func append(url: URL) {
        let newAsset = AVURLAsset(url: url)
        let range = CMTimeRangeMake(start: CMTime.zero, duration: newAsset.duration)
        let end = timeRange.end
        print(end)
        if let track = newAsset.tracks(withMediaType: AVMediaType.audio).first {
            try! insertTimeRange(range, of: track, at: end)
        }
    }
}

extension AVAudioFile {

    var duration: TimeInterval {
        let sampleRateSong = Double(processingFormat.sampleRate)
        let lengthSongSeconds = Double(length) / sampleRateSong
        print("**********************")
        print(length)
        return lengthSongSeconds
    }
}

extension AVAudioPlayerNode {

    var current: TimeInterval {
        if let nodeTime = lastRenderTime,let playerTime = playerTime(forNodeTime: nodeTime) {
            return Double(playerTime.sampleTime) / playerTime.sampleRate
        }
        return 0
    }
}

extension AVPlayer {

    var isPlaying2: Bool {
        return ((rate != 0) && (error == nil))
    }
}
