//
//  CoreDataManager.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 03.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class CoreDataManager: NSObject {
    
    static let sharedInstance = CoreDataManager()
    
    typealias CompletionHander = () -> ()
    
    fileprivate override init() {
        
    }
    
    // MARK: - Core Data stack
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.andrewcbancroft.Zootastic" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Subliminal", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        //        let url = self.applicationDocumentsDirectory.appendingPathComponent("Subliminal.sqlite")
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        let storeURL = url?.appendingPathComponent("Subliminal.sqlite")
        
        print("SQLite in \(String(describing: storeURL))")
        
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            let options = [NSInferMappingModelAutomaticallyOption:true,
                           NSMigratePersistentStoresAutomaticallyOption:true]
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            
            //            let alert = UIAlertController(title: "Ooops ... this should not happen!", message: "Something went wrong with the update. Please uninstall the app and install again from the AppStore!", preferredStyle: UIAlertControllerStyle.alert)
            //            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            //            let alertWindow = UIWindow(frame: UIScreen.main.bounds)
            //            alertWindow.rootViewController = UIViewController()
            //            alertWindow.windowLevel = UIWindowLevelAlert + 1;
            //            alertWindow.makeKeyAndVisible()
            //            alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    func clearDB() {
        // Override point for customization after application launch.
        
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        let storeURL = url?.appendingPathComponent("Subliminal.sqlite")
        
        let fm = FileManager.default
        do {
            try fm.removeItem(at:storeURL!)
        } catch {
            NSLog("Error deleting file: \(String(describing: storeURL))")
        }
    }
    
    func save() {
        do {
            try self.managedObjectContext.save()
        } catch {
            print(error)
        }
    }
    
    func createPlaylist() {
        let playlist = NSEntityDescription.insertNewObject(forEntityName: "Playlist", into: self.managedObjectContext) as! Playlist
        playlist.title = "My Playlist"
        playlist.order = 0
        playlist.icon = UIImage(named: "schmettering_transparent")?.pngData()
        
        do {
            try self.managedObjectContext.save()
        } catch {
            print(error)
        }
    }
    
    func createLibraryItem() {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Playlist")
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "order", ascending: true)]
        
        do {
            let playlists = try CoreDataManager.sharedInstance.managedObjectContext.fetch(fetchRequest) as! [Playlist]
            let playlist = playlists.first // TODO
            
            let libraryItem = NSEntityDescription.insertNewObject(forEntityName: "LibraryItem", into: self.managedObjectContext) as! LibraryItem
            libraryItem.title = "Wealth"
            libraryItem.creationDate = Date()
            libraryItem.icon = UIImage(named: "meditation_06")?.pngData()
            libraryItem.soundFileName = "wealthSubliminal"
            libraryItem.isActive = true
            
            playlist?.addToLibraryItems(libraryItem)
            try self.managedObjectContext.save()
            
        } catch {
            print(error)
        }
    }
    
    func createSubliminals() {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LibraryItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "creationDate", ascending: true)] // TODO
        
        do {
            let libraryItems = try CoreDataManager.sharedInstance.managedObjectContext.fetch(fetchRequest) as! [LibraryItem]
            let libraryItem = libraryItems.first // TODO
            
            let subliminal1 = NSEntityDescription.insertNewObject(forEntityName: "Subliminal", into: self.managedObjectContext) as! Subliminal
            subliminal1.order = 0
            subliminal1.text = "I am a magnet for money. Prosperity is drawn to me"
            
            let subliminal2 = NSEntityDescription.insertNewObject(forEntityName: "Subliminal", into: self.managedObjectContext) as! Subliminal
            subliminal2.order = 1
            subliminal2.text = "I welcome an unlimited source of income and wealth in my life"
            
            libraryItem?.addToSubliminals(subliminal1)
            libraryItem?.addToSubliminals(subliminal2)
            try self.managedObjectContext.save()
            
        } catch {
            print(error)
        }
        
    }
    
    
    
    func removeLibraryItem(item: LibraryItem) {
        
        CoreDataManager.sharedInstance.managedObjectContext.delete(item)
        save()
    }
    
    
    //    func removeFromTrainingsplan(workout:Workout) {
    //
    //        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Trainingsplan")
    //        let predicate = NSPredicate(format: "id = %d", workout.id)
    //        fetchRequest.predicate = predicate
    //
    //        do {
    //            let plan = try CoreDataManager.sharedInstance.managedObjectContext.fetch(fetchRequest).first as! Trainingsplan
    //            CoreDataManager.sharedInstance.managedObjectContext.delete(plan)
    //
    //        } catch {
    //            fatalError("Failed to delete object: \(error)")
    //        }
    //
    //        do {
    //            try self.managedObjectContext.save()
    //        } catch let error {
    //            print("Failure to save context: \(error.localizedDescription)")
    //        }
    //
    //
    //        // now avoid gaps in position indexes
    //        let fetchRequest2 = NSFetchRequest<NSFetchRequestResult>(entityName: "Trainingsplan")
    //        fetchRequest2.sortDescriptors = [NSSortDescriptor (key: "position", ascending: true)]
    //
    //        do {
    //            let plans = try CoreDataManager.sharedInstance.managedObjectContext.fetch(fetchRequest2) as! [Trainingsplan]
    //
    //            for (index, plan) in plans.enumerated() {
    //                plan.position = Int16(index)
    //            }
    //
    //        } catch let error {
    //            print("Failure to save context: \(error.localizedDescription)")
    //        }
    //
    //        do {
    //            try self.managedObjectContext.save()
    //        } catch let error {
    //            print("Failure to save context: \(error.localizedDescription)")
    //        }
    //
    //    }
    //
    //    func syncIndicesInTrainingsplan() {
    //        let fetchRequest2 = NSFetchRequest<NSFetchRequestResult>(entityName: "Trainingsplan")
    //        fetchRequest2.sortDescriptors = [NSSortDescriptor (key: "position", ascending: true)]
    //
    //        do {
    //            let plans = try CoreDataManager.sharedInstance.managedObjectContext.fetch(fetchRequest2) as! [Trainingsplan]
    //
    //            for (index, plan) in plans.enumerated() {
    //                plan.position = Int16(index)
    //            }
    //
    //        } catch let error {
    //            print("Failure to save context: \(error.localizedDescription)")
    //        }
    //
    //        do {
    //            try self.managedObjectContext.save()
    //        } catch let error {
    //            print("Failure to save context: \(error.localizedDescription)")
    //        }
    //    }
    //
    //    func updateWorkouts(serverWorkoutsData:[WorkoutData]?, completionHandler: CompletionHander?) {
    //        if let workouts = serverWorkoutsData {
    //
    //            // delete old data
    //            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Workout")
    //            let request = NSBatchDeleteRequest(fetchRequest: fetch)
    //            do {
    //                try managedObjectContext.execute(request)
    //                //try self.managedObjectContext.save()
    //            } catch let error {
    //                NSLog("Failure to delete context: \(error.localizedDescription)")
    //            }
    //
    //            for workout in workouts {
    //
    //                let _ = CoreDataManager.sharedInstance.insertWorkout(id: Int16(workout.id!), imgName: workout.imageName, isLive: workout.isLive==1, isPremium: workout.isPremium==1, alias: workout.alias, videoUrl: workout.videoUrl!, isDumbbell: workout.isDumbbell==1, isMat: workout.isMat==1, isBall: workout.isBall==1, isTheraband: workout.isTheraband==1, isMachine: workout.isMachine==1, intensity: Int16(workout.intensity!), musclegroupIds: workout.musclegroups!, titles: workout.title, instructions: workout.instructions, remarks: workout.remarks)
    //            }
    //
    //            do {
    //                try self.managedObjectContext.save()
    //            } catch let error {
    //                NSLog("Failure to save context: \(error.localizedDescription)")
    //            }
    //        }
    //
    //        completionHandler?()
    //    }
    
    func position(set: Set<Favorite>, id: Int16) -> Int16 {
        
        for item in set {
            if item.id == id {
                return item.position
            }
        }
        return -1
    }
}

class Favorite: NSObject {
    
    var id: Int16
    var position: Int16
    
    init(withId id: Int16, position: Int16) {
        self.id = id
        self.position = position
    }
    
}
