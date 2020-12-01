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
    

    
    var audioEngine: AVAudioEngine = AVAudioEngine()
    var audioFilePlayer: AVAudioPlayerNode = AVAudioPlayerNode()
    
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
        
        //try? signalGenerator.start()
        
//        do {
//            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
//            //try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
//            //            let ioBufferDuration = 128.0 / 44100.0
//            //            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(ioBufferDuration)
//        } catch {
//            assertionFailure("AVAudioSession setup error: \(error)")
//        }
//        
//        let fileURL = getDocumentsDirectory().appendingPathComponent(outputFilename)
//        guard let audioFile = try? AVAudioFile(forReading: fileURL) else{ return }
        
        

        
//        let audioFormat = audioFile.processingFormat
//        audioFrameCount = UInt32(audioFile.length)
//        audioFileBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount!)
//
//        do{
//            try audioFile.read(into: audioFileBuffer!)
//        } catch{
//            print("over")
//        }
        
        return
  
//        audioEngine.attach(audioFilePlayer)
//        //audioEngine.connect(audioFilePlayer, to:mainMixer, format: audioFileBuffer?.format)
//
//        let busFormat = AVAudioFormat(standardFormatWithSampleRate: audioFile.fileFormat.sampleRate, channels: audioFile.fileFormat.channelCount)
//        audioEngine.disconnectNodeInput(audioEngine.outputNode, bus: 0)
//        audioEngine.connect(audioFilePlayer, to: audioEngine.mainMixerNode, format: busFormat)
//
//        try? audioEngine.start()
//        audioFilePlayer.play()
    
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
        
        //        try? signalGenerator.start()
        //
        //        signalGenerator.engine.mainMixerNode.outputVolume = Float(volumeSlider.value) * 2.0
        
    }
    
    func stopPlaying() {
        
        self.playButton.setImage(Button.playOnImg, for: .normal)
        //        signalGenerator.stop()
        //try? silentSignalGenerator.start()
        //signalGenerator.stop()
        
    }
    
    @IBAction func silentButtonTouched(_ sender: Any) {
        
        isSilent = !isSilent
        
        
        
        //equalizationMode = isSilent == true ? .dctHighPass : .dctLowPass
        
        audioFilePlayer.stop()
        audioFilePlayer.play()
        
        if isSilent == true {
            
            backup = [Float]()
            
            for i in stride(from:0, to: Int(audioFrameCount!), by: 1) {
                let val = 10 * sinf(2.0 * .pi * 20000 * Float(i) / Float(44800)) //* (audioFileBuffer?.floatChannelData?[0][i])!
                //bufferTest?.floatChannelData?.pointee[Int(i)] = (audioFileBuffer?.floatChannelData?.pointee[Int(i)])!
                backup.append((audioFileBuffer?.floatChannelData?[0][i])!)
                audioFileBuffer?.floatChannelData?[0][i] = val
            }
            audioFilePlayer.scheduleBuffer(audioFileBuffer!, at: nil, options:AVAudioPlayerNodeBufferOptions.loops)
            
        } else {
            for i in stride(from:0, to: Int(audioFrameCount!), by: 1) {
                audioFileBuffer?.floatChannelData?.pointee[Int(i)] = backup[i]
            }
            audioFilePlayer.scheduleBuffer(audioFileBuffer!, at: nil, options:AVAudioPlayerNodeBufferOptions.loops)
        }

        
        //signalGenerator.isSilent = isSilent
    }
    
    
    @IBAction func volumeSliderChanged(_ sender: Any) {
        
        //signalGenerator.engine.mainMixerNode.outputVolume = Float(volumeSlider.value) * 2.0
    }
    
    @IBAction func close(_ sender: UIButton) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
}
