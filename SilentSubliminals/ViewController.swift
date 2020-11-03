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

let outputFilename: String = "affirmation.fus"

let modulationFrequency: Double = 15592
let bandwidth: Double = 2000

let cornerRadius: CGFloat = 15
let alpha: CGFloat = 0.85


// https://stackoverflow.com/questions/48911800/avaudioengine-realtime-frequency-modulation
class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var graphView: UIView!
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    struct Button {
        static var micOnImg = UIImage(named: "startRecordingButton.png")
        static var micOffImg = UIImage(named: "stopRecordingButton.png")
        static var playOnImg = UIImage(named: "playButton.png")
        static var playOffImg = UIImage(named: "stopButton.png")
    }
    
    struct Manager {
        static var recordingSession: AVAudioSession!
        static var micAuthorised = Bool()
    }
    
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
        
        initializeAudioEngine()
        
        fftSetup = vDSP_DFT_zop_CreateSetup(nil, 1024, vDSP_DFT_Direction.FORWARD)
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
        
        if audioRecorder == nil {
            startRecording()
        } else {
            stopRecording(success: true)
        }
    }
    
    @IBAction func playButtonTouched(_ sender: Any) {
        
        if audioPlayer == nil {
            startPlaying()
        } else {
            stopPlaying()
        }
    }
    
    func startPlaying() {
        
        playButton.setImage(Button.playOffImg, for: .normal)
        recordButton.isEnabled = false;
 
        var audioBuffer: AVAudioPCMBuffer!
        engine = AVAudioEngine()
        _ = engine.mainMixerNode
        
        engine.prepare()
        do {
            try engine.start()
        } catch {
            print(error)
        }
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent(outputFilename)
        
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

            let audioBuffer2 = modulate(buffer: audioBuffer)!//bytesToAudioBuffer(array2)
            audioPlayer?.scheduleBuffer(audioBuffer2, completionHandler: {

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
        
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { (buffer, time) in
            
            DispatchQueue.main.async {
                self.processAudioData(buffer: buffer)
            }
        }
        
        audioPlayer?.play()
    }
    
    // TODO: frequency modulation 20.000 Hz
    // TODO: low pass filter after modulation
    func modulate(buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        
        guard let floatData = buffer.floatChannelData else { return buffer }

        let modulatedBuffer = AVAudioPCMBuffer(pcmFormat: buffer.format,
                                                frameCapacity: buffer.frameCapacity)

        let length: AVAudioFrameCount = buffer.frameLength
        let channelCount = Int(buffer.format.channelCount)

        // i is the index in the buffer
        for i in 0 ..< Int(length) {
            // n is the channel
            for n in 0 ..< channelCount {
                let sample = floatData[n][i] * Float(5.0 * sin(0.6 * Float(i)))
                modulatedBuffer?.floatChannelData?[n][i] = sample
            }
        }
        modulatedBuffer?.frameLength = length

        return modulatedBuffer
    }


    func stopPlaying() {
        
        DispatchQueue.main.async {
            self.recordButton.isEnabled = true;
            self.playButton.setImage(Button.playOnImg, for: .normal)
            self.spectrumLayer.removeFromSuperlayer()
        }
        
        engine.detach(audioPlayer!)
        
        audioPlayer?.stop()
        audioPlayer = nil
        
        let inputNode = engine.inputNode
        let bus = 0
        inputNode.removeTap(onBus: bus)
        self.engine.stop()
    }
    
    func startRecording() {
        
        initializeAudioEngine()
        
        let inputNode = engine.inputNode
        let bus = 0
        inputNode.installTap(onBus: bus, bufferSize: 2048, format: inputNode.inputFormat(forBus: bus)) {
            (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
            
            DispatchQueue.main.async {
                self.processAudioData(buffer: buffer)
            }
        }
        
        engine.prepare()
        try! engine.start()
        let audioFilename = getDocumentsDirectory().appendingPathComponent(outputFilename)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 48000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            self.playButton.isEnabled = false
            recordButton.setImage(Button.micOffImg, for: .normal)
        } catch {
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
        let bus = 0
        inputNode.removeTap(onBus: bus)
        self.engine.stop()
        
    }
    
    var prevRMSValue : Float = 0.3
    
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
    
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
}
