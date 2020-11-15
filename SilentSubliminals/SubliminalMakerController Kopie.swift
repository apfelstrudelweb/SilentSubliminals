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

let sampleCount = 1024
let outputFilename: String = "affirmation.mp3"

let modulationFrequency: Float = 18000

let cornerRadius: CGFloat = 15
let alpha: CGFloat = 0.85

//https://stackoverflow.com/questions/52693784/audiokit-exporting-avaudiopcmbuffer-array-to-audio-file-with-fade-in-out
// https://gist.github.com/michaeldorner/746c659476429a86a9970faaa6f95ec4   (FM Synthesizer)
// https://stackoverflow.com/questions/48911800/avaudioengine-realtime-frequency-modulation
class SubliminalMakerController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var graphView: UIView!
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    var writer: AVAssetWriter?
    var isRecording: Bool = false
    
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
    
    
    var biquadFilter: vDSP.Biquad<Float>?
    
    let forwardDCT = vDSP.DCT(count: sampleCount,
                              transformType: .II)
    
    let inverseDCT = vDSP.DCT(count: sampleCount,
                              transformType: .III)
    
    var frequencyDomainGraphLayerIndex = 0
    let frequencyDomainGraphLayers = [CAShapeLayer(), CAShapeLayer(),
                                      CAShapeLayer(), CAShapeLayer()]
    
    let envelopeLayer = CAShapeLayer()
    
    lazy var forwardDCT_PreProcessed = [Float](repeating: 0,
                                               count: sampleCount)
    
    lazy var forwardDCT_PostProcessed = [Float](repeating: 0,
                                                count: sampleCount)
    
    lazy var inverseDCT_Result = [Float](repeating: 0,
                                  count: sampleCount)
    
    var equalizationMode: EqualizationMode = .flat {
        didSet {
            if let multiplier = equalizationMode.dctMultiplier() {
                GraphUtility.drawGraphInLayer(envelopeLayer,
                                              strokeColor: UIColor.red.cgColor,
                                              lineWidth: 2,
                                              values: multiplier,
                                              minimum: -10,
                                              maximum: 10)
            } else {
                envelopeLayer.path = nil
            }
        }
    }
    
    
    let samples: (naturalTimeScale: Int32, data: [Float]) = {
        guard let samples = AudioUtilities.getAudioSamples(
            forResource: "affirmation",
            withExtension: "mp3") else {
                fatalError("Unable to parse the audio resource.")
        }
        
        var samples1: (Int32, [Float]) = (44100, [])
        
        let modulationFrequency: Float = 20000
        
        for (index, sampleData) in samples.data.enumerated() {
            let value = sinf(2.0 * .pi * modulationFrequency * Float(index) / Float(samples.naturalTimeScale)) * sampleData * 10.0
            samples1.1.append(value)
        }
        
        return samples1
    }()
    
    var pageNumber = 0

    lazy var signalGenerator = SignalGenerator(signalProvider: self,
                                               sampleRate: samples.naturalTimeScale)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        equalizationMode = .dctHighPass
        
        frequencyDomainGraphLayers.forEach {
            self.graphView.layer.addSublayer($0)
        }
        
        envelopeLayer.fillColor = UIColor.red.cgColor
        self.graphView.layer.addSublayer(envelopeLayer)
        
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
        graphView.clipsToBounds = true
        
        recordButton.alpha = 0.1
        recordButton.isEnabled = false
        
        print(getDocumentsDirectory())
        
        // Clean tempFiles !
        //AKAudioFile.cleanTempDirectory()
        
        checkForPermission()
        
        //initializeAudioEngine()
        
        fftSetup = vDSP_DFT_zop_CreateSetup(nil, 1024, vDSP_DFT_Direction.FORWARD)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        frequencyDomainGraphLayers.forEach {
            $0.frame = self.graphView.frame.insetBy(dx: 0, dy: 0)
        }
        envelopeLayer.frame = self.graphView.frame.insetBy(dx: 0, dy: 0)
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
        
        if signalGenerator.isPlaying() {
            stopPlaying()
        } else {
            startPlaying()
        }
    }
    
    func startPlaying() {
        
        playButton.setImage(Button.playOffImg, for: .normal)
        recordButton.isEnabled = false;
        
        try? signalGenerator.start()
    }

    func stopPlaying() {
        
        DispatchQueue.main.async {
            self.recordButton.isEnabled = true;
            self.playButton.setImage(Button.playOnImg, for: .normal)
            self.spectrumLayer.removeFromSuperlayer()
        }
        
        signalGenerator.stop()
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
        let audioFilename = getDocumentsDirectory().appendingPathComponent(outputFilename)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatAppleIMA4),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
//        let session = AVAudioSession.sharedInstance()
//        try! session.setCategory(AVAudioSession.Category.playAndRecord, options: .defaultToSpeaker)

        let asset = AVAsset(url: audioFilename.absoluteURL)
        

        writer = try? AVAssetWriter(url: audioFilename.absoluteURL, fileType: AVFileType.caf)
        
        let audioOutputSettings: [String: Any] = [
                        AVNumberOfChannelsKey: 1,
                        AVFormatIDKey: kAudioFormatMPEG4AAC,
                        AVSampleRateKey: 44100,
                        AVEncoderBitRateKey: 128000
                    ]
        
        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOutputSettings)
        audioInput.expectsMediaDataInRealTime = true
        writer?.add(audioInput)

        if writer?.status == AVAssetWriter.Status.unknown {
            writer?.startWriting()
            writer?.startSession(atSourceTime: .zero)
        }

        
//        do {
//            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
//            audioRecorder?.delegate = self
//            audioRecorder?.record()
//            
//            self.playButton.isEnabled = false
//            recordButton.setImage(Button.micOffImg, for: .normal)
//        } catch {
//            stopRecording(success: false)
//        }
    }
    
    func stopRecording(success: Bool) {
        
        DispatchQueue.main.async {
            self.playButton.isEnabled = true
            self.recordButton.setImage(Button.micOnImg, for: .normal)
            self.spectrumLayer.removeFromSuperlayer()
        }
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent(outputFilename)
        let asset = AVAsset(url: audioFilename.absoluteURL)
        
        writer?.endSession(atSourceTime: asset.duration)
        writer?.finishWriting {
            print("finish writing")
        }
        
//        audioRecorder?.stop()
//        audioRecorder = nil
//
//        let inputNode = engine.inputNode
//        let bus = 0
//        inputNode.removeTap(onBus: bus)
//        self.engine.stop()
        
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
