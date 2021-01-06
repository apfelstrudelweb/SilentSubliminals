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
    func alertSilentsTooLoud(flag: Bool)
}

extension AudioHelperDelegate {
    func alertSilentsTooLoud(flag: Bool) {}
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

var audioFiles: Array<AudioFileTypes> = [AudioFileTypes(filename: "spokenAffirmation.caf", isSilent: false), AudioFileTypes(filename: "spokenAffirmationSilent.caf", isSilent: true)]

// from documents dir
var spokenAffirmation: String = "spokenAffirmation.caf" {
    didSet {
        audioFiles = [AudioFileTypes(filename: spokenAffirmation, isSilent: false), AudioFileTypes(filename: spokenAffirmationSilent, isSilent: true)]
    }
}
var spokenAffirmationSilent: String = "spokenAffirmationSilent.caf" {
    didSet {
        audioFiles = [AudioFileTypes(filename: spokenAffirmation, isSilent: false), AudioFileTypes(filename: spokenAffirmationSilent, isSilent: true)]
    }
}



class AudioHelper {
    
    static let shared = AudioHelper()
    
    var resetLoop: Bool = false
    
    var singleAffirmationDuration: TimeInterval = 0
    var playingNodes: Set<AVAudioPlayerNode> = Set<AVAudioPlayerNode>()
    
    let audioQueue: DispatchQueue = DispatchQueue(label: "PlayerQueue", attributes: [])
    
    private var audioEngine: AVAudioEngine = AVAudioEngine()
    private var audioRecorder: AVAudioRecorder = AVAudioRecorder()
    private var mixer: AVAudioMixerNode = AVAudioMixerNode()
    private var equalizerHighPass: AVAudioUnitEQ = AVAudioUnitEQ(numberOfBands: 1)

    var routeIsChanging: Bool = false
    
    weak var delegate : AudioHelperDelegate?
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(notification:)), name: AVAudioSession.interruptionNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange(notification:)), name: AVAudioSession.routeChangeNotification, object: nil)
        
        
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setPreferredIOBufferDuration(128.0 / 44100.0)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set audio session category.")
        }
        
        let highPass = self.equalizerHighPass.bands[0]
        highPass.filterType = .highPass
        highPass.frequency = modulationFrequency
        highPass.bandwidth = bandwidth
        highPass.bypass = false
    }
    
    @objc func handleRouteChange(notification: Notification) {
        print(notification.name)
        routeIsChanging = true
        //try! self.audioEngine.start()
        //sleep(1)
        //continueSound()
    }
    
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo, let typeInt = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt, let type = AVAudioSession.InterruptionType(rawValue: typeInt) else {
            return
        }
        
        switch type {
        case .began:
            // Pause your player
            print(type)
            break;
            
        case .ended:
            if let optionInt = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionInt)
                //TODO: resolve side effect with subliminal dictation in AddAffirmationViewController
//                if options.contains(.shouldResume) {
//                    try! self.audioEngine.start()
//                }
            }
        @unknown default:
            print("handleInterruption error")
        }
    }
    
    
    func getSilentPlayerNode() -> AVAudioPlayerNode {
        return audioFiles.filter() { $0.isSilent == true }.first!.audioPlayer
    }
    
    func getLoudPlayerNode() -> AVAudioPlayerNode {
        return audioFiles.filter() { $0.isSilent == false }.first!.audioPlayer
    }
    
    func playInduction(type: Induction) {
        
        audioQueue.async {
            
            self.resetLoop = false
            self.audioEngine.pause()
            let playerNode = AVAudioPlayerNode()
            
            self.audioEngine.attach(playerNode)
            
            var filename: String = bellSoundFile
            
            switch type {
            case .Introduction:
                filename = introductionSoundFile
            case .LeadInChair:
                filename = leadInChairSoundFile
            case .LeadInBed:
                filename = leadInBedSoundFile
            case .LeadOutDay:
                filename = leadOutDaySoundFile
            case .LeadOutNight:
                filename = leadOutNightSoundFile
            case .Bell:
                filename = bellSoundFile
            }
            
            let audioFile = try! AVAudioFile(forReading: getFileFromMainBundle(filename: filename)!)
            let format =  AVAudioFormat(standardFormatWithSampleRate: audioFile.fileFormat.sampleRate, channels: audioFile.fileFormat.channelCount)
            
            playerNode.removeTap(onBus: 0)
            
            self.audioEngine.connect(playerNode, to: self.audioEngine.outputNode, format: format)
            
            try! self.audioEngine.start()
            
            playerNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) {
                (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                
                DispatchQueue.main.async {
                    self.delegate?.processAudioData(buffer: buffer)
                    CommandCenter.shared.updateTime(elapsedTime: playerNode.currentTime, totalDuration: audioFile.duration)
                }
            }
            
            let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))!
            try! audioFile.read(into: audioFileBuffer)
            
            playerNode.scheduleBuffer(audioFileBuffer, completionHandler: {
                
                self.audioEngine.stop()
                self.playingNodes.remove(playerNode)
                
                if !self.resetLoop {
                    if type == .Introduction {
                        UserDefaults.standard.set(true, forKey: userDefaults_introductionPlayed)
                    }
                    
                    if PlayerStateMachine.shared.playerState != .ready { //&& !self.routeIsChanging {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: Notification.Name(notification_player_nextState), object: nil)
                        }
                    }
                }
            })
            
            //self.routeIsChanging = false
            
            self.playingNodes.insert(playerNode)
            playerNode.play()
        }
    }
    
    func playConsolidation() {
        
        audioQueue.async {
            
            self.resetLoop = false
            self.audioEngine.pause()
            let playerNode = AVAudioPlayerNode()
            
            self.audioEngine.detach(self.equalizerHighPass)
            self.audioEngine.attach(playerNode)
            self.audioEngine.attach(self.equalizerHighPass)
            
            let audioFile = try! AVAudioFile(forReading: getFileFromMainBundle(filename: consolidationSoundFile)!)
            let format =  AVAudioFormat(standardFormatWithSampleRate: audioFile.fileFormat.sampleRate, channels: audioFile.fileFormat.channelCount)
            
            playerNode.removeTap(onBus: 0)
            
            //self.audioEngine.connect(playerNode, to: self.audioEngine.outputNode, format: format)
            self.audioEngine.connect(playerNode, to: self.equalizerHighPass, format: format)
            self.audioEngine.connect(self.equalizerHighPass, to: self.mixer, format: format)
            
            try! self.audioEngine.start()
            
            playerNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) {
                (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                
                DispatchQueue.main.async {
                    self.delegate?.processAudioData(buffer: buffer)
                    CommandCenter.shared.updateTime(elapsedTime: playerNode.currentTime, totalDuration: audioFile.duration)
                }
            }
            
            let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))!
            try! audioFile.read(into: audioFileBuffer)
            
            playerNode.scheduleBuffer(audioFileBuffer, completionHandler: {
                
                self.audioEngine.stop()
                self.playingNodes.remove(playerNode)
                
                if PlayerStateMachine.shared.playerState != .ready {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name(notification_player_nextState), object: nil)
                    }
                }
                
            })
            
            self.playingNodes.insert(playerNode)
            playerNode.play()
        }
    }

    
    
    func playSingleAffirmation(instance: SoundInstance) {
        
        audioQueue.async {
            do {
                
                self.resetLoop = false
                self.audioEngine.pause()
                let playerNode = self.getLoudPlayerNode()
                self.audioEngine.attach(playerNode)
                self.audioEngine.attach(self.mixer)
                
                let audioFile = try AVAudioFile(forReading: getFileFromSandbox(filename: spokenAffirmation))
                self.singleAffirmationDuration = audioFile.duration
                
                let format =  AVAudioFormat(standardFormatWithSampleRate: audioFile.fileFormat.sampleRate, channels: audioFile.fileFormat.channelCount)
                
                playerNode.removeTap(onBus: 0)
                
                self.audioEngine.connect(playerNode, to: self.mixer, format: format)
                
                self.audioEngine.connect(self.mixer, to: self.audioEngine.outputNode, format: format)
                try self.audioEngine.start()
                
                playerNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) {
                    (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                    
                    DispatchQueue.main.async {
                        self.delegate?.processAudioData(buffer: buffer)
                        CommandCenter.shared.updateTime(elapsedTime: playerNode.currentTime, totalDuration: audioFile.duration)
                    }
                }
                
                let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))!
                try audioFile.read(into: audioFileBuffer)
                
                playerNode.scheduleBuffer(audioFileBuffer, completionHandler: {
                    
                    self.audioEngine.pause()
                    self.playingNodes.remove(playerNode)
                    
                    DispatchQueue.main.async {
                        
                        if instance == .player {
                            if !self.resetLoop {
                                if PlayerStateMachine.shared.playerState != .ready {
                                    NotificationCenter.default.post(name: Notification.Name(notification_player_nextState), object: nil)
                                }
                            }
                        } else {
                            NotificationCenter.default.post(name: Notification.Name(notification_maker_stopPlayingState), object: nil)
                        }
                    }
                })
                
                playerNode.play()
                self.playingNodes.insert(playerNode)
            } catch {
                print("File read error", error)
            }
        }
    }
    
    // for the Maker ...
    func stopPlayingSingleAffirmation() {
        
        let playerNode = self.getLoudPlayerNode()
        
        self.audioEngine.detach(playerNode)
        playerNode.stop()
        
        let inputNode = self.audioEngine.inputNode
        let bus = 0
        inputNode.removeTap(onBus: bus)
        self.audioEngine.stop()
    }
    
    func reset() {
        resetLoop = true
        self.audioEngine.stop()
        self.playingNodes = Set<AVAudioPlayerNode>()
        PlayerStateMachine.shared.playerState = .ready
        //MakerStateMachine.shared.playerState = .playStopped
    }
    
    func skip() {
        
        self.audioEngine.stop()
        self.playingNodes = Set<AVAudioPlayerNode>()
    }
    
    
    func playAffirmationLoop() {
        
        audioQueue.async { [self] in
            do {
                
                self.resetLoop = false
                self.audioEngine.detach(self.equalizerHighPass)
                
                self.audioEngine.attach(self.mixer)
                
                self.audioEngine.pause()
                
                for audioFile in audioFiles {
                    
                    if audioFile.isSilent {
                        self.audioEngine.attach(self.equalizerHighPass)
                    }
                    
                    let playerNode = audioFile.audioPlayer
                    self.audioEngine.attach(playerNode)
                    
                    let avAudioFile = try AVAudioFile(forReading: getFileFromSandbox(filename: audioFile.filename))
                    let format =  AVAudioFormat(standardFormatWithSampleRate: avAudioFile.fileFormat.sampleRate, channels: avAudioFile.fileFormat.channelCount)

                    self.audioEngine.connect(playerNode, to: self.mixer, format: format)
                    
                    //TODO: find out why "self.audioEngine.connect(playerNode, to: self.equalizerHighPass, format: format)" crashes at second play
                    if audioFile.isSilent {
                        self.audioEngine.connect(playerNode, to: self.equalizerHighPass, format: format)
                        self.audioEngine.connect(self.equalizerHighPass, to: self.mixer, format: format)

                    } else {
                        self.audioEngine.connect(playerNode, to: self.mixer, format: format)
                    }
                    
                    
                    playerNode.removeTap(onBus: 0)
                    
                    try self.audioEngine.start()
                    
                    let availableTimeForLoop: TimeInterval = (TimerManager.shared.remainingTime ?? defaultAffirmationTime) - self.singleAffirmationDuration
                    
                    var numExceeds = 0
                    var notificationPosted: Bool = false
                    
                    playerNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) {
                        (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                        
                        DispatchQueue.main.async {
                            
                            CommandCenter.shared.updateTime(elapsedTime: playerNode.currentTime, totalDuration: availableTimeForLoop)
                            
                            if audioFile.isSilent {
                                let exceed = SignalProcessing.checkForVolumeExceed(from: buffer)
                                if exceed {
                                    numExceeds += 1
                                }
                                if numExceeds > 5 {
                                    self.delegate?.alertSilentsTooLoud(flag: true)
                                    numExceeds = 0
                                } else {
                                    self.delegate?.alertSilentsTooLoud(flag: false)
                                }
                                
                            }
                            
                            if audioFile.isSilent && playerNode.currentTime > availableTimeForLoop {
                                //playerNode.stop()
                                self.audioEngine.pause()
                                self.playingNodes = Set<AVAudioPlayerNode>()
                                if PlayerStateMachine.shared.playerState == .affirmationLoop && !notificationPosted {
                                    NotificationCenter.default.post(name: Notification.Name(notification_player_nextState), object: nil)
                                    notificationPosted = true
                                    //PlayerStateMachine.shared.doNextPlayerState()
                                }
                            }
                            
                            if PlayerStateMachine.shared.frequencyState == .loud && !audioFile.isSilent {
                                self.delegate?.processAudioData(buffer: buffer)
                            }
                            
                            if PlayerStateMachine.shared.frequencyState == .silent && audioFile.isSilent {
                                self.delegate?.processAudioData(buffer: buffer)
                            }
                        }
                    }
                    
                    let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: avAudioFile.processingFormat, frameCapacity: AVAudioFrameCount(avAudioFile.length))!
                    try avAudioFile.read(into: audioFileBuffer)
                    
                    playerNode.scheduleBuffer(audioFileBuffer, at: nil, options:.loops, completionHandler: {
        
                        if !self.resetLoop && audioFile.isSilent && playerNode.currentTime < availableTimeForLoop && !notificationPosted {
                            NotificationCenter.default.post(name: Notification.Name(notification_player_nextState), object: nil)
                            notificationPosted = true
                        }
                    })
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
    
    // MARK:VolumeManagerDelegate
    func updateVolume(volume: Float) {
        for playerNode in self.playingNodes {
            playerNode.volume = volume
        }
    }
    
    // MARK: MAKER
    func createSilentSubliminalFile() {
        
        let file = try! AVAudioFile(forReading: getFileFromSandbox(filename: spokenAffirmation))
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        
        engine.attach(player)
        
        //engine.connect(player, to:engine.mainMixerNode, format: AVAudioFormat.init(standardFormatWithSampleRate: sampleRate, channels: 1))
        let busFormat = AVAudioFormat(standardFormatWithSampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount)
        
        engine.disconnectNodeInput(engine.outputNode, bus: 0)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: busFormat)
        
        engine.connect(player, to:engine.mainMixerNode, format: busFormat)
        
        //print(engine)
        
        // Run the engine in manual rendering mode using chunks of 512 frames
        let renderSize: AVAudioFrameCount = 512
        
        // Use the file's processing format as the rendering format
        let renderFormat = AVAudioFormat(commonFormat: file.processingFormat.commonFormat, sampleRate: file.processingFormat.sampleRate, channels: file.processingFormat.channelCount, interleaved: false)!
        
        let renderBuffer = AVAudioPCMBuffer(pcmFormat: renderFormat, frameCapacity: renderSize)!
        
        try! engine.enableManualRenderingMode(.offline, format: renderFormat, maximumFrameCount: renderBuffer.frameCapacity)
        
        try! engine.start()
        player.play()
        
        // Read using a buffer sized to produce `renderSize` frames of output
        let readBuffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: renderSize)!
        
        var settings: [String : Any] = [:]
        
        settings[AVFormatIDKey] = kAudioFormatAppleLossless
        settings[AVAudioFileTypeKey] = kAudioFileM4AType
        settings[AVSampleRateKey] = readBuffer.format.sampleRate
        settings[AVNumberOfChannelsKey] = readBuffer.format.channelCount
        settings[AVLinearPCMIsFloatKey] = (readBuffer.format.commonFormat == .pcmFormatInt32)
        settings[AVSampleRateConverterAudioQualityKey] = AVAudioQuality.max
        settings[AVLinearPCMBitDepthKey] = 32
        settings[AVEncoderAudioQualityKey] = AVAudioQuality.max
        
        // The render format is also the output format
        let output = try! AVAudioFile(forWriting: getFileFromSandbox(filename: spokenAffirmationSilent), settings: settings, commonFormat: renderFormat.commonFormat, interleaved: renderFormat.isInterleaved)
        
        var index: Int = 0;
        // Process the file
        while true {
            do {
                // Processing is finished if all frames have been read
                if file.framePosition == file.length {
                    break
                }
                
                try file.read(into: readBuffer)
                player.scheduleBuffer(readBuffer, completionHandler: nil)
                
                let result = try engine.renderOffline(readBuffer.frameLength, to: renderBuffer)
                
                let leftSourceData = readBuffer.floatChannelData?[0]
                let rightSourceData = readBuffer.floatChannelData?[1]
                
                let leftTargetData = renderBuffer.floatChannelData?[0]
                let rightTargetData = renderBuffer.floatChannelData?[1]
                
                // Process the audio in 'renderBuffer' here
                for i in 0..<Int(readBuffer.frameLength) {
                    let val: Double = sin(Double(2 * modulationFrequency) * Double(index) * Double.pi / Double(renderBuffer.format.sampleRate))
                    leftTargetData?[i] = Float(val) * (leftSourceData?[i] ?? 0)
                    rightTargetData?[i] = Float(val) * (rightSourceData?[i] ?? 0)
                    index += 1
                }
                
                if index == Int(file.fileFormat.sampleRate) {
                    index = 0
                }
                
                // Write the audio
                try output.write(from: renderBuffer)
                if result != .success {
                    break
                }
            }
            catch {
                break
            }
        }
        
        player.stop()
        engine.stop()
        
        print("Silent Subliminal file '\(spokenAffirmationSilent)' has been created")
    }
    
    
    func startRecording() {
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100, //48000,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ] as [String : Any]
        
        let inputNode = self.audioEngine.inputNode
        let audioFile = getFileFromSandbox(filename: spokenAffirmation)
        do {
            audioRecorder = try AVAudioRecorder(url: audioFile, settings: settings)
        } catch {
            print(error)
        }
        
        let format =  AVAudioFormat(standardFormatWithSampleRate: AVAudioSession.sharedInstance().sampleRate, channels: 2)
        
        inputNode.removeTap(onBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) {
            (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
            
            DispatchQueue.main.async {
                self.delegate?.processAudioData(buffer: buffer)
            }
        }
        
        self.audioEngine.prepare()
        try! self.audioEngine.start()
        
        audioRecorder.record()
    }
    
    func stopRecording() {
        
        audioRecorder.stop()
        
        let inputNode = self.audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        self.audioEngine.stop()
        
        let audioQueue: DispatchQueue = DispatchQueue(label: "SilentCreationQueue", attributes: [])
        audioQueue.async {
            self.createSilentSubliminalFile()
        }
    }
    
    func checkForPermission() {
        Manager.recordingSession = AVAudioSession.sharedInstance()
        do {
            try Manager.recordingSession.setCategory(AVAudioSession.Category.playAndRecord, options: .defaultToSpeaker)
            
            Manager.recordingSession.requestRecordPermission({ (allowed) in
                if allowed {
                    Manager.micAuthorised = true
                    DispatchQueue.main.async {
                        //                        self.recordButton.alpha = 1
                        //                        self.recordButton.isEnabled = true
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
}
