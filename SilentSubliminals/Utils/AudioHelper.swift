//
//  AudioHelper.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 26.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import AVFoundation

protocol AudioHelperDelegate : AnyObject {
    
    func processAudioData(buffer: AVAudioPCMBuffer)
}

struct Manager {
    static var recordingSession: AVAudioSession!
    static var micAuthorised = Bool()
}

struct AudioFileTypes {
    var filename = ""
    var isSilent = false
    var audioPlayer = AVAudioPlayerNode()
}

var audioFiles: Array<AudioFileTypes> = [AudioFileTypes(filename: spokenAffirmation, isSilent: false), AudioFileTypes(filename: spokenAffirmationSilent, isSilent: true)]

var affirmationLoopDuration = TimerManager.shared.remainingTime

class AudioHelper {
    
    var playingNodes: Set<AVAudioPlayerNode> = Set<AVAudioPlayerNode>()
    
    weak var delegate : AudioHelperDelegate?
    
    func getSilentPlayerNode() -> AVAudioPlayerNode {
        
        return audioFiles.filter() { $0.isSilent == true }.first!.audioPlayer
    }
    
    func getLoudPlayerNode() -> AVAudioPlayerNode {
        
        return audioFiles.filter() { $0.isSilent == false }.first!.audioPlayer
    }
    
    let audioQueue: DispatchQueue = DispatchQueue(label: "PlayerQueue", attributes: [])
    
    private var audioEngine: AVAudioEngine = AVAudioEngine()
    private var mixer: AVAudioMixerNode = AVAudioMixerNode()
    private var equalizerHighPass: AVAudioUnitEQ = AVAudioUnitEQ(numberOfBands: 1)
    
    func playInduction(type: Induction) {
        
        audioQueue.async {
            
            let playerNode = AVAudioPlayerNode()
            
            self.audioEngine.attach(self.mixer)
            self.audioEngine.attach(playerNode)
            
            self.audioEngine.stop()
            
            let filename = type == .Intro ? spokenIntro : spokenOutro
            
            let avAudioFile = try! AVAudioFile(forReading: getFileFromMainBundle(filename: filename)!)
            let format =  AVAudioFormat(standardFormatWithSampleRate: avAudioFile.fileFormat.sampleRate, channels: avAudioFile.fileFormat.channelCount)
            
            self.audioEngine.connect(playerNode, to: self.mixer, format: format)
            self.audioEngine.connect(self.mixer, to: self.audioEngine.outputNode, format: format)
            
            try! self.audioEngine.start()
            
            playerNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
                (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                
                DispatchQueue.main.async {
                    self.delegate?.processAudioData(buffer: buffer)
                }
            }
            
            let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: avAudioFile.processingFormat, frameCapacity: AVAudioFrameCount(avAudioFile.length))!
            try! avAudioFile.read(into: audioFileBuffer)
            
            playerNode.scheduleBuffer(audioFileBuffer, completionHandler: {
                self.audioEngine.stop()
                self.playingNodes.remove(playerNode)
                StateMachine.shared.doNextPlayerState()
            })
            
            playerNode.scheduleFile(avAudioFile, at: nil, completionHandler: nil)
            playerNode.play()
            
            self.playingNodes.insert(playerNode)
        }
    }
    
    func playSingleAffirmation() {
        
        audioQueue.async {
            do {
                self.audioEngine.attach(self.mixer)
                
                self.audioEngine.stop()
                
                let playerNode = self.getLoudPlayerNode()
                self.audioEngine.attach(playerNode)
                
                let avAudioFile = try AVAudioFile(forReading: getFileFromSandbox(filename: spokenAffirmation))
                let format =  AVAudioFormat(standardFormatWithSampleRate: avAudioFile.fileFormat.sampleRate, channels: avAudioFile.fileFormat.channelCount)
                
                playerNode.removeTap(onBus: 0)
                
                self.audioEngine.connect(playerNode, to: self.mixer, format: format)
                
                self.audioEngine.connect(self.mixer, to: self.audioEngine.outputNode, format: format)
                try self.audioEngine.start()
                
                playerNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
                    (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                    
                    DispatchQueue.main.async {
                        self.delegate?.processAudioData(buffer: buffer)
                    }
                }
                
                let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: avAudioFile.processingFormat, frameCapacity: AVAudioFrameCount(avAudioFile.length))!
                try avAudioFile.read(into: audioFileBuffer)
                
                playerNode.scheduleBuffer(audioFileBuffer, completionHandler: {
                    self.audioEngine.stop()
                    self.playingNodes.remove(playerNode)
                    StateMachine.shared.doNextPlayerState()
                })
                
                playerNode.play()
                self.playingNodes.insert(playerNode)
            } catch {
                print("File read error", error)
            }
        }
    }
    
    func playAffirmationLoop() {
        
        audioQueue.async {
            do {
                
                let highPass = self.equalizerHighPass.bands[0]
                highPass.filterType = .highPass
                highPass.frequency = modulationFrequency
                highPass.bandwidth = bandwidth
                highPass.bypass = false
                
                self.audioEngine.attach(self.equalizerHighPass)
                self.audioEngine.attach(self.mixer)
                
                self.audioEngine.stop()
                
                for audioFile in audioFiles {
                    
                    let playerNode = audioFile.audioPlayer
                    self.audioEngine.attach(playerNode)
                    
                    let avAudioFile = try AVAudioFile(forReading: getFileFromSandbox(filename: audioFile.filename))
                    let format =  AVAudioFormat(standardFormatWithSampleRate: avAudioFile.fileFormat.sampleRate, channels: avAudioFile.fileFormat.channelCount)
                    
                    playerNode.removeTap(onBus: 0)
                    
                    if audioFile.isSilent {
                        self.audioEngine.connect(playerNode, to: self.equalizerHighPass, format: format)
                        self.audioEngine.connect(self.equalizerHighPass, to: self.mixer, format: format)
                        
                    } else {
                        self.audioEngine.connect(playerNode, to: self.mixer, format: format)
                    }
                    
                    self.audioEngine.connect(self.mixer, to: self.audioEngine.outputNode, format: format)
                    try self.audioEngine.start()
                    
                    playerNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
                        (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                        
                        DispatchQueue.main.async {
                            
                            if audioFile.isSilent && playerNode.current >= 10 {
                                playerNode.stop()
                                self.audioEngine.stop()
                                self.playingNodes = Set<AVAudioPlayerNode>()
                                if StateMachine.shared.playerState == .affirmationLoop {
                                    StateMachine.shared.doNextPlayerState()
                                }
                            }
                            
                            if StateMachine.shared.frequencyState == .loud && !audioFile.isSilent {
                                self.delegate?.processAudioData(buffer: buffer)
                            }
                            
                            if StateMachine.shared.frequencyState == .silent && audioFile.isSilent {
                                self.delegate?.processAudioData(buffer: buffer)
                            }
                        }
                    }
                    
                    let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: avAudioFile.processingFormat, frameCapacity: AVAudioFrameCount(avAudioFile.length))!
                    try avAudioFile.read(into: audioFileBuffer)
                    
                    playerNode.scheduleBuffer(audioFileBuffer, at: nil, options:.loops, completionHandler: nil)
                    playerNode.play()
                    self.playingNodes.insert(playerNode)
                }
            } catch {
                print("File read error", error)
            }
        }
    }
    
    func pauseSound() {
        
        for playerNode in self.playingNodes {
            playerNode.pause()
        }
    }
    
    func continueSound() {
        
        for playerNode in self.playingNodes {
            playerNode.play()
        }
    }
}
