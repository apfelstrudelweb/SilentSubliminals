//
//  MakerAddNewViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 02.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import CoreData
import PureLayout
import MobileCoreServices
import EasyTipView

protocol UpdateMakerDelegate : AnyObject {
    func itemDidUpdate()
}


class MakerAddNewViewController: UIViewController, UITableViewDataSource, AddAffirmationTextDelegate {

    @IBOutlet weak var affirmationTitleLabel: UILabel!
    @IBOutlet weak var coverImageButton: ImageButton!
    @IBOutlet weak var addAffirmationButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var importButton: UIButton!
    @IBOutlet weak var editTitleButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    var isEditingMode: Bool = false
    var hasOwnIcon = false
    
    
    private var addAffirmationViewController: AddAffirmationViewController?
    private var scriptViewController: ScriptViewController?
    
    var imagePicker: ImagePicker!
    
    var fetchedResultsControllerLibraryItem: NSFetchedResultsController<LibraryItem>!
    var fetchedResultsControllerSubliminal: NSFetchedResultsController<Subliminal>!
    
    var currentLibraryItem: LibraryItem?

    weak var delegate : UpdateMakerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.tintColor = importButton.tintColor
        coverImageButton.layer.cornerRadius = 10
        coverImageButton.clipsToBounds = true
        coverImageButton.setImage(defaultImageButtonIcon, for: .normal)
        addAffirmationButton.layer.cornerRadius = 0.5 * addAffirmationButton.frame.size.width
        addAffirmationButton.clipsToBounds = true

        tableView.isEditing = false
        
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
        
  
        if !isEditingMode {
            
            showInputDialog(title: "Action required",
                            subtitle: "Please enter a name for your library",
                            actionTitle: "Add",
                            cancelTitle: "Cancel",
                            inputText: "",
                            inputPlaceholder: "Your library title",
                            inputKeyboardType: .default,
                            completionHandler: { (text) in
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

    }
    
    // MARK: user interactions
    @IBAction func coverImageButtonTouched(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }
    
    @IBAction func editButtonTouched(_ sender: Any) {
        
        DispatchQueue.main.async {
            self.tableView.setEditing(!self.tableView.isEditing, animated: true)
            let imageName = self.tableView.isEditing ? "editSymbolOn" : "editSymbolOff"
            self.editButton.setImage(UIImage(named: imageName), for: .normal)
        }
    }
    
    @IBAction func editTitleButtonTouched(_ sender: Any) {
        
        showInputDialog(title: "Change Title",
                        subtitle: "Please enter a new name for your library",
                        actionTitle: "Update",
                        cancelTitle: "Cancel",
                        inputText: self.affirmationTitleLabel.text,
                        inputPlaceholder: "",
                        inputKeyboardType: .default,
                        completionHandler: { (text) in
                            self.updateLibraryItem(title: text)
                            self.affirmationTitleLabel.text = text.capitalized
                        },
                        actionHandler: { (input:String?) in
                            self.affirmationTitleLabel.text = input?.capitalized
                        })
    }
    
    
    @IBAction func importButtonTouched(_ sender: Any) {
        //let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
        let documentPicker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeAudio)], in: .import)
        documentPicker.delegate = self
        self.present(documentPicker, animated: true)
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
        
        if let popoverController = optionMenu.popoverPresentationController {
          popoverController.sourceView = self.view
          popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
          popoverController.permittedArrowDirections = []
        }
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    @IBAction func submitButtonTouched(_ sender: Any) {

        if let title = affirmationTitleLabel.text, let icon = coverImageButton.image(for: .normal) {
            let hasOwnIcon = defaultImageButtonIcon?.pngData() != icon.pngData()
            CoreDataManager.sharedInstance.updateLibraryItem(title: title, icon: icon, hasOwnIcon: hasOwnIcon)
        }

//        if false {
//            
//            guard let viewControllers = self.navigationController?.viewControllers else { return }
//            var controllerStack = viewControllers
//            
//            var index = 0
//            
//            for (i, vc) in controllerStack.enumerated() {
//                
//                if vc.isKind(of: MediathekViewController.self) {
//                    index = i
//                    break
//                }
//            }
//            
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            let vc = storyboard.instantiateViewController(withIdentifier: "SubliminalMaker")
//            controllerStack[index] = vc
//            
//            self.navigationController?.setViewControllers(controllerStack, animated: true);
//        }
        
        delegate?.itemDidUpdate()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonTouched(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let vc = segue.destination as? AddAffirmationViewController {
            addAffirmationViewController = vc
            addAffirmationViewController?.delegate = self
        }
    }
    
    // MARK: CoreData
    func createNewLibraryItem() {
        
        var buttonImage = UIImage(named: "playerPlaceholder")
        
        if coverImageButton.isOverriden {
            buttonImage = coverImageButton.image(for: .normal)
        }
        
        guard let title = self.affirmationTitleLabel.text else { return }
        hasOwnIcon = coverImageButton.isOverriden
        
        if let item = CoreDataManager.sharedInstance.checkIfLibraryItemExists(title: title) {
            let alert = UIAlertController(title: "Warning", message: "An item '\(title)' already exists. Do you want to override the existant one?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { _ in
                //updateLibrary(title: title)
                SelectionHandler().selectLibraryItem(item)
                CoreDataManager.sharedInstance.save()
                self.showExistingLibraryItem()
                self.isEditingMode = true
            }))
            alert.addAction(UIAlertAction(title: "NO", style: .cancel, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true)
        } else {
            currentLibraryItem = CoreDataManager.sharedInstance.createLibraryItem(title: title, icon: buttonImage ?? UIImage(), hasOwnIcon: hasOwnIcon)
        }
    }
    
    func updateLibraryItem(title: String) {
        let fetchRequest = NSFetchRequest<LibraryItem> (entityName: "LibraryItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "creationDate", ascending: false)]
        let predicate = NSPredicate(format: "isActive == true")
        fetchRequest.predicate = predicate
        self.fetchedResultsControllerLibraryItem = NSFetchedResultsController<LibraryItem> (
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)

        do {
            try fetchedResultsControllerLibraryItem.performFetch()
        } catch {
            print("An error occurred")
        }
        
        if let libraryItem = fetchedResultsControllerLibraryItem.fetchedObjects?.first {
            libraryItem.title = title
            CoreDataManager.sharedInstance.save()
        }
    }
    
    func showExistingLibraryItem() {
        
        let fetchRequest = NSFetchRequest<LibraryItem> (entityName: "LibraryItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "creationDate", ascending: false)]
        let predicate = NSPredicate(format: "isActive == true")
        fetchRequest.predicate = predicate
        self.fetchedResultsControllerLibraryItem = NSFetchedResultsController<LibraryItem> (
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)

        do {
            try fetchedResultsControllerLibraryItem.performFetch()
        } catch {
            print("An error occurred")
        }
        
        if let libraryItem = fetchedResultsControllerLibraryItem.fetchedObjects?.first, let imageData = libraryItem.icon {
            currentLibraryItem = libraryItem
            
            let icon = UIImage(data: imageData)
            coverImageButton.setImage(icon, for: .normal)
            
            self.affirmationTitleLabel.text = libraryItem.title
            
            if let title = libraryItem.title {
                let fetchRequest2 = NSFetchRequest<Subliminal> (entityName: "Subliminal")
                fetchRequest2.sortDescriptors = [NSSortDescriptor (key: "order", ascending: true)]
                let predicate2 = NSPredicate(format: "libraryItem.title = %@", title as String)
                fetchRequest2.predicate = predicate2
                self.fetchedResultsControllerSubliminal = NSFetchedResultsController<Subliminal> (
                    fetchRequest: fetchRequest2,
                    managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
                    sectionNameKeyPath: nil,
                    cacheName: nil)
                self.fetchedResultsControllerSubliminal.delegate = self
                
                do {
                    try fetchedResultsControllerSubliminal.performFetch()
                } catch {
                    print("An error occurred")
                }
            }
            self.tableView.reloadData()
        }
        
        tableView.tableFooterView = UIView()
    }
    
    // AddAffirmationTextDelegate
    func addSubliminal(text: String) {
        
        if let item = currentLibraryItem {
            CoreDataManager.sharedInstance.addSubliminal(text: text, libraryItem: item)
            
            if let title = item.title {
                let fetchRequest = NSFetchRequest<Subliminal> (entityName: "Subliminal")
                fetchRequest.sortDescriptors = [NSSortDescriptor (key: "order", ascending: true)]
                let predicate = NSPredicate(format: "libraryItem.title = %@", title as String)
                fetchRequest.predicate = predicate
                self.fetchedResultsControllerSubliminal = NSFetchedResultsController<Subliminal> (
                    fetchRequest: fetchRequest,
                    managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
                    sectionNameKeyPath: nil,
                    cacheName: nil)
                
                do {
                    try fetchedResultsControllerSubliminal.performFetch()
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

extension MakerAddNewViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsControllerSubliminal == nil ? 0 : fetchedResultsControllerSubliminal.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "affirmationCell", for: indexPath as IndexPath) as! AffirmationTableViewCell
        cell.affirmationLabel?.text = fetchedResultsControllerSubliminal.fetchedObjects?[indexPath.row].text
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            
            let item = fetchedResultsControllerSubliminal.object(at: indexPath)
            CoreDataManager.sharedInstance.removeSubliminal(item: item)
            
            do {
                try fetchedResultsControllerSubliminal.performFetch()
                self.tableView.reloadData()
            } catch {
                print("An error occurred")
            }
            
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        guard let movedSubliminal = fetchedResultsControllerSubliminal.fetchedObjects?[sourceIndexPath.row] else { return }
        CoreDataManager.sharedInstance.moveSubliminal(item: movedSubliminal, fromOrder: sourceIndexPath.row, toOrder: destinationIndexPath.row)
        //self.tableView.reloadData()
    }
    
    private func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let text = fetchedResultsControllerSubliminal.fetchedObjects?[indexPath.row].text
        let height = text?.height(withConstrainedWidth: 0.8 * tableView.frame.size.width, font: UIFont.systemFont(ofSize: 20)) ?? 44
        return height + 44
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.tableView.reloadData()
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

extension MakerAddNewViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print(urls)
 
        guard let title = affirmationTitleLabel.text, let url = urls.first else { return }

        spokenAffirmation = String(format: audioTemplate, title)
        spokenAffirmationSilent = String(format: audioSilentTemplate, title)
        
        let ext = url.pathExtension
        let filename = title + "." + ext
        let newFileURL = copyFileToDocumentsFolder(sourceURL: urls.first!, targetFileName: filename)
        convertSoundFileToCaf(url: newFileURL) { (success) in
            
            DispatchQueue.main.async {
                
                var preferences = EasyTipView.Preferences()
                preferences.drawing.font = UIFont.systemFont(ofSize: 14, weight: .medium)
                preferences.drawing.foregroundColor = .white
                preferences.drawing.backgroundColor = success ? self.importButton.tintColor : .red
                preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.top
                preferences.animating.showDuration = 1.5
                preferences.animating.dismissDuration = 1.5
                
                let tipView = EasyTipView(text: success ? "Your import was successful." : "Your import did fail!", preferences: preferences)
                tipView.show(forView: self.importButton, withinSuperview: self.view)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    tipView.dismiss()
                }
            }
        }
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

extension MakerAddNewViewController: EasyTipViewDelegate {
    // MARK EasyTipViewDelegate
    func easyTipViewDidTap(_ tipView: EasyTipView) {}
    func easyTipViewDidDismiss(_ tipView: EasyTipView) { }
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
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
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


extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let label =  UILabel(frame: CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = self
        label.font = font
        label.sizeToFit()
        
        return label.frame.height
    }
}
