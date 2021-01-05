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
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Playlist")
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "order", ascending: true)]
        
        do {
            let playlists = try CoreDataManager.sharedInstance.managedObjectContext.fetch(fetchRequest) as! [Playlist]
   
            if playlists.count == 0 {
                let playlist = NSEntityDescription.insertNewObject(forEntityName: "Playlist", into: self.managedObjectContext) as! Playlist
                playlist.title = "My Playlist"
                playlist.order = 0
                playlist.icon = UIImage(named: "playerPlaceholder")?.pngData()
                
                try self.managedObjectContext.save()
            }
            
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
    
    func createLibraryItem(title: String, icon: UIImage, hasOwnIcon: Bool) -> LibraryItem? {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Playlist")
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "order", ascending: true)]
        
        let libraryItem = NSEntityDescription.insertNewObject(forEntityName: "LibraryItem", into: self.managedObjectContext) as? LibraryItem
        
        do {
            let playlists = try CoreDataManager.sharedInstance.managedObjectContext.fetch(fetchRequest) as! [Playlist]
            let playlist = playlists.first // TODO
            
            
            libraryItem?.title = title
            libraryItem?.creationDate = Date()
            libraryItem?.icon = icon.pngData()
            libraryItem?.soundFileName = title // TODO
            libraryItem?.hasOwnIcon = hasOwnIcon
            //libraryItem.isActive = true
            
            if let item = libraryItem {
                SelectionHandler().selectLibraryItem(item)
                playlist?.addToLibraryItems(item)
            }
 
            try self.managedObjectContext.save()
            
            return libraryItem
            
        } catch {
            print(error)
        }
        
        return libraryItem
    }
    
    func updateLibraryItem(title: String, icon : UIImage, hasOwnIcon: Bool) {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LibraryItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "creationDate", ascending: true)] // TODO
        let predicate = NSPredicate(format: "title = %@", title as String)
        fetchRequest.predicate = predicate
        
        do {
            let libraryItems = try CoreDataManager.sharedInstance.managedObjectContext.fetch(fetchRequest) as! [LibraryItem]
            guard let libraryItem = libraryItems.first else { return } // TODO
            libraryItem.title = title
            libraryItem.icon = icon.pngData()
            libraryItem.hasOwnIcon = hasOwnIcon
            try self.managedObjectContext.save()
            
        } catch {
            print(error)
        }
    }
    
    func updateLibraryItem(item: LibraryItem, icon : UIImage) {
        item.icon = icon.pngData()
        save()
    }
    
    func createSubliminals() { // TODO: to library item
        createSubliminal(text: "I am a magnet for money. Prosperity is drawn to me")
        createSubliminal(text: "I welcome an unlimited source of income and wealth in my life")
        createSubliminal(text: "I constantly attract opportunities that create more money")
        createSubliminal(text: "My finances improve beyond my dreams")
        createSubliminal(text: "Money is the root of joy and comfort")
        createSubliminal(text: "Money and spirituality can co-exist in harmony")
//        createSubliminal(text: "0")
//        createSubliminal(text: "1")
//        createSubliminal(text: "2")
//        createSubliminal(text: "3")
//        createSubliminal(text: "4")
//        createSubliminal(text: "5")
    }
    
    func createSubliminal(text: String) {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LibraryItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "creationDate", ascending: true)] // TODO
        
        do {
            let libraryItems = try CoreDataManager.sharedInstance.managedObjectContext.fetch(fetchRequest) as! [LibraryItem]
            guard let libraryItem = libraryItems.first else { return } // TODO
            
            let fetchRequest2 = NSFetchRequest<Subliminal> (entityName: "Subliminal")
            fetchRequest2.sortDescriptors = [NSSortDescriptor (key: "order", ascending: false)]
            guard let title = libraryItem.title else { return }
            let predicate2 = NSPredicate(format: "libraryItem.title = %@", title as String)
            fetchRequest2.predicate = predicate2

            let subliminals = try CoreDataManager.sharedInstance.managedObjectContext.fetch(fetchRequest2)
            let subliminal = NSEntityDescription.insertNewObject(forEntityName: "Subliminal", into: self.managedObjectContext) as! Subliminal
            if let lastOrder = subliminals.first?.order {
                subliminal.order = lastOrder + 1
            } else {
                subliminal.order = 0
            }
            subliminal.text = text
            libraryItem.addToSubliminals(subliminal)
            
            try self.managedObjectContext.save()
            
        } catch {
            print(error)
        }
    }
    
    func addSubliminal(text: String, libraryItem: LibraryItem) {
        
        do {
            let fetchRequest = NSFetchRequest<Subliminal> (entityName: "Subliminal")
            fetchRequest.sortDescriptors = [NSSortDescriptor (key: "order", ascending: false)]
            guard let title = libraryItem.title else { return }
            let predicate = NSPredicate(format: "libraryItem.title = %@", title as String)
            fetchRequest.predicate = predicate

            let subliminals = try CoreDataManager.sharedInstance.managedObjectContext.fetch(fetchRequest)
            let subliminal = NSEntityDescription.insertNewObject(forEntityName: "Subliminal", into: self.managedObjectContext) as! Subliminal
            if let lastOrder = subliminals.first?.order {
                subliminal.order = lastOrder + 1
            } else {
                subliminal.order = 0
            }
            subliminal.text = text
            libraryItem.addToSubliminals(subliminal)
            
            try self.managedObjectContext.save()
            
        } catch {
            print(error)
        }
    }
     
    func removeLibraryItem(item: LibraryItem) {
        
        CoreDataManager.sharedInstance.managedObjectContext.delete(item)
        save()
    }
    
    func removeSubliminal(item: Subliminal) {
        
        CoreDataManager.sharedInstance.managedObjectContext.delete(item)
        save()
    }
    
    func moveSubliminal(item: Subliminal, fromOrder: Int, toOrder: Int) {
        
        item.order = Int16(toOrder)

        do {
            let fetchRequest = NSFetchRequest<Subliminal> (entityName: "Subliminal")
            fetchRequest.sortDescriptors = [NSSortDescriptor (key: "order", ascending: true)]
            let fetchedResultsController = NSFetchedResultsController<Subliminal> (
                fetchRequest: fetchRequest,
                managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil)
            try fetchedResultsController.performFetch()
            
            var array: [Subliminal]  = Array()
            
            if let subliminals = fetchedResultsController.fetchedObjects {

                for subliminal in subliminals {
                    array.append(subliminal)
                }

                array.move(item, to: toOrder)

                for (index, subliminal) in array.enumerated() {
                    subliminal.order = Int16(index)
                }
                
            }
        } catch {
            print("An error occurred")
        }
        
        save()
    }
    

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

class SelectionHandler {

    func clearSelection(in context: NSManagedObjectContext) {
        for item in currentSelected(in: context) {
            item.isActive = false
        }
    }

    func selectLibraryItem(_ item: LibraryItem) {
        guard let context = item.managedObjectContext else {
            assertionFailure("broken !")
            return
        }

        clearSelection(in: context)
        item.isActive = true
    }

    func currentSelected(in context: NSManagedObjectContext) -> [LibraryItem] {
        let request = NSFetchRequest<LibraryItem>(entityName: LibraryItem.entity().name!)
        let predicate = NSPredicate(format: "isActive == true")
        request.predicate = predicate

        do {
            let result = try context.fetch(request)
            return result
        } catch  {
            print("fetch error =",error)
            return []
        }
    }
}



extension Array where Element: Equatable {
    mutating func move(_ item: Element, to newIndex: Index) {
        if let index = firstIndex(of: item) {
            move(at: index, to: newIndex)
        }
    }

    mutating func bringToFront(item: Element) {
        move(item, to: 0)
    }

    mutating func sendToBack(item: Element) {
        move(item, to: endIndex-1)
    }
}

extension Array {
    mutating func move(at index: Index, to newIndex: Index) {
        insert(remove(at: index), at: newIndex)
    }
}
