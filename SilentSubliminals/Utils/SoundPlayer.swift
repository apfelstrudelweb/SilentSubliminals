//
//  SoundPlayer.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 07.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import AVFoundation

protocol SoundPlayerDelegate : AnyObject {
    
    func processAudioData(buffer: AVAudioPCMBuffer)
    //func alertSilentsTooLoud(flag: Bool)
}

open class SoundPlayer: NSObject {
    
    var audioPlayer : AVAudioPlayerNode!
    var audioPlayerSilent : AVAudioPlayerNode!
    var engine = AVAudioEngine()
    
    private var equalizerHighPass: AVAudioUnitEQ = AVAudioUnitEQ(numberOfBands: 1)
    
    let audioQueue: DispatchQueue = DispatchQueue(label: "PlayerQueue", attributes: [])
    
    weak var delegate : AudioHelperDelegate?
    
    var singleAffirmationDuration: TimeInterval = 0
    var availableTimeForLoop: TimeInterval = 0
    
    public override init() {
        let highPass = self.equalizerHighPass.bands[0]
        highPass.filterType = .highPass
        highPass.frequency = modulationFrequency
        highPass.bandwidth = bandwidth
        highPass.bypass = false
        
        do {
            let audioFile = try AVAudioFile(forReading: getFileFromSandbox(filename: spokenAffirmation))
            self.singleAffirmationDuration = audioFile.duration
            availableTimeForLoop = (TimerManager.shared.remainingTime ?? defaultAffirmationTime) - self.singleAffirmationDuration
        } catch {
            print("File read error", error)
        }
    }
    
    func play(filename: String, isSilent: Bool, completionHandler: @escaping(Bool) -> Void) {
        
        audioQueue.async { [self] in
            do {
                
                self.engine.stop()
                self.engine = AVAudioEngine()
                
                // simplest possible "play a buffer" scenario
                var url = Bundle.main.url(forResource: filename.fileName(), withExtension: filename.fileExtension())
                
                if url == nil {
                    url = getFileFromSandbox(filename: filename)
                }
                
                //let url = Bundle.main.url(forResource: filename.fileName(), withExtension: filename.fileExtension())!
                let f = try! AVAudioFile(forReading: url!)
                let buffer = AVAudioPCMBuffer(pcmFormat: f.processingFormat, frameCapacity: UInt32(f.length /* /3 */)) // only need 1/3 of the original recording
                try! f.read(into:buffer!)
                
                self.engine.detach(self.equalizerHighPass)
                audioPlayer = AVAudioPlayerNode()
                self.engine.attach(audioPlayer)
                let mixer = self.engine.mainMixerNode
                
                if isSilent {
                    self.engine.attach(self.equalizerHighPass)
                    self.engine.connect(audioPlayer, to: self.equalizerHighPass, format: f.processingFormat)
                    self.engine.connect(self.equalizerHighPass, to: mixer, format: f.processingFormat)
                } else {
                    self.engine.connect(audioPlayer, to: mixer, format: f.processingFormat)
                }
                
                
                audioPlayer.installTap(onBus: 0, bufferSize: bufferSize, format: f.processingFormat) {
                (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                    
                    delegate?.processAudioData(buffer: buffer)

                }
                       
                audioPlayer.scheduleBuffer(buffer!, at: nil, options: .interrupts, completionCallbackType: .dataConsumed) { (type) in

                    delay(0.1) {
                        if self.engine.isRunning {
                            print("engine was running, really stopping")
                            self.engine.stop()
                        }
                        completionHandler(true)
                    }
                }
                
                self.engine.prepare()
                try! self.engine.start()
                audioPlayer.play()
            }
        }
    }
    
    func playLoop(filenames: [String], completionHandler: @escaping(Bool) -> Void) {
        
        audioQueue.async { [self] in
            do {
                
                self.engine.stop()
                self.engine = AVAudioEngine()
                
                let urlLoud = getFileFromSandbox(filename: filenames.first!)
                let formatLoud = try! AVAudioFile(forReading: urlLoud)
                let bufferLoud = AVAudioPCMBuffer(pcmFormat: formatLoud.processingFormat, frameCapacity: UInt32(formatLoud.length /* /3 */)) // only need 1/3 of the original recording
                try! formatLoud.read(into:bufferLoud!)
                
                // loud
                audioPlayer = AVAudioPlayerNode()
                self.engine.attach(audioPlayer)
                let mixer = self.engine.mainMixerNode
                self.engine.connect(audioPlayer, to: mixer, format: formatLoud.processingFormat)
                
                
                let urlSilent = getFileFromSandbox(filename: filenames.last!)
                let formatSilent = try! AVAudioFile(forReading: urlSilent)
                let bufferSilent = AVAudioPCMBuffer(pcmFormat: formatSilent.processingFormat, frameCapacity: UInt32(formatSilent.length /* /3 */)) // only need 1/3 of the original recording
                try! formatSilent.read(into:bufferSilent!)
                
                // silent
                self.engine.detach(self.equalizerHighPass)
                audioPlayerSilent = AVAudioPlayerNode()
                self.engine.attach(audioPlayerSilent)
                self.engine.attach(self.equalizerHighPass)
                let mixerSilent = self.engine.mainMixerNode
                
                self.engine.connect(audioPlayerSilent, to: self.equalizerHighPass, format: formatSilent.processingFormat)
                self.engine.connect(self.equalizerHighPass, to: mixerSilent, format: formatSilent.processingFormat)
                
                audioPlayer.installTap(onBus: 0, bufferSize: bufferSize, format: formatLoud.processingFormat) {
                (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                    
                    if audioPlayer.volume > 0 {
                        delegate?.processAudioData(buffer: buffer)
                    }
                    
                    if audioPlayer.currentTime  > availableTimeForLoop {
                        self.engine.stop()
                        delay(0.1) {
                            if self.engine.isRunning {
                                print("engine was running, really stopping")
                                self.engine.stop()
                            }
                        }
                    }
                }
                
                audioPlayerSilent.installTap(onBus: 0, bufferSize: bufferSize, format: formatSilent.processingFormat) {
                (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                    
                    if audioPlayerSilent.volume > 0 {
                        delegate?.processAudioData(buffer: buffer)
                    }
                }
                
                audioPlayer.scheduleBuffer(bufferLoud!, at: nil, options: .loops, completionCallbackType: .dataConsumed) { (type) in

                    delay(0.1) {
                        if self.engine.isRunning {
                            print("engine was running, really stopping")
                            self.engine.stop()
                        }
                        completionHandler(true)
                    }
                }
                
                audioPlayerSilent.scheduleBuffer(bufferSilent!, at: nil, options: .loops, completionCallbackType: .dataConsumed) { (type) in

                    delay(0.1) {
                        if self.engine.isRunning {
                            print("engine was running, really stopping")
                            //self.engine.stop()
                        }
                    }
                }
                
                self.engine.prepare()
                try! self.engine.start()
                audioPlayer.play()
                audioPlayerSilent.play()
                
                audioPlayer.volume = 0
                audioPlayerSilent.volume = 1
            }
        }
    }
    

    
    func pause() {
        self.engine.pause()
        //self.audioPlayer.pause()
    }
    
    func continuePlayer() {
        try! self.engine.start()
        //self.audioPlayer.play()
    }
    
    func stop() {
        
        self.engine.stop()
        self.engine = AVAudioEngine()
        
        delay(0.1) {
            if self.engine.isRunning {
                print("engine was running, really stopping")
                self.engine.stop()
            }
        }
        
    }
    
    func isRunning() -> Bool {
        return self.engine.isRunning
    }
}


extension String {

    func fileName() -> String {
        return URL(fileURLWithPath: self).deletingPathExtension().lastPathComponent
    }

    func fileExtension() -> String {
        return URL(fileURLWithPath: self).pathExtension
    }
}
