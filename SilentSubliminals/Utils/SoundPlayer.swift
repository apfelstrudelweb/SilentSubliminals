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
    
    var commandCenter: CommandCenter?
    
    var audioPlayerNode : AVAudioPlayerNode!
    var audioPlayerSilentNode : AVAudioPlayerNode!
    var engine = AVAudioEngine()
    
    private var equalizerHighPass: AVAudioUnitEQ = AVAudioUnitEQ(numberOfBands: 1)
    
    let audioQueue: DispatchQueue = DispatchQueue(label: "PlayerQueue", attributes: [])
    
    weak var delegate : AudioHelperDelegate?
    
    var singleAffirmationDuration: TimeInterval = 0
    var availableTimeForLoop: TimeInterval = 0
    
    public override init() {
        super.init()

        let highPass = self.equalizerHighPass.bands[0]
        highPass.filterType = .highPass
        highPass.frequency = modulationFrequency
        highPass.bandwidth = bandwidth
        highPass.bypass = false
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
                
                let file = try! AVAudioFile(forReading: url!)
                let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: UInt32(file.length))
                try! file.read(into:buffer!)
                
                self.engine.detach(self.equalizerHighPass)
                audioPlayerNode = AVAudioPlayerNode()
                self.engine.attach(audioPlayerNode)
                let mixer = self.engine.mainMixerNode
                
                if isSilent {
                    self.engine.attach(self.equalizerHighPass)
                    self.engine.connect(audioPlayerNode, to: self.equalizerHighPass, format: file.processingFormat)
                    self.engine.connect(self.equalizerHighPass, to: mixer, format: file.processingFormat)
                } else {
                    self.engine.connect(audioPlayerNode, to: mixer, format: file.processingFormat)
                }
                
                let commandCenter = CommandCenter.shared
                commandCenter.node = audioPlayerNode
                commandCenter.audioFile = file
                
                audioPlayerNode.installTap(onBus: 0, bufferSize: bufferSize, format: file.processingFormat) {
                (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                    
                    delegate?.processAudioData(buffer: buffer)
                    CommandCenter.shared.updateTime(elapsedTime: audioPlayerNode.currentTime, totalDuration: file.duration)
                }
                       
                audioPlayerNode.scheduleBuffer(buffer!, at: nil, options: .interrupts, completionCallbackType: .dataConsumed) { (type) in

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
                audioPlayerNode.play()
            }
        }
    }
    
    func playLoop(filenames: [String], completionHandler: @escaping(Bool) -> Void) {
        
        audioQueue.async { [self] in
            do {
                
                availableTimeForLoop = TimeInterval(UserDefaults.standard.integer(forKey: userDefaults_loopDuration)) - self.singleAffirmationDuration
                
                self.engine.stop()
                self.engine = AVAudioEngine()
                
                let urlLoud = getFileFromSandbox(filename: filenames.first!)
                let formatLoud = try! AVAudioFile(forReading: urlLoud)
                let bufferLoud = AVAudioPCMBuffer(pcmFormat: formatLoud.processingFormat, frameCapacity: UInt32(formatLoud.length /* /3 */)) // only need 1/3 of the original recording
                try! formatLoud.read(into:bufferLoud!)
                
                // loud
                audioPlayerNode = AVAudioPlayerNode()
                self.engine.attach(audioPlayerNode)
                let mixer = self.engine.mainMixerNode
                self.engine.connect(audioPlayerNode, to: mixer, format: formatLoud.processingFormat)
                
                
                let urlSilent = getFileFromSandbox(filename: filenames.last!)
                let formatSilent = try! AVAudioFile(forReading: urlSilent)
                let bufferSilent = AVAudioPCMBuffer(pcmFormat: formatSilent.processingFormat, frameCapacity: UInt32(formatSilent.length))
                try! formatSilent.read(into:bufferSilent!)
                
                // silent
                self.engine.detach(self.equalizerHighPass)
                audioPlayerSilentNode = AVAudioPlayerNode()
                self.engine.attach(audioPlayerSilentNode)
                self.engine.attach(self.equalizerHighPass)
                let mixerSilent = self.engine.mainMixerNode
                
                self.engine.connect(audioPlayerSilentNode, to: self.equalizerHighPass, format: formatSilent.processingFormat)
                self.engine.connect(self.equalizerHighPass, to: mixerSilent, format: formatSilent.processingFormat)
                
                let minutes = availableTimeForLoop / 60
                print("loop time: \(minutes) minutes")
                
 
                audioPlayerNode.installTap(onBus: 0, bufferSize: bufferSize, format: formatLoud.processingFormat) {
                (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                    
                    if audioPlayerNode.volume > 0 {
                        delegate?.processAudioData(buffer: buffer)
                    }
                    
                    CommandCenter.shared.updateTime(elapsedTime: audioPlayerNode.currentTime, totalDuration: availableTimeForLoop)
                    
                    if audioPlayerNode.currentTime  > availableTimeForLoop {
                        self.engine.stop()
                        delay(0.1) {
                            if self.engine.isRunning {
                                print("engine was running, really stopping")
                                self.engine.stop()
                            }
                        }
                    }
                }
                
                audioPlayerSilentNode.installTap(onBus: 0, bufferSize: bufferSize, format: formatSilent.processingFormat) {
                (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                    
                    if audioPlayerSilentNode.volume > 0 {
                        delegate?.processAudioData(buffer: buffer)
                    }
                }
                
                audioPlayerNode.scheduleBuffer(bufferLoud!, at: nil, options: .loops, completionCallbackType: .dataConsumed) { (type) in

                    delay(0.1) {
                        if self.engine.isRunning {
                            print("engine was running, really stopping")
                            self.engine.stop()
                        }
                        completionHandler(true)
                    }
                }
                
                audioPlayerSilentNode.scheduleBuffer(bufferSilent!, at: nil, options: .loops, completionCallbackType: .dataConsumed) { (type) in

                    delay(0.1) {
                        if self.engine.isRunning {
                            print("engine was running, really stopping")
                            //self.engine.stop()
                        }
                    }
                }
                
                self.engine.prepare()
                try! self.engine.start()
                audioPlayerNode.play()
                audioPlayerSilentNode.play()
                
                audioPlayerNode.volume = 0
                audioPlayerSilentNode.volume = 1
            }
        }
    }
    

    
    func pauseEngine() {
        self.engine.pause()
    }
    
    func continueEngine() {
        
        //stop()

        do {
            try self.engine.start()
        } catch {
            print("Player could not be continued", error)
        }
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
