//
//  Misc.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 20.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import UIKit

func getFileFromMainBundle(filename: String) -> URL? {
    
    let array = filename.split(separator: ".")
    
    if let filePath: String = Bundle.main.path(forResource: String(array.first!), ofType: String(array.last!)) {
        return URL(fileURLWithPath: filePath)
    }
    return nil
}

func getFileFromSandbox(filename: String) -> URL {
    return getDocumentsDirectory().appendingPathComponent(filename)
}


func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
}

func getLayerAnimation() -> CAAnimationGroup {
    
    let groupAnimation = CAAnimationGroup()
    groupAnimation.duration = 1.5
    groupAnimation.repeatCount = .infinity
    
    let layerAnimation = CABasicAnimation(keyPath: "transform.scale")
    layerAnimation.fromValue = 1
    layerAnimation.toValue = 2
    layerAnimation.isAdditive = false
    layerAnimation.fillMode = CAMediaTimingFillMode.forwards
    layerAnimation.isRemovedOnCompletion = true
    layerAnimation.repeatCount = .infinity
    layerAnimation.autoreverses = false
    
    let pulseAnimation = CABasicAnimation(keyPath: "opacity")
    pulseAnimation.fromValue = 1
    pulseAnimation.toValue = 0
    pulseAnimation.isAdditive = false
    pulseAnimation.fillMode = CAMediaTimingFillMode.both
    pulseAnimation.isRemovedOnCompletion = true
    //pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    pulseAnimation.autoreverses = true
    pulseAnimation.repeatCount = .greatestFiniteMagnitude
    
    groupAnimation.animations = [layerAnimation, pulseAnimation]
    
    return groupAnimation
}

extension URL    {
    func checkFileExist() -> Bool {
        let path = self.path
        if (FileManager.default.fileExists(atPath: path))   {
            print("FILE AVAILABLE")
            return true
        }else        {
            print("FILE NOT AVAILABLE")
            return false;
        }
    }
}
