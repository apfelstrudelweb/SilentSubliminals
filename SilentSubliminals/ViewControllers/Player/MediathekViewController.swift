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
    
    var fetchedResultsController1: NSFetchedResultsController<LibraryItem>!
    
    var recentSubliminalItems = ["meditation_01", "meditation_02", "meditation_03", "meditation_04", "meditation_05"]
    var playlistItems: [LibraryItem]? //["plusSymbolGreen", "meditation_06", "meditation_07", "meditation_08", "meditation_09"]
    var purchaseItems = ["plusSymbolGreen", "meditation_03", "meditation_05", "meditation_01", "meditation_08"]
    var creationItems = ["plusSymbolGreen", "meditation_02", "meditation_01", "meditation_09", "meditation_05"]
    
    var selectedAffirmation: Subliminal?
    

    @IBOutlet weak var recentSubliminalsCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.tintColor = .white
        
        let fetchRequest1 = NSFetchRequest<LibraryItem> (entityName: "LibraryItem")
        fetchRequest1.sortDescriptors = [NSSortDescriptor (key: "creationDate", ascending: true)]
        self.fetchedResultsController1 = NSFetchedResultsController<LibraryItem> (
            fetchRequest: fetchRequest1,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        self.fetchedResultsController1.delegate = self
        
        do {
            try fetchedResultsController1.performFetch()
            playlistItems = fetchedResultsController1.fetchedObjects!
        } catch {
            print("An error occurred")
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView.isKind(of: RecentSubliminalsCollectionView.self) {
            return self.recentSubliminalItems.count
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
            cell.symbolImageView.image = UIImage(named: recentSubliminalItems[indexPath.row])
        } else if collectionView.isKind(of: PlaylistCollectionView.self) {
            //cell.symbolImageView.image = UIImage(named: playlistItems[indexPath.row])
            //cell.symbolImageView.image = UIImage(data: playlistItems?[indexPath.row].icon ?? Data())
            guard let item = fetchedResultsController1.fetchedObjects?[indexPath.row] else { return cell }
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
 
        if let selectedItem = playlistItems?[indexPath.row], let fileName = selectedItem.soundFileName {
            spokenAffirmation = "\(fileName).caf"
            spokenAffirmationSilent = "\(fileName)Silent.caf"
            
            SelectionHandler().selectLibraryItem(selectedItem)
            CoreDataManager.sharedInstance.save()
        }

        self.performSegue(withIdentifier: "showPlayerSegue", sender: nil)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let vc = segue.destination as? SubliminalPlayerViewController {
            vc.affirmation = selectedAffirmation
        }

    }

}
