//
//  Constants.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 01.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

let cornerRadius: CGFloat = 15

// from main bundle
let spokenIntro = "intro.aiff"
let spokenOutro = "outro.aiff"

// from documents dir
let spokenAffirmation: String = "spokenAffirmation.caf"
let spokenAffirmationSilent: String = "spokenAffirmationSilent.caf"

struct Button {
    static var playOnImg = UIImage(named: "playIcon.svg")
    static var playOffImg = UIImage(named: "stopIcon.svg")
    static var silentOnImg = UIImage(named: "earSilentIcon.svg")
    static var silentOffImg = UIImage(named: "earLoudIcon.svg")
    static var micOnImg = UIImage(named: "startRecordingButton.png")
    static var micOffImg = UIImage(named: "stopRecordingButton.png")
}

struct PlayerControlColor {
    // https://www.ralfebert.de/ios-examples/uikit/swift-uicolor-picker/
    static var lightColor: UIColor = UIColor(red: 239/255, green: 239/255, blue: 239/255, alpha: 1.0)
    static var lightGrayColor: UIColor = UIColor(red: 178/255, green: 178/255, blue: 178/255, alpha: 1.0)
    static var darkGrayColor: UIColor = UIColor(red: 119/255, green: 119/255, blue: 119/255, alpha: 1.0)
    
//    // for test purposes
//    static var lightColor: UIColor = .red
//    static var lightGrayColor: UIColor = .blue
//    static var darkGrayColor: UIColor = .green
}

enum Induction {
    case Intro
    case Outro
}

let modulationFrequency: Float = 20000
let bandwidth: Float = 1000

let defaultSliderVolume: Float = 0.5

let criticalLoopDurationInHours: Int = 6

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
