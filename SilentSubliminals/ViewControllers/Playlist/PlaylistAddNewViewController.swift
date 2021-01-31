//
//  PlaylistAddNewViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 25.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices
import EasyTipView


class PlaylistAddNewViewController: UIViewController, UITableViewDataSource {
    
    
    
    @IBOutlet weak var userPlaylistTableView: UserPlaylistTableView!
    @IBOutlet weak var defaultPlaylistTableView: DefaultPlaylistTableView!
    @IBOutlet weak var newPlaylistTitleLabel: UILabel!
    @IBOutlet weak var newPlaylistImageButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var tableViewEditButton: UIButton!
    
    var imagePicker: ImagePicker!

    var currentPlaylist: Playlist?
    var fetchedResultsControllerUserPlaylist: NSFetchedResultsController<Playlist>!
    var fetchedResultsControllerDefaultPlaylistItems: NSFetchedResultsController<LibraryItem>!
    var playlistItems: [LibraryItem]?
    
    var dropForbidden: Bool = false
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        userPlaylistTableView.dragDelegate = self
        userPlaylistTableView.dropDelegate = self
        defaultPlaylistTableView.dragDelegate = self
        defaultPlaylistTableView.dropDelegate = self

        userPlaylistTableView.dragInteractionEnabled = true
        defaultPlaylistTableView.dragInteractionEnabled = true
        
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
                                    //self.showUserPlaylistItems()
                                    self.getPlaylist(text)
                                }
                                
                            },
                            actionHandler: { (input:String?) in
                                self.newPlaylistTitleLabel.text = input?.capitalized
                            })
        } else {
            guard let title = currentPlaylist?.title else { return }
            self.getPlaylist(title)
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
    @IBAction func tableViewEditButtonTouched(_ sender: Any) {
        
        DispatchQueue.main.async {
            self.userPlaylistTableView.setEditing(!self.userPlaylistTableView.isEditing, animated: true)
            let imageName = self.userPlaylistTableView.isEditing ? "editSymbolOn" : "editSymbolOff"
            self.tableViewEditButton.setImage(UIImage(named: imageName), for: .normal)
        }
    }
    
    @IBAction func newPlaylistImageButtonTouched(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }
    
    func getPlaylist(_ title: String) {
        let fetchRequest = NSFetchRequest<Playlist> (entityName: "Playlist")
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "creationDate", ascending: true)]
        let predicate = NSPredicate(format: "title = %@", title)
        fetchRequest.predicate = predicate
        
        self.fetchedResultsControllerUserPlaylist = NSFetchedResultsController<Playlist> (
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        do {
            try fetchedResultsControllerUserPlaylist.performFetch()
            self.currentPlaylist = fetchedResultsControllerUserPlaylist.fetchedObjects?.first
            
            self.userPlaylistTableView.reloadData()
            self.userPlaylistTableView.tableFooterView = UIView()
        } catch {
            print("An error occurred")
        }
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
            return currentPlaylist?.libraryItems?.count ?? 0//fetchedResultsControllerUserPlaylistItems == nil ? 0 : fetchedResultsControllerUserPlaylistItems.fetchedObjects?.count ?? 0
        } else {
            return fetchedResultsControllerDefaultPlaylistItems == nil ? 0 : fetchedResultsControllerDefaultPlaylistItems.fetchedObjects?.count ?? 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "playlistItemCell", for: indexPath as IndexPath) as! PlaylistItemTableViewCell
        
        if tableView.isKind(of: UserPlaylistTableView.self) {
            guard let items = currentPlaylist?.libraryItems else { return cell }//fetchedResultsControllerUserPlaylistItems.fetchedObjects?[indexPath.row] else { return cell }
            let item = items[indexPath.row] as! LibraryItem
            cell.symbolImageView.image = UIImage(data: item.icon ?? Data())
            cell.titleLabel.text = item.title
        } else {
            guard let item = fetchedResultsControllerDefaultPlaylistItems.fetchedObjects?[indexPath.row] else { return cell }
            cell.symbolImageView.image = UIImage(data: item.icon ?? Data())
            cell.titleLabel.text = item.title
        }
      
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            
            guard let item = currentPlaylist?.libraryItems?[indexPath.row], let playlist = currentPlaylist, let title = playlist.title  else { return }
            CoreDataManager.sharedInstance.removeLibraryItemFromPlaylist(libraryItem: item as! LibraryItem, playlist: playlist)
            
            getPlaylist(title)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        guard let items = currentPlaylist?.libraryItems, let playlist = currentPlaylist else { return }
        let movedItem = items[sourceIndexPath.row] as! LibraryItem
        print(movedItem)

        CoreDataManager.sharedInstance.moveLibraryItemInPlaylist(playlist: playlist, item: movedItem, fromOrder: sourceIndexPath.row, toOrder: destinationIndexPath.row)
        self.userPlaylistTableView.reloadData()
    }
    
    private func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}

extension PlaylistAddNewViewController: UITableViewDragDelegate, UITableViewDropDelegate {
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        print("performDropWith")
        
        if dropForbidden { return }
        
        let destinationIndexPath: IndexPath

        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = userPlaylistTableView.numberOfSections - 1
            let row = userPlaylistTableView.numberOfRows(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        
        coordinator.session.loadObjects(ofClass: NSString.self) { items in
            // convert the item provider array to a string array or bail out
            guard let strings = items as? [String] else { return }

            // create an empty array to track rows we've copied
            var indexPaths = [IndexPath]()

            // loop over all the strings we received
            for (index, string) in strings.enumerated() {
  
                let indexPath = IndexPath(row: destinationIndexPath.row + index, section: destinationIndexPath.section)
                CoreDataManager.sharedInstance.addLibraryItemToPlaylist(playlistObjectID: self.currentPlaylist!.objectID, order: indexPath.row, title: string)
                indexPaths.append(indexPath)
            }

            //self.showUserPlaylistItems()
            guard let title = self.currentPlaylist?.title else { return }
            self.getPlaylist(title)
            self.userPlaylistTableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        print("itemsForBeginning")
        
        dropForbidden = false
        
        guard let item = fetchedResultsControllerDefaultPlaylistItems.fetchedObjects?[indexPath.row] else { return [] }
        guard let data = item.title?.data(using: .utf8) else { return [] }
        
        if let items = currentPlaylist?.libraryItems {
            for el in items.array {
                let libraryItem = el as! LibraryItem
                if libraryItem.title == item.title {
                    self.showDragDropWarning(title: item.title!)
                    dropForbidden = true
                    return [UIDragItem]()
                }
            }
        }
        
        let itemProvider = NSItemProvider(item: data as NSData, typeIdentifier: kUTTypePlainText as String)
        return [UIDragItem(itemProvider: itemProvider)]
    }
    
    func showDragDropWarning(title: String) {
        
        DispatchQueue.main.async {
            
            var preferences = EasyTipView.Preferences()
            preferences.drawing.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            preferences.drawing.foregroundColor = .white
            preferences.drawing.backgroundColor = .red
            preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.top
            preferences.animating.showDuration = 1.5
            preferences.animating.dismissDuration = 1.5
            
            let tipView = EasyTipView(text: "The item \(title) already exists in your playlist!", preferences: preferences)
            tipView.show(forView: self.userPlaylistTableView, withinSuperview: self.view)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                tipView.dismiss()
            }
        }
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
