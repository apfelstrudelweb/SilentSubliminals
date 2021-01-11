//
//  Misc.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 20.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

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

func removeFileFromSandbox(filename: String) {
    
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    let fileURL = documentsURL!.appendingPathComponent(filename)
    
    let fileManager = FileManager.default
    
    do {
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(atPath: fileURL.path)
        } else {
            print("File does not exist")
        }
    } catch {
        print("Unable to copy file")
    }
}

func copyFileToDocumentsFolder(sourceURL: URL, targetFileName: String) -> URL{
    
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    let destURL = documentsURL!.appendingPathComponent(targetFileName)
    
    let fileManager = FileManager.default
    
    do {
        if fileManager.fileExists(atPath: destURL.path) {
            // Delete file
            try fileManager.removeItem(atPath: destURL.path)
        } else {
            print("File does not exist")
        }
        try fileManager.copyItem(at: sourceURL, to: destURL)
    } catch {
        print("Unable to copy file")
    }
    
    return destURL
}

func convertSoundFileToCaf(url: URL, completionHandler: @escaping(Bool) -> Void) {
    
    let fileMgr = FileManager.default
    let dirPaths = fileMgr.urls(for: .documentDirectory,
                                in: .userDomainMask)
    
    let outputUrl = dirPaths[0].appendingPathComponent(spokenAffirmation)
    let oldFileURL = url
    let asset = AVAsset.init(url: url)

    let fileManager = FileManager.default
    do {
        //try fileManager.removeItem(at: url)
        try fileManager.removeItem(at: outputUrl)
        
    } catch{
        print("can't remove item - maybe it doesn't exist")
    }
    
    let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)

        exporter?.outputURL = outputUrl
        exporter?.outputFileType = AVFileType.caf // error here
        exporter?.shouldOptimizeForNetworkUse = true

        exporter?.exportAsynchronously {

            print("exporter status =", exporter?.status as Any)

            switch exporter!.status {
            case .unknown:
                print("status unknown")
                completionHandler(false)
            case .waiting:
                print("status waiting")
            case .exporting:
                print("status exporting")
            case .completed:
                print("status completed")
                AudioHelper().createSilentSubliminalFile()
                do {
                    //try fileManager.removeItem(at: url)
                    try fileManager.removeItem(at: oldFileURL)
                    
                } catch{
                    print("can't remove item - maybe it doesn't exist")
                }
                completionHandler(true)
            case .failed:
                print("status failed")
                completionHandler(false)
            case .cancelled:
                print("status cancelled")
                completionHandler(false)
            @unknown default:
                print("@unknown default:")
                completionHandler(false)
            }
        }
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
