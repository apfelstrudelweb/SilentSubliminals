//
//  SpectrumViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 24.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import CoreAudio
import AVFoundation
import Accelerate

class SpectrumViewController: UIViewController {
    
    var fftSetup : vDSP_DFT_Setup?
    
    let spectrumLayer = CAShapeLayer.init()
    var frequencyDomainGraphLayerIndex = 0
    let frequencyDomainGraphLayers = [CAShapeLayer(), CAShapeLayer(),
                                      CAShapeLayer(), CAShapeLayer()]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = PlayerControlColor.darkGrayColor
        self.view.layer.cornerRadius = cornerRadius
        self.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        fftSetup = vDSP_DFT_zop_CreateSetup(nil, 1024, vDSP_DFT_Direction.FORWARD)
        
        frequencyDomainGraphLayers.forEach {
            self.view.layer.addSublayer($0)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        frequencyDomainGraphLayers.forEach {
            $0.frame = self.view.frame.insetBy(dx: 0, dy: 0)
        }
    }
    
    func processAudioData(buffer: AVAudioPCMBuffer) {
        
        guard let channelData = buffer.floatChannelData?[0] else {return}
        let frames = buffer.frameLength
        
        let rmsValue = SignalProcessing.rms(data: channelData, frameLength: UInt(frames))
        
        if rmsValue == -.infinity { return }
        
        spectrumLayer.removeFromSuperlayer()
        
        
        //fft
        let fftMagnitudes: [Float] =  SignalProcessing.fft(data: channelData, setup: fftSetup!)
        
        let path = UIBezierPath.init()
        let width = self.view.frame.size.width
        let height = self.view.frame.size.height
        
        var maxFFT: Float = 0
        
        for magn in fftMagnitudes {
            if magn.magnitude > maxFFT {
                maxFFT = magn.magnitude
            }
        }
        
        if maxFFT == 0 { return }
        
        path.move(to: CGPoint(x: 0, y: height))
        
        var x1: CGFloat = 0
        var y1: CGFloat = height
        var x2: CGFloat = 0
        var y2: CGFloat = height
        
        for (index, element) in fftMagnitudes.enumerated() {
            //print("Item \(index): \(element)")
            
            x2 = x1
            y2 = y1
            
            //            if index == fftMagnitudes.count / 4 {
            //                break
            //            }
            
            let xUnit = width / log10(1000)
            
            x1 = CGFloat(log10f(Float(index + 1))) * xUnit //CGFloat(4 * index) * width / CGFloat(fftMagnitudes.count)
            y1 = height - CGFloat(rmsValue / 80) * CGFloat(element.magnitude) * height / CGFloat(maxFFT)
            
            if y1 < 0 {
                y1 = 0
            }
            
            //path.addLine(to: CGPoint(x: x, y: y))
            
            if x1 > width {
                break
            }
            
            path.addQuadCurve(to: CGPoint(x: x1, y: y1), controlPoint: CGPoint(x: x2, y: y2))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        
        path.close()
        
        spectrumLayer.path = path.cgPath
        spectrumLayer.fillColor = UIColor.green.cgColor
        self.view.layer.addSublayer(spectrumLayer)
    }
}
