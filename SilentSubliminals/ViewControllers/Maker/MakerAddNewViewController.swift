//
//  MakerAddNewViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 02.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices


class MakerAddNewViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddAffirmationTextDelegate, UIDocumentPickerDelegate {

    @IBOutlet weak var affirmationTitleLabel: UILabel!
    @IBOutlet weak var coverImageButton: ImageButton!
    @IBOutlet weak var addAffirmationButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var importButton: UIButton!
    @IBOutlet weak var importFeedbackLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    var isEditingMode: Bool = false
    var hasOwnIcon = false
    
    private var addAffirmationViewController: AddAffirmationViewController?
    
    var imagePicker: ImagePicker!

    var fetchedResultsController: NSFetchedResultsController<LibraryItem>!
    var fetchedResultsController2: NSFetchedResultsController<Subliminal>!
    
    var currentLibraryItem: LibraryItem?
    
    let defaultImageButtonIcon = "playerPlaceholderSymbol"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = submitButton.tintColor
        coverImageButton.layer.cornerRadius = 10
        coverImageButton.clipsToBounds = true
        coverImageButton.setImage(name: defaultImageButtonIcon)
        addAffirmationButton.layer.cornerRadius = 0.5 * addAffirmationButton.frame.size.width
        addAffirmationButton.clipsToBounds = true

        tableView.isEditing = false
        
        
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
        
        // createNewLibraryItem(title: textField.text)
        
        if !isEditingMode {
            
            showInputDialog(title: "Action required",
                            subtitle: "Please enter a name for your library",
                            actionTitle: "Add",
                            cancelTitle: "Cancel",
                            inputText: "",
                            inputPlaceholder: "Your library title",
                            inputKeyboardType: .default,
                            completionHandler: { (text) in
                                //self.createNewLibraryItem(title: text)
                                self.createNewLibraryItem()
                            },
                            actionHandler: { (input:String?) in
                                self.affirmationTitleLabel.text = input?.capitalized
                            })
        } else {
            showExistingLibraryItem()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.importFeedbackLabel.alpha = 0
    }
    
    // MARK: UIDocumentPickerDelegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print(urls)
 
        guard let title = affirmationTitleLabel.text, let url = urls.first else { return }

        // TODO: refactor - it's too hacky ...
        spokenAffirmation = title + ".caf"
        spokenAffirmationSilent = title + "Silent.caf"
        
        let ext = url.pathExtension
        let filename = title + "." + ext
        let newFileURL = copyFileToDocumentsFolder(sourceURL: urls.first!, targetFileName: filename)
        convertSoundFileToCaf(url: newFileURL) { (success) in
            
            DispatchQueue.main.async {
                self.importFeedbackLabel.alpha = 1
                
                if success {
    
                    self.importFeedbackLabel.text = "Your import was successful."
                } else {
                    self.importFeedbackLabel.text = "Your import did fail!"
                }
            }
        }
    }
    
    func createNewLibraryItem() {
        
        var buttonImage = UIImage(named: "playerPlaceholder")
        
        if coverImageButton.isOverriden {
            buttonImage = coverImageButton.image(for: .normal)
        }
        
        guard let title = self.affirmationTitleLabel.text else { return }
        hasOwnIcon = coverImageButton.isOverriden

        currentLibraryItem = CoreDataManager.sharedInstance.createLibraryItem(title: title, icon: buttonImage ?? UIImage(), hasOwnIcon: hasOwnIcon)
    }
    
    func showExistingLibraryItem() {
        
        let fetchRequest = NSFetchRequest<LibraryItem> (entityName: "LibraryItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "creationDate", ascending: false)]
        let predicate = NSPredicate(format: "isActive == true")
        fetchRequest.predicate = predicate
        self.fetchedResultsController = NSFetchedResultsController<LibraryItem> (
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)

        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("An error occurred")
        }
        
        if let libraryItem = fetchedResultsController.fetchedObjects?.first, let imageData = libraryItem.icon {
            currentLibraryItem = libraryItem
            
            let icon = UIImage(data: imageData)
            coverImageButton.setImage(icon, for: .normal)
            
            self.affirmationTitleLabel.text = libraryItem.title
            
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
                } catch {
                    print("An error occurred")
                }
            }

        }
        
        tableView.tableFooterView = UIView()
    }
    
    @IBAction func coverImageButtonTouched(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }
    
    @IBAction func editButtonTouched(_ sender: Any) {
        
        DispatchQueue.main.async {
            self.tableView.isEditing = !self.tableView.isEditing
            
            let imageName = self.tableView.isEditing ? "editSymbolOn" : "editSymbolOff"
            self.editButton.setImage(UIImage(named: imageName), for: .normal)
        }

    }
    
    @IBAction func importButtonTouched(_ sender: Any) {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeAudio)], in: .import)
        //Call Delegate
        documentPicker.delegate = self
        
        self.present(documentPicker, animated: true)
    }
    
    
    @IBAction func submitButtonTouched(_ sender: Any) {
        
        //if isEditingMode {
            if let title = affirmationTitleLabel.text, let icon = coverImageButton.image(for: .normal), var hasOwnIcon = currentLibraryItem?.hasOwnIcon {
                if !hasOwnIcon {
                    hasOwnIcon = coverImageButton.isOverriden
                }
                CoreDataManager.sharedInstance.updateLibraryItem(title: title, icon: icon, hasOwnIcon: hasOwnIcon)
            }
//        } else {
//            //createNewLibraryItem()
//        }

        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func addAffirmationButtonTouched(_ sender: Any) {
        
        let optionMenu = UIAlertController(title: nil, message: "Here you can configure your subliminals", preferredStyle: .actionSheet)
        
        
        let selectFromLibraryAction = UIAlertAction(title: "Select from Library", style: .default)
        let typeOwnAction = UIAlertAction(title: "Type your own", style: .default, handler: { (action:UIAlertAction) in
            self.performSegue(withIdentifier: "addAffirmationSegue", sender: sender)
            
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        optionMenu.addAction(selectFromLibraryAction)
        optionMenu.addAction(typeOwnAction)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController2 == nil ? 0 : fetchedResultsController2.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "affirmationCell", for: indexPath as IndexPath) as! AffirmationTableViewCell
        cell.affirmationLabel?.text = fetchedResultsController2.fetchedObjects?[indexPath.row].text
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {

            let item = fetchedResultsController2.object(at: indexPath)
            CoreDataManager.sharedInstance.removeSubliminal(item: item)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        guard let movedSubliminal = fetchedResultsController2.fetchedObjects?[sourceIndexPath.row] else { return }
        CoreDataManager.sharedInstance.moveSubliminal(item: movedSubliminal, fromOrder: sourceIndexPath.row, toOrder: destinationIndexPath.row)
        
        self.tableView.reloadData()
    }
    
    private func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    // MARK: segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let vc = segue.destination as? AddAffirmationViewController {
            addAffirmationViewController = vc
            addAffirmationViewController?.delegate = self
        }
    }
    
    // AddAffirmationTextDelegate
    func addSubliminal(text: String) {

        if let item = currentLibraryItem {
            CoreDataManager.sharedInstance.addSubliminal(text: text, libraryItem: item)
            
            if let title = item.title {
                let fetchRequest2 = NSFetchRequest<Subliminal> (entityName: "Subliminal")
                fetchRequest2.sortDescriptors = [NSSortDescriptor (key: "order", ascending: true)]
                let predicate2 = NSPredicate(format: "libraryItem.title = %@", title as String)
                fetchRequest2.predicate = predicate2
                self.fetchedResultsController2 = NSFetchedResultsController<Subliminal> (
                    fetchRequest: fetchRequest2,
                    managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
                    sectionNameKeyPath: nil,
                    cacheName: nil)

                do {
                    try fetchedResultsController2.performFetch()
                } catch {
                    print("An error occurred")
                }
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
}

extension MakerAddNewViewController: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .move, .update:
            self.tableView.moveRow(at: indexPath!, to: newIndexPath!)
            fallthrough
        default:
            print(type)
        }
    }


    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }

}

extension MakerAddNewViewController: ImagePickerDelegate {
    
    func didSelect(image: UIImage?) {
        guard let img = image else {
            return
        }
        coverImageButton.setImage(img, for: .normal)
        coverImageButton.isOverriden = true
    }
}

extension UIViewController {
    func showInputDialog(title:String? = nil,
                         subtitle:String? = nil,
                         actionTitle:String? = "Add",
                         cancelTitle:String? = "Cancel",
                         inputText: String? = nil,
                         inputPlaceholder:String? = nil,
                         inputKeyboardType:UIKeyboardType = UIKeyboardType.default,
                         cancelHandler: ((UIAlertAction) -> Swift.Void)? = nil,
                         completionHandler: @escaping (String) -> Void,
                         actionHandler: ((_ text: String?) -> Void)? = nil) {
        
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        alert.addTextField { (textField:UITextField) in
            textField.text = inputText
            textField.placeholder = inputPlaceholder
            textField.keyboardType = inputKeyboardType
            textField.addTarget(alert, action: #selector(alert.textDidChangeInNameAlert), for: .editingChanged)
        }
        
        let nameAction = UIAlertAction(title: actionTitle, style: .default, handler: { (action:UIAlertAction) in
            guard let textField =  alert.textFields?.first else {
                actionHandler?(nil)
                return
            }
            actionHandler?(textField.text)
            if let text = textField.text {
                completionHandler(text)
            }
        })
        alert.addAction(nameAction)
        alert.textDidChangeInNameAlert()
        
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: { (action:UIAlertAction) in
            self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
}


extension UIAlertController {
    
    @objc func textDidChangeInNameAlert() {
        if let name = textFields?[0].text, let action = actions.first {
            action.isEnabled = name.count > 2
        }
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
