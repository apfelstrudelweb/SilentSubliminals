//
//  Misc.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 20.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import Foundation


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
