//
//  ViewController.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 10.05.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import CoreAudio
import AVFoundation
import Accelerate
import PureLayout

//let sampleCount = 512

let alpha: CGFloat = 0.85


class SubliminalMakerViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var graphView: UIView!
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    var writer: AVAssetWriter?
    var isRecording: Bool = false
    var isPlaying: Bool = false
    

    var recording: Bool = false
    var playing: Bool = false
    
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayerNode?
    
    var engine = AVAudioEngine()
    var distortion = AVAudioUnitDistortion()
    var reverb = AVAudioUnitReverb()
    var audioBuffer = AVAudioPCMBuffer()
    var outputFile = AVAudioFile()
    var delay = AVAudioUnitDelay()
    var fftSetup : vDSP_DFT_Setup?
    
    let spectrumLayer = CAShapeLayer.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backbutton = UIButton(type: .custom)
        backbutton.setImage(UIImage(named: "backButton.png"), for: [.normal])
        backbutton.tintColor = PlayerControlColor.lightColor
        backbutton.addTarget(self, action: #selector(self.close(_:)), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backbutton)
        
        view.layer.contents = #imageLiteral(resourceName: "subliminalMakerBackground.png").cgImage
        
        playerView.layer.cornerRadius = cornerRadius
        controlView.layer.cornerRadius = playerView.layer.cornerRadius
        controlView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        controlView.alpha = alpha
        containerView.alpha = alpha
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.autoPinEdge(.top, to: .bottom, of: self.view)
        
        graphView.layer.cornerRadius = cornerRadius
        graphView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        recordButton.alpha = 0.1
        recordButton.isEnabled = false
        
        print(getDocumentsDirectory())
        
        // Clean tempFiles !
        //AKAudioFile.cleanTempDirectory()
        
        checkForPermission()
        
        //initializeAudioEngine()
        
        fftSetup = vDSP_DFT_zop_CreateSetup(nil, 1024, vDSP_DFT_Direction.FORWARD)
        
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
            let ioBufferDuration = 128.0 / 44100.0
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(ioBufferDuration)
        } catch {
            assertionFailure("AVAudioSession setup error: \(error)")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopPlaying()
    }
    
    func createSilentSubliminalFile() {
        
        let file = try! AVAudioFile(forReading: getFileFromSandbox(filename: spokenAffirmation))
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        
        engine.attach(player)
        
        //engine.connect(player, to:engine.mainMixerNode, format: AVAudioFormat.init(standardFormatWithSampleRate: sampleRate, channels: 1))
        let busFormat = AVAudioFormat(standardFormatWithSampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount)
        
        engine.disconnectNodeInput(engine.outputNode, bus: 0)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: busFormat)
        
        engine.connect(player, to:engine.mainMixerNode, format: busFormat)
        
        print(engine)
        
        // Run the engine in manual rendering mode using chunks of 512 frames
        let renderSize: AVAudioFrameCount = 512
        
        // Use the file's processing format as the rendering format
        let renderFormat = AVAudioFormat(commonFormat: file.processingFormat.commonFormat, sampleRate: file.processingFormat.sampleRate, channels: file.processingFormat.channelCount, interleaved: true)!
        let renderBuffer = AVAudioPCMBuffer(pcmFormat: renderFormat, frameCapacity: renderSize)!
        
        try! engine.enableManualRenderingMode(.offline, format: renderFormat, maximumFrameCount: renderBuffer.frameCapacity)
        
        try! engine.start()
        player.play()
        
        // Read using a buffer sized to produce `renderSize` frames of output
        let readBuffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: renderSize)!
        
        var settings: [String : Any] = [:]
        
        settings[AVFormatIDKey] = kAudioFormatAppleLossless
        settings[AVAudioFileTypeKey] = kAudioFileM4AType
        settings[AVSampleRateKey] = readBuffer.format.sampleRate
        settings[AVNumberOfChannelsKey] = 1
        settings[AVLinearPCMIsFloatKey] = (readBuffer.format.commonFormat == .pcmFormatInt32)
        settings[AVSampleRateConverterAudioQualityKey] = AVAudioQuality.max
        settings[AVLinearPCMBitDepthKey] = 32
        settings[AVEncoderAudioQualityKey] = AVAudioQuality.max
        
        // The render format is also the output format
        let output = try! AVAudioFile(forWriting: getFileFromSandbox(filename: spokenAffirmationSilent), settings: settings, commonFormat: renderFormat.commonFormat, interleaved: renderFormat.isInterleaved)
        
        var index: Int = 0;
        // Process the file
        while true {
            do {
                // Processing is finished if all frames have been read
                if file.framePosition == file.length {
                    break
                }
                
                try file.read(into: readBuffer)
                player.scheduleBuffer(readBuffer, completionHandler: nil)
                
                let result = try engine.renderOffline(readBuffer.frameLength, to: renderBuffer)
                
                // Process the audio in `renderBuffer` here
                for i in 0..<Int(renderBuffer.frameLength) {
                    let val: Double =  Double(1) * sin(Double(2 * modulationFrequency) * Double(index) * Double.pi / Double(renderBuffer.format.sampleRate))
                    let sourceData: Double = Double((readBuffer.floatChannelData?.pointee[i])!)
                    //let val: Double = Double(10) * sin(Double(2) * Double.pi * Double(modulationFrequency + Double(0.25 * sourceData)) * Double(index)  / Double(renderBuffer.format.sampleRate))
                    let targetData: Double = val * sourceData
                    renderBuffer.floatChannelData?.pointee[i] = Float(targetData)
                    index += 1
                }
                
                if index == Int(file.fileFormat.sampleRate) {
                    index = 0
                }
                
                // Write the audio
                try output.write(from: renderBuffer)
                if result != .success {
                    break
                }
            }
            catch {
                break
            }
        }
        
        player.stop()
        engine.stop()
    }
    
    
    func initializeAudioEngine() {
        
        engine.stop()
        engine.reset()
        engine = AVAudioEngine()
        
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
            let ioBufferDuration = 128.0 / 44100.0
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(ioBufferDuration)
        } catch {
            assertionFailure("AVAudioSession setup error: \(error)")
        }
    }
    
    
    @IBAction func scriptCreationButtonTouched(_ sender: Any) {
        
        let offset = 0.1 * view.frame.size.height
        containerView.autoPinEdge(.bottom, to: .bottom, of: view, withOffset: -offset)
        
        UIView.animate(withDuration: 0.45) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    @IBAction func recordButtonTouched(_ sender: Any) {
        
        if isRecording == false {
            startRecording()
            isRecording = true
        } else {
            stopRecording(success: true)
            isRecording = false
        }
    }
    
    @IBAction func playButtonTouched(_ sender: Any) {
        
        if isPlaying == false {
            startPlaying()
            isPlaying = true
        } else {
            stopPlaying()
            isPlaying = false
        }
    }
    
    func startPlaying() {
        
        playButton.setImage(Button.playOffImg, for: .normal)
        recordButton.isEnabled = false;
        
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
            let ioBufferDuration = 128.0 / 44100.0
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(ioBufferDuration)
        } catch {
            assertionFailure("AVAudioSession setup error: \(error)")
        }
        
        
        var audioBuffer: AVAudioPCMBuffer!
        engine = AVAudioEngine()
        _ = engine.mainMixerNode
        
        let inputNode = engine.inputNode
        let bus = 0
        inputNode.installTap(onBus: bus, bufferSize: 1024, format: inputNode.inputFormat(forBus: bus)) {
            (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
            
            DispatchQueue.main.async {
                self.processAudioData(buffer: buffer)
            }
        }
        
        engine.prepare()
        do {
            try engine.start()
        } catch {
            print(error)
        }
        
        let audioFilename = getFileFromSandbox(filename: spokenAffirmation)
        
        do {
            let audioFile = try AVAudioFile(forReading: audioFilename)
            let format = audioFile.processingFormat
            
            audioPlayer = AVAudioPlayerNode()
            audioPlayer?.volume = 1.0
            engine.attach(audioPlayer!)
            engine.connect(audioPlayer!, to: engine.mainMixerNode, format: format)
            
            audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))!
            
            do {
                print("read")
                try audioFile.read(into: audioBuffer)
            } catch _ {
                print("error reading audiofile into buffer")
            }
            
            audioPlayer?.scheduleBuffer(audioBuffer, completionHandler: {
                
                DispatchQueue.main.async {
                    if self.audioPlayer != nil {
                        self.stopPlaying()
                    }
                }
            })
            
            audioPlayer!.scheduleFile(audioFile, at: nil, completionHandler: nil)
        } catch {
            print("could not load file")
        }
        
        audioPlayer?.play()
    }
    
    func stopPlaying() {
        
        DispatchQueue.main.async {
            self.recordButton.isEnabled = true;
            self.playButton.setImage(Button.playOnImg, for: .normal)
            self.spectrumLayer.removeFromSuperlayer()
        }
        
        guard let player = audioPlayer else {
            return
        }
        
        engine.detach(player)
        
        player.stop()
        //player = nil
        isPlaying = false
        
        let inputNode = engine.inputNode
        let bus = 0
        inputNode.removeTap(onBus: bus)
        self.engine.stop()
    }
    
    func startRecording() {
        
        initializeAudioEngine()
        
        let inputNode = engine.inputNode
        let bus = 0
        inputNode.installTap(onBus: bus, bufferSize: 1024, format: inputNode.inputFormat(forBus: bus)) {
            (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
            
            DispatchQueue.main.async {
                self.processAudioData(buffer: buffer)
            }
        }
        
        engine.prepare()
        try! engine.start()
        let audioFilename = getFileFromSandbox(filename: spokenAffirmation)
        
        let settings = [
            //AVFormatIDKey: Int(kAudioFormatM4a),
            //AVAudioFileTypeKey: kAudioFileM4AType,
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 48000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ] as [String : Any]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            self.playButton.isEnabled = false
            recordButton.setImage(Button.micOffImg, for: .normal)
        } catch {
            print(error)
            stopRecording(success: false)
        }
    }
    
    func stopRecording(success: Bool) {
        
        DispatchQueue.main.async {
            self.playButton.isEnabled = true
            self.recordButton.setImage(Button.micOnImg, for: .normal)
            self.spectrumLayer.removeFromSuperlayer()
        }
        
        audioRecorder?.stop()
        audioRecorder = nil
        
        let inputNode = engine.inputNode
        inputNode.removeTap(onBus: 0)
        self.engine.stop()
        
        let audioQueue: DispatchQueue = DispatchQueue(label: "FMSynthesizerQueue", attributes: [])
        audioQueue.async {
            self.createSilentSubliminalFile()
        }
    }
    
    
    func processAudioData(buffer: AVAudioPCMBuffer){
        
        guard let channelData = buffer.floatChannelData?[0] else {return}
        let frames = buffer.frameLength
        
        let rmsValue = SignalProcessing.rms(data: channelData, frameLength: UInt(frames))
        
        
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
                        self.recordButton.alpha = 1
                        self.recordButton.isEnabled = true
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
    
    // MARK: AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopPlaying()
    }
    
    
    @IBAction func close(_ sender: UIButton) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
}
