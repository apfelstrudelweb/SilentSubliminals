//
//  MakerAddNewViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 02.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit

protocol SelectAffirmationDelegate : AnyObject {

    func affirmationSelected(affirmation: Affirmation)
}

class MakerAddNewViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddAffirmationTextDelegate {

    @IBOutlet weak var affirmationTitleLabel: UILabel!
    @IBOutlet weak var coverImageButton: UIButton!
    @IBOutlet weak var addAffirmationButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    private var addAffirmationViewController: AddAffirmationViewController?
    weak var delegate : SelectAffirmationDelegate?
    
    var imagePicker: ImagePicker!
    
    var alphaOff: CGFloat = 0.5
    
    var existingAffirmations = ["I am surrounded by peace, harmony and good energy.",
                                "The world deserves nothing less than my authentic happiness. I am happy and I know so I show it. My inner peace helps me get through anything.",
                                "When I recognize all of the blessings in my life I find that I am naturally happy.",
                                "I am healthy, energetic, and optimistic. My body vibrates with energy and health. My body systems function perfectly.",
                                "I pay attention to what my body needs for health and vitality.  I stay up to date about my health issues."]
    

    var usedAffirmation = Affirmation()
    
    var usedText: String? {
        didSet {
            usedAffirmation.text = usedText
            delegate?.affirmationSelected(affirmation: usedAffirmation)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = .lightGray
        coverImageButton.layer.cornerRadius = 10
        coverImageButton.clipsToBounds = true
        addAffirmationButton.layer.cornerRadius = 0.5 * addAffirmationButton.frame.size.width
        addAffirmationButton.clipsToBounds = true
        
        tableView.isEditing = false
        tableView.tableFooterView = UIView()
        editButton.alpha = alphaOff
        
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
        
        if false {
            showInputDialog(title: "Action required",
                            subtitle: "Please enter a name for your affirmation",
                            actionTitle: "Add",
                            cancelTitle: "Cancel",
                            inputPlaceholder: "your affirmation title",
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
        return existingAffirmations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "affirmationCell", for: indexPath as IndexPath) as! AffirmationTableViewCell
        cell.affirmationLabel?.text = existingAffirmations[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        usedText = existingAffirmations[indexPath.row]
    }
    

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.existingAffirmations.remove(at: indexPath.row)
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedObject = self.existingAffirmations[sourceIndexPath.row]
        existingAffirmations.remove(at: sourceIndexPath.row)
        existingAffirmations.insert(movedObject, at: destinationIndexPath.row)
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

        existingAffirmations.insert(text, at: 0)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
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
