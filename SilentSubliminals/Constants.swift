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
    static var playOnImg = UIImage(named: "playButton.png")
    static var playOffImg = UIImage(named: "stopButton.png")
    static var silentOnImg = UIImage(named: "earSilentIcon.png")
    static var silentOffImg = UIImage(named: "earLoudIcon.png")
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

