//
//  MediathekViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 02.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import CoreData

class MediathekViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    
    var fetchedResultsControllerRecent: NSFetchedResultsController<LibraryItem>!
    var fetchedResultsControllerPlaylist: NSFetchedResultsController<LibraryItem>!
    
    var recentItems: [LibraryItem]?
    var playlistItems: [LibraryItem]?
    var purchaseItems = ["plusSymbolGreen", "meditation_03", "meditation_05", "meditation_01", "meditation_08"]
    var creationItems = ["plusSymbolGreen", "meditation_02", "meditation_01", "meditation_09", "meditation_05"]
    
    var selectedAffirmation: Subliminal?
    

    @IBOutlet weak var recentSubliminalsCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.tintColor = .white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let fetchRequestRecent = NSFetchRequest<LibraryItem> (entityName: "LibraryItem")
        fetchRequestRecent.sortDescriptors = [NSSortDescriptor (key: "lastUsedDate", ascending: false)]
        let predicateRecent = NSPredicate(format: "lastUsedDate != null")
        fetchRequestRecent.predicate = predicateRecent
        self.fetchedResultsControllerRecent = NSFetchedResultsController<LibraryItem> (
            fetchRequest: fetchRequestRecent,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        self.fetchedResultsControllerRecent.delegate = self
        
        let fetchRequestPlaylist = NSFetchRequest<LibraryItem> (entityName: "LibraryItem")
        fetchRequestPlaylist.sortDescriptors = [NSSortDescriptor (key: "creationDate", ascending: true)]
        self.fetchedResultsControllerPlaylist = NSFetchedResultsController<LibraryItem> (
            fetchRequest: fetchRequestPlaylist,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        self.fetchedResultsControllerPlaylist.delegate = self
        
        do {
            try fetchedResultsControllerRecent.performFetch()
            try fetchedResultsControllerPlaylist.performFetch()
            recentItems = fetchedResultsControllerRecent.fetchedObjects!
            playlistItems = fetchedResultsControllerPlaylist.fetchedObjects!
            
            recentSubliminalsCollectionView.reloadData()
        } catch {
            print("An error occurred")
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView.isKind(of: RecentSubliminalsCollectionView.self) {
            return self.recentItems?.count ?? 0
        } else if collectionView.isKind(of: PlaylistCollectionView.self) {
            return self.playlistItems?.count ?? 0
        } else if collectionView.isKind(of: PurchasesCollectionView.self) {
            return self.purchaseItems.count
        } else if collectionView.isKind(of: CreationsCollectionView.self) {
            return self.creationItems.count
        }
        return 0
    }
    

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "recentSubliminalCell", for: indexPath as IndexPath) as! MediathekCollectionViewCell
        
        if collectionView.isKind(of: RecentSubliminalsCollectionView.self) {
            guard let item = fetchedResultsControllerRecent.fetchedObjects?[indexPath.row] else { return cell }
            cell.symbolImageView.image = UIImage(data: item.icon ?? Data())
            if !item.hasOwnIcon {
                cell.title = item.title
            } else {
                cell.title = ""
            }
        } else if collectionView.isKind(of: PlaylistCollectionView.self) {
            guard let item = fetchedResultsControllerPlaylist.fetchedObjects?[indexPath.row] else { return cell }
            cell.symbolImageView.image = UIImage(data: item.icon ?? Data())
            if !item.hasOwnIcon {
                cell.title = item.title
            } else {
                cell.title = ""
            }
        } else if collectionView.isKind(of: PurchasesCollectionView.self) {
            cell.symbolImageView.image = UIImage(named: purchaseItems[indexPath.row])
        } else if collectionView.isKind(of: CreationsCollectionView.self) {
            cell.symbolImageView.image = UIImage(named: creationItems[indexPath.row])
        }
 
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var item: LibraryItem?
        
        if collectionView.isKind(of: RecentSubliminalsCollectionView.self) {
            item = recentItems?[indexPath.row]
        }
        
        if collectionView.isKind(of: PlaylistCollectionView.self) {
            item = playlistItems?[indexPath.row]
        }
 
        if let selectedItem = item, let fileName = selectedItem.soundFileName {
            spokenAffirmation = "\(fileName).caf"
            spokenAffirmationSilent = "\(fileName)Silent.caf"
            
            SelectionHandler().selectLibraryItem(selectedItem)
            CoreDataManager.sharedInstance.save()
        }

        self.performSegue(withIdentifier: "showPlayerSegue", sender: nil)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //recentSubliminalsCollectionView.reloadData()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let vc = segue.destination as? SubliminalPlayerViewController {
            vc.affirmation = selectedAffirmation
        }

    }

}


//extension MediathekViewController: NSFetchedResultsControllerDelegate {
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//  }
//}
