//
//  AlertController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 30.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import UIKit

class AlertController {
    
    func showWarningMissingSilentFile(vc: UIViewController, fileName: String, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "Warning", message: "You first need to record your Subliminal named '\(fileName)'. You're now redirected to the Subliminal Maker where you can record your Silent.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {_ in
            completionHandler(true)
        }))
        vc.present(alert, animated: true)
    }
    
    func showWarningMissingSilentFilesForPlaylist(vc: UIViewController, fileNames: Array<String>, completionHandler: @escaping (Bool) -> Void) {
        
        var names: String = ""
        for name in fileNames {
            names += "\n\(name)"
        }
        
        let alert = UIAlertController(title: "Warning", message: "You first need to record all Subliminals for this Playlist.\nSound files are missing for the following items:\n\(names)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {_ in
            completionHandler(true)
        }))
        vc.present(alert, animated: true)
    }
    
    func showWarningEmptyPlaylist(vc: UIViewController, completionHandler: @escaping (Bool) -> Void) {

        let alert = UIAlertController(title: "Warning", message: "This playlist is empty! Please switch to the edit mode and drag at least one item into the playlist!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {_ in
            completionHandler(true)
        }))
        vc.present(alert, animated: true)
    }
    
    func showInfoLongAffirmationLoop(vc: UIViewController, completionHandler: @escaping (Bool) -> Void) {
        
        let playTimeInSeconds = UserDefaults.standard.integer(forKey: userDefaults_loopDuration)

        if playTimeInSeconds < Int(criticalLoopDurationInSeconds) {
            completionHandler(true)
            return
        }

        let hours: Int = Int(playTimeInSeconds) / hourInSeconds
        
        let alert = UIAlertController(title: "Information", message: "You've set a very long time interval of about \(hours) hours. Are you sure that you want to listen to the silent subliminals for so long?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "YES", style: .default, handler: {_ in
            completionHandler(true)
        }))
        alert.addAction(UIAlertAction(title: "NO", style: .cancel, handler: { _ in
            completionHandler(false)
        }))
        vc.present(alert, animated: true)
    }
    
}
