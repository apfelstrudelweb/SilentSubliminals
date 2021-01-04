//
//  MakerAddNewViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 02.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import CoreData


class MakerAddNewViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddAffirmationTextDelegate {

    @IBOutlet weak var affirmationTitleLabel: UILabel!
    @IBOutlet weak var coverImageButton: UIButton!
    @IBOutlet weak var addAffirmationButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    private var addAffirmationViewController: AddAffirmationViewController?
    
    var imagePicker: ImagePicker!
    
    var alphaOff: CGFloat = 0.5
    
    var usedAffirmation = SimpleAffirmation()
    
    var usedText: String? {
        didSet {
            usedAffirmation.text = usedText
        }
    }
    
    var fetchedResultsController: NSFetchedResultsController<LibraryItem>!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fetchRequest = NSFetchRequest<LibraryItem> (entityName: "LibraryItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "creationDate", ascending: false)]
        self.fetchedResultsController = NSFetchedResultsController<LibraryItem> (
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        self.fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            //existingAffirmations = fetchedResultsController.fetchedObjects!
        } catch {
            print("An error occurred")
        }
        
        self.navigationController?.navigationBar.tintColor = .lightGray
        coverImageButton.layer.cornerRadius = 10
        coverImageButton.clipsToBounds = true
        addAffirmationButton.layer.cornerRadius = 0.5 * addAffirmationButton.frame.size.width
        addAffirmationButton.clipsToBounds = true
        
        tableView.isEditing = false
        tableView.tableFooterView = UIView()
        editButton.alpha = alphaOff
        
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
        
        if true {
            showInputDialog(title: "Action required",
                            subtitle: "Please enter a name for your library",
                            actionTitle: "Add",
                            cancelTitle: "Cancel",
                            inputPlaceholder: "your library title",
                            inputKeyboardType: .default, actionHandler:
                                { (input:String?) in
                                    //print("The new number is \(input ?? "")")
                                    self.affirmationTitleLabel.text = input?.capitalized
                                    self.usedAffirmation.title = input?.capitalized
                                })
        }
        
    }
    
    @IBAction func coverImageButtonTouched(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }
    
    @IBAction func editButtonTouched(_ sender: Any) {
        tableView.isEditing = !tableView.isEditing
        editButton.alpha = tableView.isEditing ? 1 : alphaOff
    }
    
    @IBAction func submitButtonTouched(_ sender: Any) {
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
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "affirmationCell", for: indexPath as IndexPath) as! AffirmationTableViewCell
        cell.affirmationLabel?.text = fetchedResultsController.fetchedObjects?[indexPath.row].title
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let affirmations = fetchedResultsController.fetchedObjects {
            for affirmation in affirmations {
                affirmation.isActive = false
            }
        }

        let libraryItem = fetchedResultsController.object(at: indexPath)
        libraryItem.isActive = true
        //libraryItem.soundFileName = affirmation.title
        CoreDataManager.sharedInstance.save()
    }
    

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {

            let item = fetchedResultsController.object(at: indexPath)
            CoreDataManager.sharedInstance.removeLibraryItem(item: item)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedObject = fetchedResultsController.fetchedObjects?[sourceIndexPath.row]
//        existingAffirmations.remove(at: sourceIndexPath.row)
//        existingAffirmations.insert(movedObject, at: destinationIndexPath.row)
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
    func addAffirmation(text: String) {

//        CoreDataManager.sharedInstance.insertAffirmation(id: 4711, title: usedAffirmation.title ?? "My affirmation", text: text, icon: usedAffirmation.image ?? UIImage())
//        CoreDataManager.sharedInstance.save()
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
        case .move:
            self.tableView.deleteRows(at: [indexPath! as IndexPath], with: .fade)
            self.tableView.insertRows(at: [indexPath! as IndexPath], with: .fade)
        default:
            print("...")
        }
    }


    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }

}

extension MakerAddNewViewController: ImagePickerDelegate {
    
    func didSelect(image: UIImage?) {
        self.coverImageButton.setImage(image, for: .normal)
        guard let img = image else {
            return
        }
        usedAffirmation.image = img
    }
}

extension UIViewController {
    func showInputDialog(title:String? = nil,
                         subtitle:String? = nil,
                         actionTitle:String? = "Add",
                         cancelTitle:String? = "Cancel",
                         inputPlaceholder:String? = nil,
                         inputKeyboardType:UIKeyboardType = UIKeyboardType.default,
                         cancelHandler: ((UIAlertAction) -> Swift.Void)? = nil,
                         actionHandler: ((_ text: String?) -> Void)? = nil) {
        
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        alert.addTextField { (textField:UITextField) in
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
        })
        alert.addAction(nameAction)
        nameAction.isEnabled = false
        
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
