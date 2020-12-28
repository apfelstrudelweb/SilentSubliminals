//
//  Constants.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 01.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import UIKit

let cornerRadius: CGFloat = 15

// from main bundle
let spokenIntroChair = "intro.aiff"
let spokenIntroBed = "intro.aiff"
let spokenOutroDay = "outro.aiff"
let spokenOutroNight = "outro.aiff"
let introOutroBell = "bell.aiff"


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

enum SoundInstance {
    case player
    case maker
}

let spectrumColor: UIColor = UIColor(red: 0, green: 0.8863, blue: 0.5333, alpha: 1.0)

let modulationFrequency: Float = 20000
let bandwidth: Float = 1000

let defaultSliderVolume: Float = 0.5

let criticalLoopDurationInHours: Int = 6
let defaultAffirmationTime: TimeInterval = 5 * 60

