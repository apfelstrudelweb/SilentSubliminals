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
}

enum Induction {
    case Intro
    case Outro
}

let modulationFrequency: Float = 20000
let bandwidth: Float = 1000

struct Manager {
    static var recordingSession: AVAudioSession!
    static var micAuthorised = Bool()
}


func getFileFromMainBundle(filename: String) -> URL? {
    
    let array = filename.split(separator: ".")
    
    if let filePath: String = Bundle.main.path(forResource: String(array.first!), ofType: String(array.last!)) {
        return URL(fileURLWithPath: filePath)
    }
    return nil
}

func getFileFromSandbox(filename: String) -> URL {
    return getDocumentsDirectory().appendingPathComponent(filename)
}

func clearToListenFiles() {
//    let fileManager = FileManager.default
    //let myDocuments = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
//    do {
//        try fileManager.removeItem(at: getFileFromSandbox(filename: toListenAffirmation))
//        try fileManager.removeItem(at: getFileFromSandbox(filename: toListenAffirmationSilent))
//    } catch {
//        print(error)
//    }
}


func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
}

