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
        

        let colors = [UIColor.green, UIColor.yellow, UIColor.red]
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
        
        let volume = self.getVolume(from: buffer) * AVAudioSession.sharedInstance().outputVolume
        
        let w = Double(self.view.frame.size.width)
        let h = Double(self.view.bounds.size.height)
        
        UIView.animate(withDuration: 0.2) {
            self.maskView.frame = CGRect(x: 0.0, y: 0.0, width: Double(5 * volume) * w, height: h)
        }
    }
    
    private func getVolume(from buffer: AVAudioPCMBuffer) -> Float {
        
        guard let _ = buffer.floatChannelData?[0] else {
            return 0
        }
        
        var volume: Float = 0
        
        let arraySize = Int(buffer.frameLength)
        var channelSamples: [[DSPComplex]] = []
        let channelCount = Int(buffer.format.channelCount)
        
        for i in 0..<channelCount {
            
            channelSamples.append([])
            let firstSample = buffer.format.isInterleaved ? i : i*arraySize
            
            for j in stride(from: firstSample, to: arraySize, by: buffer.stride*2) {
                
                let channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: Int(buffer.format.channelCount))
                let floats = UnsafeBufferPointer(start: channels[0], count: Int(buffer.frameLength))
                channelSamples[i].append(DSPComplex(real: floats[j], imag: floats[j+buffer.stride]))
            }
        }
        
        for i in 0..<arraySize/2 {
            
            let imag = channelSamples[0][i].imag
            let real = channelSamples[0][i].real
            let magnitude = sqrt(pow(real,2)+pow(imag,2))
            
            volume += magnitude
        }
        return volume / Float(bufferSize)
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
        
        gradientLayer.locations = [0.0, 0.4, 0.6, 0.8]
        
        gradientLayer.bounds = self.bounds
        gradientLayer.anchorPoint = CGPoint.zero
        gradientLayer.cornerRadius = self.layer.cornerRadius
        self.layer.addSublayer(gradientLayer)
    }
}
