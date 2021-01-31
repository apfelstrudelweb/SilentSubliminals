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
    var fetchedResultsControllerCreation: NSFetchedResultsController<LibraryItem>!
    var fetchedResultsControllerPlaylist: NSFetchedResultsController<Playlist>!
    
    var recentItems: [LibraryItem]?
    var creationItems: [LibraryItem]?
    var playlistItems: [Playlist]?
    var purchaseItems = ["plusSymbolGreen", "meditation_03", "meditation_05", "meditation_01", "meditation_08"]
    

    var currentPlaylist: Playlist?
    
    var selectedAffirmation: Subliminal?
    
    var isEditingCreations: Bool = false
    var isEditingPlaylist: Bool = false
    
    
    @IBOutlet weak var recentSubliminalsCollectionView: RecentSubliminalsCollectionView!
    @IBOutlet weak var creationsCollectionView: CreationsCollectionView!
    @IBOutlet weak var playlistCollectionView: PlaylistCollectionView!
    @IBOutlet weak var editCreationsButton: UIButton!
    @IBOutlet weak var editPlaylistButton: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = .white

        let longPressGestureRecent:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressRecent))
        longPressGestureRecent.minimumPressDuration = 1.0 // 1 second press
        longPressGestureRecent.delegate = self
        recentSubliminalsCollectionView.addGestureRecognizer(longPressGestureRecent)
        
        let longPressGestureCreations:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressCreations))
        longPressGestureCreations.minimumPressDuration = 1.0 // 1 second press
        longPressGestureCreations.delegate = self
        //recentSubliminalsCollectionView.addGestureRecognizer(longPressGesture)
        creationsCollectionView.addGestureRecognizer(longPressGestureCreations)
        
        let longPressGesturePlaylist:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressPlaylist))
        longPressGesturePlaylist.minimumPressDuration = 1.0 // 1 second press
        longPressGesturePlaylist.delegate = self
        //recentSubliminalsCollectionView.addGestureRecognizer(longPressGesture)
        playlistCollectionView.addGestureRecognizer(longPressGesturePlaylist)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        currentPlaylist = nil
        isEditingCreations = false
        isEditingPlaylist = false
        displayCreationsEditingMode()
        displayPlaylistEditingMode()
        
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
        
        let fetchRequestCreations = NSFetchRequest<LibraryItem> (entityName: "LibraryItem")
        fetchRequestCreations.sortDescriptors = [NSSortDescriptor (key: "isDummyItem", ascending: false), NSSortDescriptor (key: "creationDate", ascending: false)]
        self.fetchedResultsControllerCreation = NSFetchedResultsController<LibraryItem> (
            fetchRequest: fetchRequestCreations,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        self.fetchedResultsControllerCreation.delegate = self
        
        let fetchRequestPlaylist = NSFetchRequest<Playlist> (entityName: "Playlist")
        fetchRequestPlaylist.sortDescriptors = [NSSortDescriptor (key: "isDefault", ascending: false), NSSortDescriptor (key: "creationDate", ascending: false)]
        self.fetchedResultsControllerPlaylist = NSFetchedResultsController<Playlist> (
            fetchRequest: fetchRequestPlaylist,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        self.fetchedResultsControllerPlaylist.delegate = self
        
        do {
            try fetchedResultsControllerRecent.performFetch()
            try fetchedResultsControllerCreation.performFetch()
            try fetchedResultsControllerPlaylist.performFetch()
            recentItems = fetchedResultsControllerRecent.fetchedObjects!
            creationItems = fetchedResultsControllerCreation.fetchedObjects!
            playlistItems = fetchedResultsControllerPlaylist.fetchedObjects!
            
            recentSubliminalsCollectionView.reloadData()
            creationsCollectionView.reloadData()
            playlistCollectionView.reloadData()
            
        } catch {
            print("An error occurred")
        }
    }
    
    @IBAction func editCreationsButtonTouched(_ sender: Any) {
        isEditingCreations = !isEditingCreations
        displayCreationsEditingMode()
    }
    
    @IBAction func editPlaylistButtonTouched(_ sender: Any) {
        isEditingPlaylist = !isEditingPlaylist
        displayPlaylistEditingMode()
    }
    
    
    func displayCreationsEditingMode() {

        editCreationsButton.tintColor = isEditingCreations ? .gray : .white
        
        creationsCollectionView.allowsMultipleSelection = false

        let indexPaths = creationsCollectionView.indexPathsForVisibleItems
        for indexPath in indexPaths {
            if indexPath.row == 0 { continue }
            let cell = creationsCollectionView.cellForItem(at: indexPath) as! MediathekCollectionViewCell
            cell.displayCheckmark(flag: isEditingCreations)
        }
    }
    
    func displayPlaylistEditingMode() {

        editPlaylistButton.tintColor = isEditingPlaylist ? .gray : .white
        
        playlistCollectionView.allowsMultipleSelection = false

        let indexPaths = playlistCollectionView.indexPathsForVisibleItems
        for indexPath in indexPaths {
            if indexPath.row == 0 { continue }
            let cell = playlistCollectionView.cellForItem(at: indexPath) as! MediathekCollectionViewCell
            cell.displayCheckmark(flag: isEditingPlaylist)
        }
    }
    
    // TODO: refactor
    @objc func handleLongPressRecent(longPressGesture:UILongPressGestureRecognizer) {
        
        let p = longPressGesture.location(in: self.recentSubliminalsCollectionView)
        guard let indexPath = self.recentSubliminalsCollectionView.indexPathForItem(at: p) else { return }
        
//        // + icon
//        if indexPath.row == 0 {
//            return
//        }
        
        if (longPressGesture.state == UIGestureRecognizer.State.began) {
            print("Long press on row, at \(indexPath.row)")
            
            guard let item = recentItems?[indexPath.row], let title = item.title else {
                return
            }
            
            DispatchQueue.main.async {
                let cell = self.recentSubliminalsCollectionView!.cellForItem(at: indexPath) as! MediathekCollectionViewCell
                cell.shake {
                    let alert = UIAlertController(title: title, message: "Do you really want to delete this item permanently?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { _ in
                        
                        if let fileName = item.soundFileName {
                           
                            removeFileFromSandbox(filename: String(format: audioTemplate, fileName))
                            removeFileFromSandbox(filename: String(format: audioSilentTemplate, fileName))
                        }
                        
                        CoreDataManager.sharedInstance.deleteLibraryItem(item: item)

                        do {
                            try self.fetchedResultsControllerRecent.performFetch()
                            try self.fetchedResultsControllerCreation.performFetch()
                            self.recentItems = self.fetchedResultsControllerRecent.fetchedObjects!
                            self.creationItems = self.fetchedResultsControllerCreation.fetchedObjects!
                            
                            self.recentSubliminalsCollectionView.reloadData()
                        } catch {
                            print("An error occurred")
                        }
                        
                        self.recentSubliminalsCollectionView.reloadData()
                        self.creationsCollectionView.reloadData()
                    }))
                    alert.addAction(UIAlertAction(title: "NO", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    @objc func handleLongPressCreations(longPressGesture:UILongPressGestureRecognizer) {
        
        let p = longPressGesture.location(in: self.creationsCollectionView)
        guard let indexPath = self.creationsCollectionView.indexPathForItem(at: p) else { return }
        
        // + icon
        if indexPath.row == 0 {
            return
        }
        
        if (longPressGesture.state == UIGestureRecognizer.State.began) {
            print("Long press on row, at \(indexPath.row)")
            
            guard let item = creationItems?[indexPath.row], let title = item.title else {
                return
            }
            
            DispatchQueue.main.async {
                let cell = self.creationsCollectionView!.cellForItem(at: indexPath) as! MediathekCollectionViewCell
                cell.shake {
                    let alert = UIAlertController(title: title, message: "Do you really want to delete this item permanently?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { _ in
                        
                        if let fileName = item.soundFileName {
                            removeFileFromSandbox(filename: String(format: audioTemplate, fileName))
                            removeFileFromSandbox(filename: String(format: audioSilentTemplate, fileName))
                        }
                        
                        CoreDataManager.sharedInstance.deleteLibraryItem(item: item)

                        do {
                            try self.fetchedResultsControllerRecent.performFetch()
                            try self.fetchedResultsControllerCreation.performFetch()
                            self.recentItems = self.fetchedResultsControllerRecent.fetchedObjects!
                            self.creationItems = self.fetchedResultsControllerCreation.fetchedObjects!
                            
                            self.recentSubliminalsCollectionView.reloadData()
                        } catch {
                            print("An error occurred")
                        }
                        
                        self.recentSubliminalsCollectionView.reloadData()
                        self.creationsCollectionView.reloadData()
                    }))
                    alert.addAction(UIAlertAction(title: "NO", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    
    @objc func handleLongPressPlaylist(longPressGesture:UILongPressGestureRecognizer) {
        
        let p = longPressGesture.location(in: self.playlistCollectionView)
        guard let indexPath = self.playlistCollectionView.indexPathForItem(at: p) else { return }
        
        // + icon
        if indexPath.row == 0 {
            return
        }
        
        if (longPressGesture.state == UIGestureRecognizer.State.began) {
            print("Long press on row, at \(indexPath.row)")
            
            guard let playlist = playlistItems?[indexPath.row], let title = playlist.title else {
                return
            }
            
            DispatchQueue.main.async {
                let cell = self.playlistCollectionView!.cellForItem(at: indexPath) as! MediathekCollectionViewCell
                cell.shake {
                    let alert = UIAlertController(title: title, message: "Do you really want to delete this item permanently?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { _ in
                        
                        CoreDataManager.sharedInstance.deletePlaylist(playlist: playlist)

                        do {
                            try self.fetchedResultsControllerPlaylist.performFetch()
                            self.playlistItems = self.fetchedResultsControllerPlaylist.fetchedObjects!

                        } catch {
                            print("An error occurred")
                        }
                        
                        self.playlistCollectionView.reloadData()
                    }))
                    alert.addAction(UIAlertAction(title: "NO", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                }
            }
        }
    }
   
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView.isKind(of: RecentSubliminalsCollectionView.self) {
            return self.recentItems?.count ?? 0
        } else if collectionView.isKind(of: CreationsCollectionView.self) {
            return self.creationItems?.count ?? 0
        } else if collectionView.isKind(of: PlaylistCollectionView.self) {
            return self.playlistItems?.count ?? 0
        } else if collectionView.isKind(of: PurchasesCollectionView.self) {
            return self.purchaseItems.count
        }
        return 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView.isKind(of: RecentSubliminalsCollectionView.self) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "recentSubliminalCell", for: indexPath as IndexPath) as! MediathekCollectionViewCell
            guard let item = fetchedResultsControllerRecent.fetchedObjects?[indexPath.row] else { return cell }
            cell.symbolImageView.image = UIImage(data: item.icon ?? Data())
            cell.titleLabel.text = item.title
            return cell
        } else if collectionView.isKind(of: CreationsCollectionView.self) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "creationsCell", for: indexPath as IndexPath) as! MediathekCollectionViewCell
            guard let item = fetchedResultsControllerCreation.fetchedObjects?[indexPath.row] else { return cell }
            cell.symbolImageView.image = UIImage(data: item.icon ?? Data())
            cell.titleLabel.text = item.title
            return cell
        } else if collectionView.isKind(of: PlaylistCollectionView.self) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "playlistCell", for: indexPath as IndexPath) as! MediathekCollectionViewCell
            guard let item = fetchedResultsControllerPlaylist.fetchedObjects?[indexPath.row] else { return cell }
            cell.symbolImageView.image = UIImage(data: item.icon ?? Data())
            cell.titleLabel.text = item.title
            return cell
        } else if collectionView.isKind(of: PurchasesCollectionView.self) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "purchasesCell", for: indexPath as IndexPath) as! MediathekCollectionViewCell
            cell.symbolImageView.image = UIImage(named: purchaseItems[indexPath.row])
            return cell
        }
        
        return MediathekCollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            (cell as! MediathekCollectionViewCell).displayCheckmark(flag: false)
            return
        }
        if collectionView.isKind(of: CreationsCollectionView.self) {
            (cell as! MediathekCollectionViewCell).displayCheckmark(flag: isEditingCreations)
        }
        if collectionView.isKind(of: PlaylistCollectionView.self) {
            (cell as! MediathekCollectionViewCell).displayCheckmark(flag: isEditingPlaylist)
        }
    }

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var item: LibraryItem?
        
        if collectionView.isKind(of: RecentSubliminalsCollectionView.self) {
            item = recentItems?[indexPath.row]
        }
        
        if collectionView.isKind(of: CreationsCollectionView.self) {
            item = creationItems?[indexPath.row]
            if isEditingCreations || indexPath.row == 0 {
                if let selectedItem = item {
                    SelectionHandler().selectLibraryItem(selectedItem)
                    self.performSegue(withIdentifier: "makerSegue", sender: nil)
                    return
                }
            }
        }
        
        if let selectedItem = item, let fileName = selectedItem.soundFileName {
            spokenAffirmation = String(format: audioTemplate, fileName)
            spokenAffirmationSilent = String(format: audioSilentTemplate, fileName)
            
            SelectionHandler().selectLibraryItem(selectedItem)
            CoreDataManager.sharedInstance.save()
        }
        
        if collectionView.isKind(of: PlaylistCollectionView.self)  {

            if indexPath.row > 0 {
                currentPlaylist = fetchedResultsControllerPlaylist.fetchedObjects?[indexPath.row]
            }

            if isEditingPlaylist || indexPath.row == 0 {
                self.performSegue(withIdentifier: "playlistSegue", sender: nil)
                return
            }
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
        if let vc = segue.destination as? SubliminalMakerViewController {

            if isEditingCreations {
                vc.editItemFromMediathek = true
                vc.createItemFromMediathek = false
            } else {
                vc.editItemFromMediathek = false
                vc.createItemFromMediathek = true
            }
        }
        
        if let vc = segue.destination as? PlaylistAddNewViewController {
            vc.currentPlaylist = currentPlaylist
        }

    }
    
}
