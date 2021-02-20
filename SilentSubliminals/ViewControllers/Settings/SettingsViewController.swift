//
//  SettingsViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 07.02.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var playerBackgroundImageButton: ShadowButton!
    @IBOutlet weak var resetButton: UIButton!
    
    private var audioHelper = AudioHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        getBackgroundImage()
    }
    

    @IBAction func playerBackgroundImageButtonTouched(_ sender: Any) {
        
        self.performSegue(withIdentifier: "cropperSegue", sender: self)
    }
    
    @IBAction func resetButtonTouched(_ sender: Any) {
    
        playerBackgroundImageButton.setImage(UIImage(named: "subliminalPlayerBackground"), for: .normal)
        UserDefaults.standard.set(nil, forKey: userDefaults_playerBackgroundImage)
    }
    
    // MARK: segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        
        if let vc = segue.destination as? ImageCropperViewController {
            vc.delegate = self
            vc.isBackgroundImageForPlayer = true
            vc.restoredImage = playerBackgroundImageButton.image(for: .normal)
        }
    }
    
    func getBackgroundImage() {
        
        if let url = UserDefaults.standard.url(forKey: userDefaults_playerBackgroundImage) {
            
            let image = UIImage(contentsOfFile: url.path)
            playerBackgroundImageButton.setImage(image, for: .normal)
        }
    }

}

extension SettingsViewController: ImageCropperDelegate {

    func didSelectCroppedImage(image: UIImage?) {
        guard let img = image else {
            return
        }
        playerBackgroundImageButton.setImage(img, for: .normal)
        
        if let data = img.pngData() {
            // Create URL
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let url = documents.appendingPathComponent(filename_playerBackgroundImage)

            do {
                // Write to Disk
                try data.write(to: url)

                // Store URL in User Defaults
                UserDefaults.standard.set(url, forKey: userDefaults_playerBackgroundImage)

            } catch {
                print("Unable to Write Data to Disk (\(error))")
            }
        }
    }
}
