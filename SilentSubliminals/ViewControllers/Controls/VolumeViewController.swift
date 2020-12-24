//
//  VolumeViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 24.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import CoreAudio
import AVFoundation
import Accelerate

class VolumeViewController: UIViewController {

    let maskView = UIView()
    var deviceVolume: Float?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .red

        let colors = [UIColor.blue, UIColor.green, UIColor.yellow, UIColor.red]
        self.maskView.backgroundColor = .white
        self.view.showGradientColors(colors)
        self.view.addSubview(self.maskView)
        self.view.mask = self.maskView
        self.maskView.frame = .zero//self.view.frame

        do {
            try AVAudioSession.sharedInstance().setActive(true)
            deviceVolume = AVAudioSession.sharedInstance().outputVolume
        } catch {
            print("Error Setting Up Audio Session")
        }
    }
    
    func processAudioData(buffer: AVAudioPCMBuffer) {
        
        let volume = self.getVolume(from: buffer, bufferSize: 1024) * (deviceVolume ?? defaultSliderVolume) * (VolumeManager.shared.sliderVolume ?? defaultSliderVolume)
        
        let w = Double(self.view.frame.size.width)
        let h = Double(self.view.bounds.size.height)
        
        UIView.animate(withDuration: 0.2) {
            self.maskView.frame = CGRect(x: 0.0, y: 0.0, width: Double(5 * volume) * w, height: h)
        }
    }
    
    private func getVolume(from buffer: AVAudioPCMBuffer, bufferSize: Int) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else {
            return 0
        }
        
        let channelDataArray = Array(UnsafeBufferPointer(start:channelData, count: bufferSize))
        
        var outEnvelope = [Float]()
        var envelopeState:Float = 0
        let envConstantAtk:Float = 0.16
        let envConstantDec:Float = 0.003
        
        for sample in channelDataArray {
            let rectified = abs(sample)
            
            if envelopeState < rectified {
                envelopeState += envConstantAtk * (rectified - envelopeState)
            } else {
                envelopeState += envConstantDec * (rectified - envelopeState)
            }
            outEnvelope.append(envelopeState)
        }
        
        // 0.007 is the low pass filter to prevent
        // getting the noise entering from the microphone
        if let maxVolume = outEnvelope.max(),
           maxVolume > Float(0.015) {
            return maxVolume
        } else {
            return 0.0
        }
    }

}



extension UIView {
    
    enum GradientColorDirection {
        case vertical
        case horizontal
    }
    
    func showGradientColors(_ colors: [UIColor], opacity: Float = 0.8, direction: GradientColorDirection = .horizontal) {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.opacity = opacity
        gradientLayer.colors = colors.map { $0.cgColor }
        
        if case .horizontal = direction {
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.0)
        }
        
        gradientLayer.locations = [0.0, 0.2, 0.4, 0.6]
        
        gradientLayer.bounds = self.bounds
        gradientLayer.anchorPoint = CGPoint.zero
        gradientLayer.cornerRadius = self.layer.cornerRadius
        self.layer.addSublayer(gradientLayer)
    }
}
