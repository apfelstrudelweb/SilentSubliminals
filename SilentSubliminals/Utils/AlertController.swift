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
    
    func showWarningMissingAffirmationFile(vc: UIViewController, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "Warning", message: "You first need to record your Subliminal for this Library. You're now redirected to the Subliminal Maker.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {_ in
            completionHandler(true)
        }))
        vc.present(alert, animated: true)
    }
    
    func showInfoLongAffirmationLoop(vc: UIViewController, completionHandler: @escaping (Bool) -> Void) {
        
        guard let playTimeInSeconds = TimerManager.shared.remainingTime else {
            completionHandler(true)
            return
        }

        if playTimeInSeconds < criticalLoopDurationInSeconds {
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
