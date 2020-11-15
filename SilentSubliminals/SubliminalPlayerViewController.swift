//
//  SubliminalPlayerViewController.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 15.11.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit

class SubliminalPlayerViewController: UIViewController {

    @IBOutlet weak var graphView: UIView!
    @IBOutlet weak var playButton: UIButton!
    
    var isPlaying: Bool = false
    
    struct Button {
        static var playOnImg = UIImage(named: "playButton.png")
        static var playOffImg = UIImage(named: "stopButton.png")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let backbutton = UIButton(type: .custom)
        backbutton.setImage(UIImage(named: "arrow-left.png"), for: [.normal])
        backbutton.addTarget(self, action: #selector(self.close(_:)), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backbutton)
        
        graphView.layer.cornerRadius = cornerRadius
        graphView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    
    @IBAction func playButtonTouchUpInside(_ sender: Any) {
        
        if isPlaying == false {
            startPlaying()
            isPlaying = true
        } else {
            stopPlaying()
            isPlaying = false
        }
    }
    
    func startPlaying() {
        
        playButton.setImage(Button.playOffImg, for: .normal)
    
    }
    
    func stopPlaying() {
        
        self.playButton.setImage(Button.playOnImg, for: .normal)
        
    }
    

    @IBAction func close(_ sender: UIButton) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

}
