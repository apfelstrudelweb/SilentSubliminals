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
import CoreData
import PureLayout


let alpha: CGFloat = 0.85


class SubliminalMakerViewController: UIViewController, BackButtonDelegate, MakerStateMachineDelegate, AudioHelperDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var recordButton: RecordButton!
    @IBOutlet weak var playButton: PlayButton!
    
    private var spectrumViewController: SpectrumViewController?
    private var scriptViewController: ScriptViewController?
    private var makerAddNewViewController: MakerAddNewViewController?
    
    private var audioHelper = AudioHelper()
    
    var usedAffirmation: String?
    var usedImage: UIImage?
    
    var fetchedResultsController: NSFetchedResultsController<LibraryItem>!

    override func viewDidLoad() {
        super.viewDidLoad()
  
        audioHelper.delegate = self
        MakerStateMachine.shared.delegate = self
        MakerStateMachine.shared.playerState = .playStopped
        MakerStateMachine.shared.recorderState = .recordStopped
        
        view.layer.contents = #imageLiteral(resourceName: "subliminalMakerBackground.png").cgImage
        
        //self.navigationController?.navigationBar.tintColor = .white
        
        playerView.layer.cornerRadius = cornerRadius
        controlView.layer.cornerRadius = playerView.layer.cornerRadius
        controlView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        let offset = 0.1 * view.frame.size.height
        containerView.autoPinEdge(.bottom, to: .bottom, of: view, withOffset: -offset)
        self.view.layoutIfNeeded()

        
        print(getDocumentsDirectory())
 
        audioHelper.checkForPermission()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.tintColor = .white
        
        let fetchRequest = NSFetchRequest<LibraryItem> (entityName: "LibraryItem")
        let predicate = NSPredicate(format: "isActive = true")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor (key: "creationDate", ascending: false)]
        self.fetchedResultsController = NSFetchedResultsController<LibraryItem> (
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        self.fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("An error occurred")
        }
        
        scriptViewController?.view.isHidden = fetchedResultsController.fetchedObjects?.count == 0
        
        if let libraryItem = fetchedResultsController.fetchedObjects?.first, let fileName = libraryItem.soundFileName {
            spokenAffirmation = "\(fileName).caf"
            spokenAffirmationSilent = "\(fileName)Silent.caf"
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlaying()
        //audioHelper.stopPlayingSingleAffirmation()
    }
    

    // MARK: user actions
    @IBAction func scriptCreationButtonTouched(_ sender: Any) {
        
        self.performSegue(withIdentifier: "showMakerAddNewSegue", sender: sender)
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
        //MakerStateMachine.shared.doNextPlayerState()
        audioHelper.reset()
        //audioHelper.stopPlayingSingleAffirmation()
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
        DispatchQueue.main.async {
            self.spectrumViewController?.processAudioData(buffer: buffer)
        }
    }

    // MARK: Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let vc = segue.destination as? SpectrumViewController {
            spectrumViewController = vc
        }
        if let vc = segue.destination as? ScriptViewController {
            scriptViewController = vc
        }
        if let vc = segue.destination as? MakerAddNewViewController {
            makerAddNewViewController = vc
            makerAddNewViewController?.isEditingMode = false
        }
    }
    
    
    // MARK: BackButtonDelegate
    func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

}
