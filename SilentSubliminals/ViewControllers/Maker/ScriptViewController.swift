//
//  ScriptViewController.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 18.10.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import CoreData

class ScriptViewController: UIViewController, NSFetchedResultsControllerDelegate {
    

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var buttonView: UIView!
    
    var fetchedResultsController1: NSFetchedResultsController<LibraryItem>!
    var fetchedResultsController2: NSFetchedResultsController<Subliminal>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.layer.cornerRadius = cornerRadius
        buttonView.layer.cornerRadius = cornerRadius
        
        imageView.layer.cornerRadius = cornerRadius
        imageView.clipsToBounds = true
        
        if UIDevice.current.userInterfaceIdiom == .phone {
           textView.textContainerInset = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)
        } else {
           textView.textContainerInset = UIEdgeInsets(top: 40, left: 20, bottom: 40, right: 20)
        }
        
        
        textView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        buttonView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let fetchRequest1 = NSFetchRequest<LibraryItem> (entityName: "LibraryItem")
        let predicate1 = NSPredicate(format: "isActive = true")
        fetchRequest1.predicate = predicate1
        fetchRequest1.sortDescriptors = [NSSortDescriptor (key: "creationDate", ascending: false)]
        self.fetchedResultsController1 = NSFetchedResultsController<LibraryItem> (
            fetchRequest: fetchRequest1,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        self.fetchedResultsController1.delegate = self
  
        do {
            try fetchedResultsController1.performFetch()
        } catch {
            print("An error occurred")
        }
  
        if let libraryItem = fetchedResultsController1.fetchedObjects?.first {
            titleLabel.text = libraryItem.title
            imageView.image = UIImage(data: libraryItem.icon ?? Data())
            
            if let title = libraryItem.title {
                let fetchRequest2 = NSFetchRequest<Subliminal> (entityName: "Subliminal")
                fetchRequest2.sortDescriptors = [NSSortDescriptor (key: "order", ascending: true)]
                let predicate2 = NSPredicate(format: "libraryItem.title = %@", title as String)
                fetchRequest2.predicate = predicate2
                self.fetchedResultsController2 = NSFetchedResultsController<Subliminal> (
                    fetchRequest: fetchRequest2,
                    managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
                    sectionNameKeyPath: nil,
                    cacheName: nil)
                self.fetchedResultsController2.delegate = self
                
                do {
                    try fetchedResultsController2.performFetch()
                    
                    if let subliminals = fetchedResultsController2.fetchedObjects {
                        var textViewText = String()
                        for subliminal in subliminals {
                            if let text = subliminal.text {
                                textViewText.append(text)
                                textViewText.append("\n\n")
                            }
                        }
                        textView.text = textViewText
                    }
                } catch {
                    print("An error occurred")
                }
            }
        }
    }
}

class SimpleAffirmation {
    var title: String?
    var text: String?
    var image: UIImage?
}
