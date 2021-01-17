//
//  Constants.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 01.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

let cornerRadius: CGFloat = 15

// Audio files
var audioTemplate = "%@.caf"
var audioSilentTemplate = "%@Silent.caf"
var defaultAudioName = "spokenSubliminal"

let defaultImageButtonIcon = UIImage(named: "playerPlaceholderSymbol")

// from main bundle
let introductionSoundFile = "introduction.aiff"
let leadInChairSoundFile = "leadInChair.aiff"
let leadInBedSoundFile = "leadInBed.aiff"
let leadOutDaySoundFile = "leadOutDay.aiff"
let leadOutNightSoundFile = "leadOutNight.aiff"
let bellSoundFile = "bell.aiff"
let consolidationSoundFile = "Integration-Silent.mp3"

let bufferSize: AVAudioFrameCount = 1024

let playOnImg = UIImage(named: "playIcon.svg")
let playOffImg = UIImage(named: "stopIcon.svg")
let silentOnImg = UIImage(named: "earSilentIcon.svg")
let silentOffImg = UIImage(named: "earLoudIcon.svg")
let micOnImg = UIImage(named: "startRecordingButton.png")
let micOffImg = UIImage(named: "stopRecordingButton.png")


// https://www.ralfebert.de/ios-examples/uikit/swift-uicolor-picker/
let lightColor: UIColor = UIColor(red: 239/255, green: 239/255, blue: 239/255, alpha: 1.0)
let lightGrayColor: UIColor = UIColor(red: 178/255, green: 178/255, blue: 178/255, alpha: 1.0)
let darkGrayColor: UIColor = UIColor(red: 119/255, green: 119/255, blue: 119/255, alpha: 1.0)

//// for test purposes
//let lightColor: UIColor = .red
//let lightGrayColor: UIColor = .blue
//let darkGrayColor: UIColor = .green

let warningColor: UIColor = UIColor(red: 196/255, green: 0/255, blue: 0/255, alpha: 1.0)


enum SoundInstance {
    case player
    case maker
}

enum LeadInLeadOutSymbols : Int {
    case introduction = 0
    case chair = 1
    case bed = 2
    case day = 3
    case night = 4
}

let spectrumColor: UIColor = UIColor(red: 0, green: 0.8863, blue: 0.5333, alpha: 1.0)

let modulationFrequency: Float = 20000
let bandwidth: Float = 1000


let criticalLoopDurationInSeconds: TimeInterval = 6 * 60 * 60
let defaultAffirmationTime: TimeInterval = 5 * 60
let dayInSeconds: Double = 24 * 60 * 60
let hourInSeconds: Int = 60 * 60
let minuteInSeconds: Int = 60

// User defaults
let userDefaults_introductionPlayed = "introductionPlayed"
let userDefaults_loopDuration = "loopDuration"
let userDefaults_loopTerminated = "loopTerminated"
let userDefaults_loopTerminationTime = "loopTerminationTime"


// Notification
let notification_durationViewControllerCalled = "durationViewControllerCalled"
let notification_endtimeViewControllerCalled = "endtimeViewControllerCalled"
let notification_systemVolumeDidChange = "AVSystemController_SystemVolumeDidChangeNotification"

let notification_player_nextState = "player_nextState"
//let notification_maker_stopRecordingState = "maker_stopRecordingState"
let notification_maker_stopPlayingState = "maker_stopPlayingState"

