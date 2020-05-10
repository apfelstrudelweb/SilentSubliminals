//
//  ViewController.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 10.05.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import AudioKit

let modulationFrequency: Double = 15592
let bandwidth: Double = 2000

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let audiofile = try? AKAudioFile(readFileName: "affirmation_01.mp3") else { return }
        let player = AKPlayer(audioFile: audiofile)
        let booster = AKBooster(player)
        
        let modulatedPlayer = AKOperationEffect(booster) { booster, _ in
            let sine = AKOperation.sineWave(frequency: modulationFrequency)
            let modulation = booster * sine

            return modulation
        }
        
        let filter = AKBandPassButterworthFilter(modulatedPlayer, centerFrequency: modulationFrequency + 0.5 * bandwidth, bandwidth: bandwidth)

        AudioKit.output = filter
        
        do {
            try AudioKit.start()
        } catch {
            AKLog("AudioKit did not start!")
        }
        
        player.play()
    }


}

