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
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var playerView: RoundedView!
    @IBOutlet weak var soundView: RoundedView!
    @IBOutlet weak var volumeSlider: UISlider!
    
//    var audioPlayer: AVAudioPlayerNode?
//    var engine = AVAudioEngine()
//    var distortion = AVAudioUnitDistortion()
//    var reverb = AVAudioUnitReverb()
//    var audioBuffer = AVAudioPCMBuffer()
    
    struct AudioFileTypes {
        var filename = ""
        var isSilent = false
        var audioPlayer = AVAudioPlayerNode()
    }
    
    private var audioFiles: Array<AudioFileTypes> = [AudioFileTypes(filename: outputFilename, isSilent: false), AudioFileTypes(filename: outputFilenameSilent, isSilent: true)]
    //private var audioFiles: Array<AudioFileTypes> = [AudioFileTypes(filename: "test1.caf", isSilent: false), AudioFileTypes(filename: "test2.caf", isSilent: true)]
    private var audioEngine: AVAudioEngine = AVAudioEngine()
    private var mixer: AVAudioMixerNode = AVAudioMixerNode()
    
    
    var isPlaying: Bool = false
    var isSilent: Bool = false
    
    var audioFileBuffer: AVAudioPCMBuffer?
    var audioFrameCount: UInt32?
    
    var backup = [Float]()
    
    struct Button {
        static var playOnImg = UIImage(named: "playButton.png")
        static var playOffImg = UIImage(named: "stopButton.png")
    }
    
    let spectrumLayer = CAShapeLayer.init()
    
    var frequencyDomainGraphLayerIndex = 0
    let frequencyDomainGraphLayers = [CAShapeLayer(), CAShapeLayer(),
                                      CAShapeLayer(), CAShapeLayer()]
    
    var dict: NSDictionary!
    
    //var audioFilePlayer: AVAudioPlayerNode = AVAudioPlayerNode()
    
    
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
        
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
            let ioBufferDuration = 128.0 / 44100.0
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(ioBufferDuration)
        } catch {
            assertionFailure("AVAudioSession setup error: \(error)")
        }
        
        // do work in a background thread
        let audioQueue: DispatchQueue = DispatchQueue(label: "PlayerQueue", attributes: [])
        audioQueue.async {
            do {
                self.audioEngine.attach(self.mixer)
                self.audioEngine.connect(self.mixer, to: self.audioEngine.outputNode, format: nil)
                // !important - start the engine *before* setting up the player nodes
                try self.audioEngine.start()
  
                for audioFile in self.audioFiles {
                    // Create and attach the audioPlayer node for this file
                    let audioPlayer = audioFile.audioPlayer
                    self.audioEngine.attach(audioPlayer)
                    
                    let audioFilename = getDocumentsDirectory().appendingPathComponent(audioFile.filename)
                    let avAudioFile = try AVAudioFile(forReading: audioFilename)
                    
                    // Notice the output is the mixer in this case
                    self.audioEngine.connect(audioPlayer, to: self.mixer, format: AVAudioFormat.init(standardFormatWithSampleRate: avAudioFile.fileFormat.sampleRate, channels: 1))
                    audioPlayer.volume = audioFile.isSilent ? 0 : 0.5

                    let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: avAudioFile.processingFormat, frameCapacity: AVAudioFrameCount(avAudioFile.length))!
                    try avAudioFile.read(into: audioFileBuffer)

                    audioPlayer.scheduleBuffer(audioFileBuffer, at: nil, options:.loops, completionHandler: nil)
                    audioPlayer.scheduleFile(avAudioFile, at: nil, completionHandler: nil)
  
                    audioPlayer.play()
                }
            } catch {
                print("File read error", error)
            }
        }
        
        //        var audioBuffer: AVAudioPCMBuffer!
        //        engine = AVAudioEngine()
        //        _ = engine.mainMixerNode
        //
        //        engine.prepare()
        //        do {
        //            try engine.start()
        //        } catch {
        //            print(error)
        //        }
        //
        //        let audioFilename = getDocumentsDirectory().appendingPathComponent(outputFilenameSilent)
        //
        //        do {
        //            let audioFile = try AVAudioFile(forReading: audioFilename)
        //            let format = audioFile.processingFormat
        //
        //            audioPlayer = AVAudioPlayerNode()
        //            audioPlayer?.volume = 1.0
        //            engine.attach(audioPlayer!)
        //            engine.connect(audioPlayer!, to: engine.mainMixerNode, format: format)
        //
        //            audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))!
        //
        //            do {
        //                print("read")
        //                try audioFile.read(into: audioBuffer)
        //            } catch _ {
        //                print("error reading audiofile into buffer")
        //            }
        //
        //            audioPlayer?.scheduleBuffer(audioBuffer, completionHandler: {
        //
        //                DispatchQueue.main.async {
        //                    if self.audioPlayer != nil {
        //                        self.stopPlaying()
        //                    }
        //                }
        //            })
        //
        //            audioPlayer!.scheduleFile(audioFile, at: nil, completionHandler: nil)
        //        } catch {
        //            print("could not load file")
        //        }
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
            stopPlaying()
            isPlaying = false
        }
    }
    
    func startPlaying() {
        
        playButton.setImage(Button.playOffImg, for: .normal)
        

        
    }
    
    func stopPlaying() {
        
//        self.playButton.setImage(Button.playOnImg, for: .normal)
//        audioPlayer?.stop()
        
    }
    
    @IBAction func silentButtonTouched(_ sender: Any) {
        
        isSilent = !isSilent
        
        for audioFile in self.audioFiles {
            // Create and attach the audioPlayer node for this file
            let audioPlayer = audioFile.audioPlayer
            audioPlayer.volume = audioFile.isSilent ? (isSilent ? 1 : 0) : (isSilent ? 0 : 1)
        }
        
        // TODO: change ear symbol
        
    }
    
    
    @IBAction func volumeSliderChanged(_ sender: Any) {
        
        let volume = Float(volumeSlider.value)
        
        for audioFile in self.audioFiles {
            let audioPlayer = audioFile.audioPlayer
            audioPlayer.volume = audioFile.isSilent ? (isSilent ? volume : 0) : (isSilent ? 0 : volume)
        }
    }
    
    @IBAction func close(_ sender: UIButton) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    
    
}
