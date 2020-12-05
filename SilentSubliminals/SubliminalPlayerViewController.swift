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
    private var equalizerLow: AVAudioUnitEQ = AVAudioUnitEQ(numberOfBands: 1)
    
    var fftSetup : vDSP_DFT_Setup?
    
    var isPlaying: Bool = false
    var isSilent: Bool = false
    
    var audioFileBuffer: AVAudioPCMBuffer?
    var audioFrameCount: UInt32?
    
    var backup = [Float]()
    
    struct Button {
        static var playOnImg = UIImage(named: "playButton.png")
        static var playOffImg = UIImage(named: "stopButton.png")
        static var silentOnImg = UIImage(named: "earSilentIcon.png")
        static var silentOffImg = UIImage(named: "earLoudIcon.png")
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
        
        fftSetup = vDSP_DFT_zop_CreateSetup(nil, 1024, vDSP_DFT_Direction.FORWARD)
        
        
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
            let ioBufferDuration = 128.0 / 44100.0
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(ioBufferDuration)
        } catch {
            assertionFailure("AVAudioSession setup error: \(error)")
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
        
        // https://medium.com/@ian.mundy/audio-mixing-on-ios-4cd51dfaac9a
        // do work in a background thread
        let audioQueue: DispatchQueue = DispatchQueue(label: "PlayerQueue", attributes: [])
        audioQueue.async {
            do {
                
                let lowPass = self.equalizerLow.bands[0]
                lowPass.filterType = .highPass//audioFile.isSilent ? .highPass : .lowPass
                lowPass.frequency = 20000 //audioFile.isSilent ? 22000 : 400
                lowPass.bandwidth = 200
                lowPass.bypass = false
                
                self.audioEngine.attach(self.equalizerLow)
                self.audioEngine.attach(self.mixer)
                
                
                // !important - start the engine *before* setting up the player nodes
                //try self.audioEngine.start()
                
                
                for audioFile in self.audioFiles {
                    //self.audioEngine.stop()
                    // Create and attach the audioPlayer node for this file
                    let audioPlayer = audioFile.audioPlayer
                    self.audioEngine.attach(audioPlayer)
                    
                    let audioFilename = getDocumentsDirectory().appendingPathComponent(audioFile.filename)
                    let avAudioFile = try AVAudioFile(forReading: audioFilename)
                    
                    // Notice the output is the mixer in this case
                    let format =  AVAudioFormat(standardFormatWithSampleRate: avAudioFile.fileFormat.sampleRate, channels: avAudioFile.fileFormat.channelCount)
                    
                    audioPlayer.removeTap(onBus: 0)
                    
                    if audioFile.isSilent {
                        self.audioEngine.connect(audioPlayer, to: self.equalizerLow, format: format)
                        self.audioEngine.connect(self.equalizerLow, to: self.mixer, format: format)
                        
                    } else {
                        self.audioEngine.connect(audioPlayer, to: self.mixer, format: format)
                        audioPlayer.installTap(onBus: 0, bufferSize: 1024, format: format) {
                            (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                            
                            DispatchQueue.main.async {
                                self.processAudioData(buffer: buffer)
                            }
                        }
                        
                    }
                    
                    self.audioEngine.connect(self.mixer, to: self.audioEngine.outputNode, format: format)
                    try self.audioEngine.start()
                    
                    audioPlayer.volume = 0.5 //audioFile.isSilent ? 0 : 0.5
  
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
        
    }
    
    func stopPlaying() {
        
        self.playButton.setImage(Button.playOnImg, for: .normal)
        //        for audioFile in self.audioFiles {
        //            // Create and attach the audioPlayer node for this file
        //            let audioPlayer = audioFile.audioPlayer
        //            audioPlayer.stop()
        //        }
        
    }
    
    @IBAction func silentButtonTouched(_ sender: Any) {
        
        isSilent = !isSilent
        
        let buttonImage = isSilent ? Button.silentOnImg : Button.silentOffImg
        
        self.silentButton.setImage(buttonImage, for: .normal)

        for audioFile in self.audioFiles {
 
            let audioPlayer = audioFile.audioPlayer
            audioPlayer.volume = audioFile.isSilent ? (isSilent ? 1 : 0) : (isSilent ? 0 : 1)
            
            let audioFilename = getDocumentsDirectory().appendingPathComponent(audioFile.filename)
            let avAudioFile = try! AVAudioFile(forReading: audioFilename)
            let format =  AVAudioFormat(standardFormatWithSampleRate: avAudioFile.fileFormat.sampleRate, channels: avAudioFile.fileFormat.channelCount)
            
            audioPlayer.removeTap(onBus: 0)
            
            if isSilent && audioFile.isSilent || !isSilent && !audioFile.isSilent {
                audioPlayer.installTap(onBus: 0, bufferSize: 1024, format: format) {
                    (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                    
                    DispatchQueue.main.async {
                        self.processAudioData(buffer: buffer)
                    }
                }
            }
 
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
    
}
