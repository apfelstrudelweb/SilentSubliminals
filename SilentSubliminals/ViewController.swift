//
//  ViewController.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 10.05.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import AudioKit
import AudioKitUI
import CoreAudio
import AVFoundation
import PureLayout

let modulationFrequency: Double = 15592
let bandwidth: Double = 2000

let cornerRadius: CGFloat = 15
let alpha: CGFloat = 0.85

class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    struct Manager {
        static var recordingSession: AVAudioSession!
        static var micAuthorised = Bool()
    }
    
    var recording: Bool = false
    var playing: Bool = false
    
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    
    var engine = AVAudioEngine()
    var distortion = AVAudioUnitDistortion()
    var reverb = AVAudioUnitReverb()
    var audioBuffer = AVAudioPCMBuffer()
    var outputFile = AVAudioFile()
    var delay = AVAudioUnitDelay()
    
    
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
        
        recordButton.alpha = 0.1
        recordButton.isEnabled = false
        
        print(getDocumentsDirectory())
        
        // Clean tempFiles !
        //AKAudioFile.cleanTempDirectory()
        
        checkForPermission()
        
        initializeAudioEngine()
        
    }
    
    func initializeAudioEngine() {
        
        engine.stop()
        engine.reset()
        engine = AVAudioEngine()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
            
            let ioBufferDuration = 128.0 / 44100.0
            
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(ioBufferDuration)
            
        } catch {
            
            assertionFailure("AVAudioSession setup error: \(error)")
        }
        
        //        let fileUrl = URLFor("/NewRecording.caf")
        //        outputFile = AVAudioFile(forWriting:  fileUrl!, settings: engine.mainMixerNode.outputFormatForBus(0).settings)
        
        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        
        //engine.connect(input, to: reverb, format: format)
        //
        //        try! engine.start()
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
        
        playButton.setImage(UIImage(named: "stopButton.png"), for: .normal)
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("rookieSwim.m4a")
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFilename)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            print("could not load file")
        }
    }
    
    func stopPlaying() {
        
        playButton.setImage(UIImage(named: "playButton.png"), for: .normal)
        
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func startRecording() {
        
        let inputNode = engine.inputNode
        let bus = 0
        inputNode.installTap(onBus: bus, bufferSize: 2048, format: inputNode.inputFormat(forBus: bus)) {
            (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in

            self.processAudioData(buffer: buffer)
        }
        
//        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { (buffer, time) in
//            self.processAudioData(buffer: buffer)
//        }
        
        engine.prepare()
        try! engine.start()
        let audioFilename = getDocumentsDirectory().appendingPathComponent("rookieSwim.m4a")
        
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
            
            recordButton.setImage(UIImage(named: "stopRecordingButton.png"), for: .normal)
        } catch {
            stopRecording(success: false)
        }
    }
    
    func stopRecording(success: Bool) {
        
        audioRecorder?.stop()
        audioRecorder = nil
        
        let inputNode = engine.inputNode
        let bus = 0
        inputNode.removeTap(onBus: bus)
        self.engine.stop()
        
        recordButton.setImage(UIImage(named: "startRecordingButton.png"), for: .normal)
        
        //        if success {
        //            recordButton.setTitle("Tap to Re-record", for: .normal)
        //        } else {
        //            recordButton.setTitle("Tap to Record", for: .normal)
        //            // recording failed :(
        //        }
    }
    
    var prevRMSValue : Float = 0.3
    
    //fft setup object for 1024 values going forward (time domain -> frequency domain)
    let fftSetup = vDSP_DFT_zop_CreateSetup(nil, 1024, vDSP_DFT_Direction.FORWARD)

    func processAudioData(buffer: AVAudioPCMBuffer){
        guard let channelData = buffer.floatChannelData?[0] else {return}
        let frames = buffer.frameLength
        
        //rms
        let rmsValue = SignalProcessing.rms(data: channelData, frameLength: UInt(frames))
        let interpolatedResults = SignalProcessing.interpolate(current: rmsValue, previous: prevRMSValue)
        prevRMSValue = rmsValue
        
        //print(rmsValue)
        
        //fft
        let fftMagnitudes =  SignalProcessing.fft(data: channelData, setup: fftSetup!)
        
//        for var m in fftMagnitudes {
//            print(m)
//        }
        
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

