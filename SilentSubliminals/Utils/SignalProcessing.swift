//
//  SignalProcessing.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 25.10.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Accelerate
import AVFoundation

class SignalProcessing {
    
    static var index: Int = 0
    
    static func rms(data: UnsafeMutablePointer<Float>, frameLength: UInt) -> Float {
        var val : Float = 0
        vDSP_measqv(data, 1, &val, frameLength)

        var db = 10*log10f(val)
  
        //inverse dB to +ve range where 0(silent) -> 160(loudest)
        db = 160 + db;
        //Only take into account range from 120->160, so FSR = 40
        db = db - 60

//        let dividor = Float(40/0.3)
//        var adjustedVal = 0.3 + db/dividor
        
        //print(adjustedVal)

//        //cutoff
//        if (adjustedVal < 0.3) {
//            adjustedVal = 0.3
//        } else if (adjustedVal > 0.6) {
//            adjustedVal = 0.6
//        }
        
        return db
    }
    
    static func fft(data: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float] {
        //output setup
        var realIn = [Float](repeating: 0, count: 2048)
        var imagIn = [Float](repeating: 0, count: 2048)
        var realOut = [Float](repeating: 0, count: 2048)
        var imagOut = [Float](repeating: 0, count: 2048)
        
        //fill in real input part with audio samples
        for i in 0...2047 {
            realIn[i] = data[i]
        }
    
        
        vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)

        //our results are now inside realOut and imagOut
        
        //package it inside a complex vector representation used in the vDSP framework
        var complex = DSPSplitComplex(realp: &realOut, imagp: &imagOut)
        
        //setup magnitude output
        var magnitudes = [Float](repeating: 0, count: Int(bufferSize))
        
        //calculate magnitude results
        vDSP_zvabs(&complex, 1, &magnitudes, 1, vDSP_Length(bufferSize))
        
        //normalize
        var normalizedMagnitudes = [Float](repeating: 0.0, count: Int(bufferSize))
        var scalingFactor = Float(25.0/Double(bufferSize))
        vDSP_vsmul(&magnitudes, 1, &scalingFactor, &normalizedMagnitudes, 1, vDSP_Length(bufferSize))
        
        return normalizedMagnitudes
    }
    
    static func getVolume(from buffer: AVAudioPCMBuffer) -> Float {
        
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
        return volume  * AVAudioSession.sharedInstance().outputVolume / Float(bufferSize)
    }
    
    static func checkForVolumeExceed(from buffer: AVAudioPCMBuffer) -> Bool {

        return getVolume(from: buffer) > 0.18
    }
}

