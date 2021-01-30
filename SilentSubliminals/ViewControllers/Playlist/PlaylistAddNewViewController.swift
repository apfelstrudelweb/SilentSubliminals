//
//  PlaylistAddNewViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 25.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import CoreData

class PlaylistAddNewViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var userPlaylistTableView: UserPlaylistTableView!
    @IBOutlet weak var defaultPlaylistTableView: DefaultPlaylistTableView!
    @IBOutlet weak var newPlaylistTitleLabel: UILabel!
    @IBOutlet weak var newPlaylistImageButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    var imagePicker: ImagePicker!

    var currentPlaylist: Playlist?
    var fetchedResultsControllerUserPlaylistItems: NSFetchedResultsController<LibraryItem>!
    var fetchedResultsControllerDefaultPlaylistItems: NSFetchedResultsController<LibraryItem>!
    var playlistItems: [LibraryItem]?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)

        newPlaylistTitleLabel.text = currentPlaylist?.title
        if let iconData = currentPlaylist?.icon {
            newPlaylistImageButton.setImage(UIImage(data: iconData), for: .normal)
        }
        

        if currentPlaylist == nil {

            showInputDialog(title: "Action required",
                            subtitle: "Please enter a name for your playlist",
                            actionTitle: "Add",
                            cancelTitle: "Cancel",
                            inputText: "",
                            inputPlaceholder: "Your playlist title",
                            inputKeyboardType: .default,
                            completionHandler: { (text) in
                                self.currentPlaylist = CoreDataManager.sharedInstance.createPlaylist(title: text, icon: nil)
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    self.showUserPlaylistItems()
                                }
                                
                            },
                            actionHandler: { (input:String?) in
                                self.newPlaylistTitleLabel.text = input?.capitalized
                            })
        } else {
            self.showUserPlaylistItems()
        }
        
        showDefaultPlaylistItems()
 
    }
    
    @IBAction func editButtonTouched(_ sender: Any) {
        
        showInputDialog(title: "Action required",
                        subtitle: "Please enter a new name for your playlist",
                        actionTitle: "Change",
                        cancelTitle: "Cancel",
                        inputText: currentPlaylist?.title,
                        inputPlaceholder: "Your playlist title",
                        inputKeyboardType: .default,
                        completionHandler: { (text) in
                            guard let objectId = self.currentPlaylist?.objectID else { return }
                            CoreDataManager.sharedInstance.updatePlaylist(objectID: objectId, title: text, icon: nil)
                        },
                        actionHandler: { (input:String?) in
                            self.newPlaylistTitleLabel.text = input?.capitalized
                        })
    }
    
    @IBAction func newPlaylistImageButtonTouched(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }
    
    
    func showUserPlaylistItems() {
        
        guard let playlist = self.currentPlaylist else { return }
        
//        CoreDataManager.sharedInstance.addLibraryItemToPlaylist(playlistObjectID: currentPlaylist!.objectID, title: "Jeanstyp") // TODO: per drag&drop
//        CoreDataManager.sharedInstance.addLibraryItemToPlaylist(playlistObjectID: currentPlaylist!.objectID, title: "Engineered") // TODO: per drag&drop
//        CoreDataManager.sharedInstance.addLibraryItemToPlaylist(playlistObjectID: currentPlaylist!.objectID, title: "Jeansjacke")
        
        let fetchRequest = NSFetchRequest<LibraryItem> (entityName: "LibraryItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "creationDate", ascending: true)]
        let predicate = NSPredicate(format: "ANY playlists = %@", playlist)
        fetchRequest.predicate = predicate
        fetchRequest.relationshipKeyPathsForPrefetching = ["Playlist"]

        self.fetchedResultsControllerUserPlaylistItems = NSFetchedResultsController<LibraryItem> (
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        do {
            try fetchedResultsControllerUserPlaylistItems.performFetch()
        } catch {
            print("An error occurred")
        }
        
        userPlaylistTableView.reloadData()
        userPlaylistTableView.tableFooterView = UIView()
    }
    
    func showDefaultPlaylistItems() {
        
        let fetchRequest = NSFetchRequest<LibraryItem> (entityName: "LibraryItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "creationDate", ascending: false)]
        let predicate = NSPredicate(format: "isDummyItem == false")
        fetchRequest.predicate = predicate
        self.fetchedResultsControllerDefaultPlaylistItems = NSFetchedResultsController<LibraryItem> (
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)

        do {
            try fetchedResultsControllerDefaultPlaylistItems.performFetch()
        } catch {
            print("An error occurred")
        }

        defaultPlaylistTableView.tableFooterView = UIView()
    }
    
}

extension PlaylistAddNewViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.isKind(of: UserPlaylistTableView.self) {
            return fetchedResultsControllerUserPlaylistItems == nil ? 0 : fetchedResultsControllerUserPlaylistItems.fetchedObjects?.count ?? 0
        } else {
            return fetchedResultsControllerDefaultPlaylistItems == nil ? 0 : fetchedResultsControllerDefaultPlaylistItems.fetchedObjects?.count ?? 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "playlistItemCell", for: indexPath as IndexPath) as! PlaylistItemTableViewCell
        
        if tableView.isKind(of: UserPlaylistTableView.self) {
            guard let item = fetchedResultsControllerUserPlaylistItems.fetchedObjects?[indexPath.row] else { return cell }
            cell.symbolImageView.image = UIImage(data: item.icon ?? Data())
            cell.titleLabel.text = item.title
        } else {
            guard let item = fetchedResultsControllerDefaultPlaylistItems.fetchedObjects?[indexPath.row] else { return cell }
            cell.symbolImageView.image = UIImage(data: item.icon ?? Data())
            cell.titleLabel.text = item.title
        }
      
        return cell
    }
}

extension PlaylistAddNewViewController: ImagePickerDelegate {
    
    func didSelect(image: UIImage?) {
        guard let img = image else {
            return
        }
        newPlaylistImageButton.setImage(img, for: .normal)
        guard let objectId = currentPlaylist?.objectID else { return }
        CoreDataManager.sharedInstance.updatePlaylist(objectID: objectId, title: title, icon: img)
    }
}
