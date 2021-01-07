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
    
    let audioQueue: DispatchQueue = DispatchQueue(label: "PlayerQueue", attributes: [])
    
    weak var delegate : AudioHelperDelegate?
    
    public override init() {
        
    }
    
    func play(filename: String, completionHandler: @escaping(Bool) -> Void) {
        
        audioQueue.async { [self] in
            do {
                
                self.engine.stop()
                self.engine = AVAudioEngine()
                
                // simplest possible "play a buffer" scenario
                let url = Bundle.main.url(forResource: filename, withExtension: "mp3")!
                let f = try! AVAudioFile(forReading: url)
                let buffer = AVAudioPCMBuffer(pcmFormat: f.processingFormat, frameCapacity: UInt32(f.length /* /3 */)) // only need 1/3 of the original recording
                try! f.read(into:buffer!)
                
                audioPlayer = AVAudioPlayerNode()
                self.engine.attach(audioPlayer)
                let mixer = self.engine.mainMixerNode
                self.engine.connect(audioPlayer, to: mixer, format: f.processingFormat)
                
                audioPlayer.installTap(onBus: 0, bufferSize: bufferSize, format: f.processingFormat) {
                (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                    
                    delegate?.processAudioData(buffer: buffer)
                    
                    if Int(audioPlayer.currentTime)  > Int(10) {
                        self.engine.stop()
                    }
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
    
    func playLoop(filename: String, completionHandler: @escaping(Bool) -> Void) {
        
        audioQueue.async { [self] in
            do {
                
                self.engine.stop()
                self.engine = AVAudioEngine()
                
                let urlLoud = Bundle.main.url(forResource: filename, withExtension: "mp3")!
                let formatLoud = try! AVAudioFile(forReading: urlLoud)
                let bufferLoud = AVAudioPCMBuffer(pcmFormat: formatLoud.processingFormat, frameCapacity: UInt32(formatLoud.length /* /3 */)) // only need 1/3 of the original recording
                try! formatLoud.read(into:bufferLoud!)
                
                // loud
                audioPlayer = AVAudioPlayerNode()
                self.engine.attach(audioPlayer)
                let mixer = self.engine.mainMixerNode
                self.engine.connect(audioPlayer, to: mixer, format: formatLoud.processingFormat)
                
                
                let urlSilent = Bundle.main.url(forResource: filename + "Silent", withExtension: "mp3")!
                let formatSilent = try! AVAudioFile(forReading: urlSilent)
                let bufferSilent = AVAudioPCMBuffer(pcmFormat: formatSilent.processingFormat, frameCapacity: UInt32(formatSilent.length /* /3 */)) // only need 1/3 of the original recording
                try! formatSilent.read(into:bufferSilent!)
                
                // silent
                audioPlayerSilent = AVAudioPlayerNode()
                self.engine.attach(audioPlayerSilent)
                let mixerSilent = self.engine.mainMixerNode
                self.engine.connect(audioPlayerSilent, to: mixerSilent, format: formatSilent.processingFormat)
                
                audioPlayer.installTap(onBus: 0, bufferSize: bufferSize, format: formatLoud.processingFormat) {
                (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                    
                    if audioPlayer.volume > 0 {
                        delegate?.processAudioData(buffer: buffer)
                    }
                    
                    if Int(audioPlayer.currentTime)  > Int(5) {
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
