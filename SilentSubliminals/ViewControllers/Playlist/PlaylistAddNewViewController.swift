//
//  PlaylistAddNewViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 25.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import CoreData

class PlaylistAddNewViewController: UIViewController, UITableViewDataSource, AddAffirmationTextDelegate {
    
    @IBOutlet weak var userPlaylistTableView: UserPlaylistTableView!
    @IBOutlet weak var defaultPlaylistTableView: DefaultPlaylistTableView!
    
    
    var isEditingMode: Bool = false
    var hasOwnIcon = false
    
    var imagePicker: ImagePicker!
    
    var fetchedResultsControllerUserPlaylist: NSFetchedResultsController<LibraryItem>!
    var fetchedResultsControllerDefaultPlaylist: NSFetchedResultsController<LibraryItem>!
    
    
    func addSubliminal(text: String) {
        print(text)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
        
  
//        if !isEditingMode {
//
//            showInputDialog(title: "Action required",
//                            subtitle: "Please enter a name for your playlist",
//                            actionTitle: "Add",
//                            cancelTitle: "Cancel",
//                            inputText: "",
//                            inputPlaceholder: "Your playlist title",
//                            inputKeyboardType: .default,
//                            completionHandler: { (text) in
//                                //self.createNewLibraryItem()
//                            },
//                            actionHandler: { (input:String?) in
//                                //self.affirmationTitleLabel.text = input?.capitalized
//                            })
//        } else {
//            showExistingLibraryItem()
//        }
        
        showDefaultPlaylist()
        showUserPlaylist()
    }
    
    func showDefaultPlaylist() {
        
        let fetchRequest = NSFetchRequest<LibraryItem> (entityName: "LibraryItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "creationDate", ascending: false)]
        let predicate = NSPredicate(format: "isDummyItem == false")
        fetchRequest.predicate = predicate
        self.fetchedResultsControllerDefaultPlaylist = NSFetchedResultsController<LibraryItem> (
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)

        do {
            try fetchedResultsControllerDefaultPlaylist.performFetch()
        } catch {
            print("An error occurred")
        }

        defaultPlaylistTableView.tableFooterView = UIView()
    }
    
    func showUserPlaylist() {
        
        let fetchRequest = NSFetchRequest<LibraryItem> (entityName: "LibraryItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "creationDate", ascending: false)]
        let predicate = NSPredicate(format: "isDummyItem == false")
        fetchRequest.predicate = predicate
        self.fetchedResultsControllerUserPlaylist = NSFetchedResultsController<LibraryItem> (
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)

        do {
            try fetchedResultsControllerUserPlaylist.performFetch()
        } catch {
            print("An error occurred")
        }
        
        userPlaylistTableView.tableFooterView = UIView()
    }
    
}

extension PlaylistAddNewViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.isKind(of: UserPlaylistTableView.self) {
            return fetchedResultsControllerUserPlaylist == nil ? 0 : fetchedResultsControllerUserPlaylist.fetchedObjects?.count ?? 0
        } else {
            return fetchedResultsControllerDefaultPlaylist == nil ? 0 : fetchedResultsControllerDefaultPlaylist.fetchedObjects?.count ?? 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "playlistItemCell", for: indexPath as IndexPath) as! PlaylistItemTableViewCell
        
        if tableView.isKind(of: UserPlaylistTableView.self) {
            guard let item = fetchedResultsControllerUserPlaylist.fetchedObjects?[indexPath.row] else { return cell }
            cell.symbolImageView.image = UIImage(data: item.icon ?? Data())
            cell.titleLabel.text = item.title
        } else {
            guard let item = fetchedResultsControllerDefaultPlaylist.fetchedObjects?[indexPath.row] else { return cell }
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
//        coverImageButton.setImage(img, for: .normal)
//        coverImageButton.isOverriden = true
    }
}
