//
//  ViewController.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 10.05.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import CoreAudio
import AVFoundation
import Accelerate
import PureLayout


let alpha: CGFloat = 0.85


class SubliminalMakerViewController: UIViewController, BackButtonDelegate, MakerStateMachineDelegate, AudioHelperDelegate {
 
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var recordButton: RecordButton!
    @IBOutlet weak var playButton: PlayButton!
    
    private var spectrumViewController: SpectrumViewController?
    private var audioHelper = AudioHelper()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioHelper.delegate = self
        MakerStateMachine.shared.delegate = self
        
        let backButton = BackButton(type: .custom)
        backButton.delegate = self
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        
        view.layer.contents = #imageLiteral(resourceName: "subliminalMakerBackground.png").cgImage
        
        playerView.layer.cornerRadius = cornerRadius
        controlView.layer.cornerRadius = playerView.layer.cornerRadius
        controlView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        controlView.alpha = alpha
        containerView.alpha = alpha
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.autoPinEdge(.top, to: .bottom, of: self.view)
        
//        recordButton.alpha = 0.1
//        recordButton.isEnabled = false
        
        print(getDocumentsDirectory())
 
        audioHelper.checkForPermission()
        //audioHelper.initializeAudioEngine(recording: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //stopPlaying()
        audioHelper.stopPlayingSingleAffirmation()
    }
    

    // MARK: user actions
    @IBAction func scriptCreationButtonTouched(_ sender: Any) {
        
        let offset = 0.1 * view.frame.size.height
        containerView.autoPinEdge(.bottom, to: .bottom, of: view, withOffset: -offset)
        
        UIView.animate(withDuration: 0.45) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    @IBAction func playButtonTouched(_ sender: Any) {
        
        if MakerStateMachine.shared.playerState == .playStopped {
            startPlaying()
        } else {
            stopPlaying()
        }
    }
    
    @IBAction func recordButtonTouched(_ sender: Any) {
        
        if MakerStateMachine.shared.recorderState == .recordStopped {
            startRecording()
        } else {
            stopRecording()
        }
    }
    
    func startPlaying() {
       MakerStateMachine.shared.doNextPlayerState()
    }
    
    func stopPlaying() {
        MakerStateMachine.shared.doNextPlayerState()
        audioHelper.stopPlayingSingleAffirmation()
    }
    
    func startRecording() {
       MakerStateMachine.shared.doNextRecorderState()
    }
    
    func stopRecording() {
        MakerStateMachine.shared.doNextRecorderState()
        audioHelper.stopRecording()
    }
    
    // MARK: MakerStateMachineDelegate
    func performPlayerAction() {
        
        self.spectrumViewController?.clearGraph()
        print(MakerStateMachine.shared.playerState)

        if MakerStateMachine.shared.playerState == .play {
            playButton.setState(active: true)
            recordButton.setEnabled(flag: false)
            audioHelper.playSingleAffirmation(instance: .maker)
        } else if MakerStateMachine.shared.playerState == .playStopped {
            playButton.setState(active: false)
            recordButton.setEnabled(flag: true)
        }
    }
    
    func performRecorderAction() {
        
        self.spectrumViewController?.clearGraph()
        print(MakerStateMachine.shared.recorderState)
        
        if MakerStateMachine.shared.recorderState == .record {
            playButton.setEnabled(flag: false)
            recordButton.setState(active: true)
            audioHelper.startRecording()
        } else if MakerStateMachine.shared.playerState == .playStopped {
            playButton.setEnabled(flag: true)
            recordButton.setState(active: false)
        }
    }
    
    // MARK: AudioHelperDelegate
    func processAudioData(buffer: AVAudioPCMBuffer) {
        self.spectrumViewController?.processAudioData(buffer: buffer)
    }

    // MARK: Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let vc = segue.destination as? SpectrumViewController {
            spectrumViewController = vc
        }
    }
    
    
    // MARK: BackButtonDelegate
    func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
}
