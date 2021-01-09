//
//  MediathekViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 02.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import CoreData

class MediathekViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, UIGestureRecognizerDelegate {
    
    
    var fetchedResultsControllerRecent: NSFetchedResultsController<LibraryItem>!
    var fetchedResultsControllerPlaylist: NSFetchedResultsController<LibraryItem>!
    
    var recentItems: [LibraryItem]?
    var playlistItems: [LibraryItem]?
    var purchaseItems = ["plusSymbolGreen", "meditation_03", "meditation_05", "meditation_01", "meditation_08"]
    var creationItems = ["plusSymbolGreen", "meditation_02", "meditation_01", "meditation_09", "meditation_05"]
    
    var selectedAffirmation: Subliminal?
    
    
    @IBOutlet weak var recentSubliminalsCollectionView: UICollectionView!
    @IBOutlet weak var playlistCollectionView: PlaylistCollectionView!
    @IBOutlet weak var creationsCollectionView: CreationsCollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = .white
        
        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 1.0 // 1 second press
        longPressGesture.delegate = self
        playlistCollectionView.addGestureRecognizer(longPressGesture)
    }
    
    @objc func handleLongPress(longPressGesture:UILongPressGestureRecognizer) {
        
        let p = longPressGesture.location(in: self.playlistCollectionView)
        guard let indexPath = self.playlistCollectionView.indexPathForItem(at: p) else { return }
        
        if (longPressGesture.state == UIGestureRecognizer.State.began) {
            print("Long press on row, at \(indexPath.row)")
            
            guard let item = playlistItems?[indexPath.row], let title = item.title else {
                return
            }
            
            DispatchQueue.main.async {
                let cell = self.playlistCollectionView!.cellForItem(at: indexPath) as! MediathekCollectionViewCell
                cell.shake {
                    let alert = UIAlertController(title: title, message: "Do you really want to delete this item permanently?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { _ in
                        CoreDataManager.sharedInstance.deleteLibraryItem(item: item)
                        
                        do {
                            try self.fetchedResultsControllerRecent.performFetch()
                            try self.fetchedResultsControllerPlaylist.performFetch()
                            self.recentItems = self.fetchedResultsControllerRecent.fetchedObjects!
                            self.playlistItems = self.fetchedResultsControllerPlaylist.fetchedObjects!
                            
                            self.recentSubliminalsCollectionView.reloadData()
                        } catch {
                            print("An error occurred")
                        }
                        
                        self.recentSubliminalsCollectionView.reloadData()
                        self.playlistCollectionView.reloadData()
                    }))
                    alert.addAction(UIAlertAction(title: "NO", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                }
            }
        }
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
        
        
        if collectionView.isKind(of: RecentSubliminalsCollectionView.self) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "recentSubliminalCell", for: indexPath as IndexPath) as! MediathekCollectionViewCell
            guard let item = fetchedResultsControllerRecent.fetchedObjects?[indexPath.row] else { return cell }
            cell.symbolImageView.image = UIImage(data: item.icon ?? Data())
            if !item.hasOwnIcon {
                cell.title = item.title
            } else {
                cell.title = ""
            }
            return cell
        } else if collectionView.isKind(of: PlaylistCollectionView.self) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "playlistCell", for: indexPath as IndexPath) as! MediathekCollectionViewCell
            guard let item = fetchedResultsControllerPlaylist.fetchedObjects?[indexPath.row] else { return cell }
            cell.symbolImageView.image = UIImage(data: item.icon ?? Data())
            if !item.hasOwnIcon {
                cell.title = item.title
            } else {
                cell.title = ""
            }
            return cell
        } else if collectionView.isKind(of: PurchasesCollectionView.self) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "purchasesCell", for: indexPath as IndexPath) as! MediathekCollectionViewCell
            cell.symbolImageView.image = UIImage(named: purchaseItems[indexPath.row])
            return cell
        } else if collectionView.isKind(of: CreationsCollectionView.self) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "creationsCell", for: indexPath as IndexPath) as! MediathekCollectionViewCell
            cell.symbolImageView.image = UIImage(named: creationItems[indexPath.row])
            return cell
        }
        
        return MediathekCollectionViewCell()
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
    
    //    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
    //        return true
    //    }
    
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
