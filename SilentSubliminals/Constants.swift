//
//  Constants.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 01.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import AVFoundation

let outputFilename: String = "affirmation.caf"
let outputFilenameSilent: String = "affirmationSilent.caf"
let modulationFrequency: Double = 20000

struct Manager {
    static var recordingSession: AVAudioSession!
    static var micAuthorised = Bool()
}


func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
}
