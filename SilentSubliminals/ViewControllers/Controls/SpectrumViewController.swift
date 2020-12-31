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
//import PureLayout

class SpectrumView : UIView {
    
    let spectrumLayer = CAShapeLayer.init()
    var frequencyDomainGraphLayerIndex = 0
    let frequencyDomainGraphLayers = [CAShapeLayer(), CAShapeLayer(),
                                      CAShapeLayer(), CAShapeLayer()]
    
    var cgContext: CGContext?
    
    func drawBezier(points: Array<CGPoint>) {
        
        cgContext?.setLineWidth(10.0)
        
        spectrumLayer.fillColor = spectrumColor.cgColor //UIColor.clear.cgColor
        spectrumLayer.strokeColor = spectrumColor.cgColor
        let bezierPath = quadCurvedPathWithPoints(points: points)
        spectrumLayer.path = bezierPath.cgPath
        
        cgContext?.strokePath()
        
        self.layer.addSublayer(spectrumLayer)
    }
    
    override func draw(_ rect: CGRect) {
        
        if let context = UIGraphicsGetCurrentContext() {
            cgContext = context
        }
    }
    
    func quadCurvedPathWithPoints(points: Array<CGPoint>) -> UIBezierPath {
        
        let path = UIBezierPath()
        
        var p1 = points.first ?? .zero
        path.move(to: p1)
        
        for i in stride(from: 1, to: points.count - 1, by: 1) {
            
            let p2 = points[i]
            let midPoint = midPointForPoints(p1: p1, p2: p2)
            path.addQuadCurve(to: midPoint, controlPoint: controlPointForPoints(p1: midPoint, p2: p1))
            path.addQuadCurve(to: midPoint, controlPoint: controlPointForPoints(p1: midPoint, p2: p2))
            
            p1 = p2
        }
        return path
    }
    
    func midPointForPoints(p1: CGPoint, p2:CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2.0, y: (p1.y + p2.y) / 2.0)
    }
    
    func controlPointForPoints(p1: CGPoint, p2:CGPoint) -> CGPoint {
        var controlPoint = midPointForPoints(p1: p1, p2: p2)
        let diffY = abs(p2.y - controlPoint.y)
        
        if p1.y < p2.y {
            controlPoint.y += diffY
        } else if p1.y > p2.y {
            controlPoint.y -= diffY
        }
        return controlPoint
    }
}

class SpectrumViewController: UIViewController {
    
    var fftSetup : vDSP_DFT_Setup?
    
    let spectrumView = SpectrumView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(spectrumView)
        spectrumView.autoPinEdgesToSuperviewEdges()
        
        self.view.backgroundColor = PlayerControlColor.darkGrayColor
        self.view.layer.cornerRadius = cornerRadius
        self.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.view.clipsToBounds = true
        
        fftSetup = vDSP_DFT_zop_CreateSetup(nil, 2048, vDSP_DFT_Direction.FORWARD)
        
        spectrumView.frequencyDomainGraphLayers.forEach {
            spectrumView.layer.addSublayer($0)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        spectrumView.frequencyDomainGraphLayers.forEach {
            $0.frame = self.view.frame.insetBy(dx: 0, dy: 0)
        }
    }
    
    func processAudioData(buffer: AVAudioPCMBuffer) {
        
        guard let channelData = buffer.floatChannelData?[0] else {return}
        let frames = buffer.frameLength
        
        let rmsValue = SignalProcessing.rms(data: channelData, frameLength: UInt(frames))
        
        if rmsValue == -.infinity { return }
        
        spectrumView.spectrumLayer.removeFromSuperlayer()
        
        var floatChannelData: [Float] = []
        
        for i in 0..<Int(buffer.frameLength) {
            floatChannelData.append((buffer.floatChannelData?[0][i])!)
        }
        
        
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
        
        if maxFFT == 0 {
            maxFFT = 1
            
        }
        
        path.move(to: CGPoint(x: 0, y: height))
        
        var points = Array<CGPoint>()
        
        let xUnit = width / log10(CGFloat(fftMagnitudes.count))
        
        for i in stride(from: 0, to: fftMagnitudes.count - 1, by: 1) {

            let x = i == 0 ? 0 : CGFloat(log10f(Float(i))) * xUnit
            let y = (i == 0 || i > fftMagnitudes.count - 10) ? height : height - CGFloat(rmsValue / 80) * CGFloat(fftMagnitudes[i]) * height / CGFloat(maxFFT)
            
            points.append(CGPoint(x: x, y: abs(y)))
        }
        
        spectrumView.drawBezier(points: points)
    }
    
    func clearGraph() {
        DispatchQueue.main.async {
            self.spectrumView.spectrumLayer.removeFromSuperlayer()
        }
    }
    
}
