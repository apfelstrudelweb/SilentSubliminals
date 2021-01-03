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
    
    var fetchedResultsController: NSFetchedResultsController<Affirmation>!
    
    
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
        
        let fetchRequest = NSFetchRequest<Affirmation> (entityName: "Affirmation")
        let predicate = NSPredicate(format: "isActive = true")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "creationDate", ascending: false)]
        self.fetchedResultsController = NSFetchedResultsController<Affirmation> (
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        self.fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("An error occurred")
        }
        
        if let affirmation = fetchedResultsController.fetchedObjects?.first {
            titleLabel.text = affirmation.title
            imageView.image = UIImage(data: affirmation.icon ?? Data())
            textView.text = affirmation.text
        }
    }

}

class SimpleAffirmation {
    var title: String?
    var text: String?
    var image: UIImage?
}
