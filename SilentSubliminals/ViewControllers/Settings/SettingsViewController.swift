//
//  SettingsViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 07.02.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var modulationSwitch: UISwitch!
    
    private var audioHelper = AudioHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        modulationSwitch.isOn = false
        // Do any additional setup after loading the view.
    }
    

 
    @IBAction func modulationSwitchTouched(_ sender: Any) {
        
        UserDefaults.standard.setValue(modulationSwitch.isOn, forKey: userDefaults_frequencyModulation)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.audioHelper.createSilentSubliminalFile()
        }
    }
    
}
