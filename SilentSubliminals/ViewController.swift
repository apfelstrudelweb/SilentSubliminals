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
import PureLayout

let modulationFrequency: Double = 15592
let bandwidth: Double = 2000

let cornerRadius: CGFloat = 15
let alpha: CGFloat = 0.85

class ViewController: UIViewController {
    
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewCenterY: NSLayoutConstraint!
    
//    @IBOutlet weak var recordButton: UIButton!
//    @IBOutlet weak var playButton: UIButton!
//    @IBOutlet weak var spectrumView: UIView!
  
    
    var recording: Bool = false
    var playing: Bool = false
    
    
    var recorder: AKNodeRecorder!
    var player: AKPlayer!
    //var tape: AKAudioFile!
    var filter: AKBandPassButterworthFilter!
    var mixer: AKMixer!
    
    var filterBooster: AKBooster!
    var signalBooster: AKBooster!
    
    var frequencyTracker: AKFrequencyTracker!
    var fftPlot: AKNodeFFTPlot!
    
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
        
        
        print(getDocumentsDirectory())
        
        // Clean tempFiles !
        //AKAudioFile.cleanTempDirectory()
        
        // Session settings
        AKSettings.bufferLength = .medium
        
        do {
            try AKSettings.setSession(category: .playAndRecord, with: .allowBluetoothA2DP)
        } catch {
            AKLog("Could not set session category.")
        }
        
        AKSettings.defaultToSpeaker = true
        
        
        let mic = AKMicrophone()
        let booster = AKBooster(mic)
        booster.gain = 1.0
        
        
        
        recorder = try? AKNodeRecorder(node: booster)
        if let file = recorder.audioFile {
            player = AKPlayer(audioFile: file)
        }
        player.isLooping = true
        //AudioKit.output = booster
        
//        fftPlot = AKNodeFFTPlot(mic, frame: .zero)
//        fftPlot.shouldFill = true
//        fftPlot.shouldMirror = false
//        fftPlot.shouldCenterYAxis = false
//        fftPlot.color = AKColor.red
//        fftPlot.backgroundColor = .clear
//        fftPlot.clipsToBounds = true
//        fftPlot.gain = 200
//        spectrumView.addSubview(fftPlot)
//        fftPlot.autoPinEdge(.top, to: .top, of: spectrumView)
//        fftPlot.autoPinEdge(.left, to: .left, of: spectrumView, withOffset: 10.0)
//        fftPlot.autoPinEdge(.bottom, to: .bottom, of: spectrumView, withOffset: -10.0)
//        fftPlot.autoMatch(.width, to: .width, of: spectrumView, withMultiplier: 2.2)

    }
    
    
    @IBAction func scriptCreationButtonTouched(_ sender: Any) {
        

        let offset = 0.1 * view.frame.size.height
        containerView.autoPinEdge(.bottom, to: .bottom, of: view, withOffset: -offset)
        
        UIView.animate(withDuration: 0.45) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
//    @IBAction func recordButtonTouched(_ sender: Any) {
//        
//        do {
//            try AudioKit.start()
//        } catch {
//            AKLog("AudioKit did not start!")
//        }
//        
//        recording = !recording
//        
//        playButton.isEnabled = recording == false
//        playButton.alpha = playButton.isEnabled ? 1.0 : 0.5
//        let title = recording == true ? "Stop" : "Record"
//        recordButton.setTitle(title, for: UIControl.State.normal)
//        
//        if recording == true {
//            do {
//                try recorder.record()
//            } catch {
//                AKLog("Errored recording.")
//                
//            }
//        } else {
//            
//            tape = recorder.audioFile!
//            player.load(audioFile: tape)
//            
//            if let _ = player.audioFile?.duration {
//                recorder.stop()
//                tape.exportAsynchronously(name: "SilentSubliminal.wav",
//                                          baseDir: .documents,
//                                          exportFormat: .wav) {_, exportError in
//                                            if let error = exportError {
//                                                AKLog("Export Failed \(error)")
//                                            } else {
//                                                AKLog("Export succeeded")
//                                            }
//                }
//            }
//            
//            do {
//                try AudioKit.stop()
//            } catch {
//                AKLog("AudioKit did not start!")
//            }
//        }
//        
//    }
//    
//    @IBAction func playButtonTouched(_ sender: Any) {
//        
//        playing = !playing
//        
//        recordButton.isEnabled = playing == false
//        recordButton.alpha = recordButton.isEnabled ? 1.0 : 0.5
//        let title = playing == true ? "Stop" : "Play"
//        playButton.setTitle(title, for: UIControl.State.normal)
//        
//        if playing == true {
//            
//            if let silentSubliminal = try? AKAudioFile(readFileName: "SilentSubliminal.wav", baseDir: .documents) {
//                player = AKPlayer(audioFile: silentSubliminal)
//                player.completionHandler = { Swift.print("completion callback has been triggered!") }
//                player.isLooping = true
//                player.buffering = .always
//                
//                let modulatedPlayer = AKOperationEffect(player) { player, _ in
//                    let sine = AKOperation.sineWave(frequency: modulationFrequency)
//                    let modulation = player * sine
//                    
//                    return modulation
//                }
//                
//                filter = AKBandPassButterworthFilter(modulatedPlayer, centerFrequency: modulationFrequency + 0.5 * bandwidth, bandwidth: bandwidth)
//                
//                
//                filterBooster = AKBooster(filter, gain: 0)
//                signalBooster = AKBooster(player, gain: 1)
//                
//                mixer = AKMixer(filterBooster, signalBooster)
//                AudioKit.output = mixer
//                fftPlot.node = mixer
//            }
//            
//            do {
//                try AudioKit.start()
//                player.play()
//            } catch {
//                AKLog("AudioKit did not start!")
//            }
//            
//        } else {
//            player.stop()
//            
//            do {
//                try AudioKit.stop()
//            } catch {
//                AKLog("AudioKit did not start!")
//            }
//        }
//    }
//    
//    
//    @IBAction func switchTapped(_ sender: UISwitch) {
//        
//        if signalBooster == nil || filterBooster == nil { return }
//        
//        
//        if sender.isOn {
//            
//            self.signalBooster.gain = 0
//            self.filterBooster.gain = 1
//            
//            self.signalBooster.gain = 1
//            self.filterBooster.gain = 0
//            
//            self.signalBooster.gain = 0
//            self.filterBooster.gain = 1
//            
//            self.fftPlot.gain = 1000
//        } else {
//            self.signalBooster.gain = 1
//            self.filterBooster.gain = 0
//            self.fftPlot.gain = 500
//        }
//    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    
}

