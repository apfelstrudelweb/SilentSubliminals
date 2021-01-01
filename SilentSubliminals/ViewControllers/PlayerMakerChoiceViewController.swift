//
//  PlayerMakerChoiceViewController.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 15.11.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerMakerChoiceViewController: UIViewController, AudioSessionManagerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let audioSessionManager = AudioSessionManager.shared
        audioSessionManager.delegate = self
        audioSessionManager.checkForPermission()

        //self.navigationItem.title = "Choice"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
   
    }
    
    // MARK: AudioSessionManagerDelegate
    func showWarning() {
        
        if let url = NSURL(string: UIApplication.openSettingsURLString) as URL? {
            DispatchQueue.main.async {
                
                let alert = UIAlertController(title: "Warning", message: "You first need to grant permission to your microphone. You're redirected to 'Settings' -> 'Privacy' -> 'Microphone'", preferredStyle: .alert)
                
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {_ in
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }))
                self.present(alert, animated: true)

            }
        }
    }

}
