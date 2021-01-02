//
//  MakerAddNewViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 02.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit

protocol SelectAffirmationDelegate : AnyObject {
    
    //    func textSelected(text: String)
    //    func imageSelected(image: UIImage)
    func affirmationSelected(affirmation: Affirmation)
}

class MakerAddNewViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var affirmationTitleLabel: UILabel!
    @IBOutlet weak var coverImageButton: UIButton!
    @IBOutlet weak var addAffirmationButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate : SelectAffirmationDelegate?
    
    var imagePicker: ImagePicker!
    
    var existingAffirmations = ["I am surrounded by peace, harmony and good energy.",
                                "The world deserves nothing less than my authentic happiness. I am happy and I know so I show it. My inner peace helps me get through anything.",
                                "When I recognize all of the blessings in my life I find that I am naturally happy.",
                                "I am healthy, energetic, and optimistic. My body vibrates with energy and health. My body systems function perfectly.",
                                "I pay attention to what my body needs for health and vitality.  I stay up to date about my health issues."]
    
    //var usedAffirmations: Set<String> = []
    //    var usedAffirmation: String? {
    //        didSet {
    //            delegate?.textSelected(text: usedAffirmation ?? "Affirmation")
    //        }
    //    }
    
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
        
        tableView.tableFooterView = UIView()

        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
        
        showInputDialog(title: "Action required",
                        subtitle: "Please enter a name for your affirmation",
                        actionTitle: "Add",
                        cancelTitle: "Cancel",
                        inputPlaceholder: "your affirmation",
                        inputKeyboardType: .default, actionHandler:
                            { (input:String?) in
                                //print("The new number is \(input ?? "")")
                                self.affirmationTitleLabel.text = input?.capitalized
                                self.usedAffirmation.title = input?.capitalized
                            })
        
    }
    
    @IBAction func coverImageButtonTouched(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }
    
    @IBAction func addAffirmationButtonTouched(_ sender: Any) {
        
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
