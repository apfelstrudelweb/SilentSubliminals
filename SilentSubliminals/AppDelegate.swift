//
//  AppDelegate.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 10.05.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var db = CoreDataManager.sharedInstance

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let navFont = UIFont.systemFont(ofSize: 26, weight: .medium)
        let navBarAttributesDictionary: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(rawValue: NSAttributedString.Key.foregroundColor.rawValue): PlayerControlColor.lightColor,
            NSAttributedString.Key(rawValue: NSAttributedString.Key.font.rawValue): navFont]
        UINavigationBar.appearance().titleTextAttributes = navBarAttributesDictionary
        UINavigationBar.appearance().setTitleVerticalPositionAdjustment(CGFloat(2), for: UIBarMetrics.default)

        UINavigationBar.appearance().backgroundColor = .clear
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().isTranslucent = true
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            //try audioSession.setCategory(recording ? .playAndRecord : .playback)
            try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setPreferredIOBufferDuration(128.0 / 44100.0)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set audio session category.")
        }
        
        db.managedObjectContext.automaticallyMergesChangesFromParent = true
        
        //CoreDataManager.sharedInstance.clearDB()
        CoreDataManager.sharedInstance.createPlaylist()
        CoreDataManager.sharedInstance.createLibraryItem()
        CoreDataManager.sharedInstance.createSubliminals()
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
}

