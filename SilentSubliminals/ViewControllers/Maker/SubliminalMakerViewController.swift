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


let editItemSegue = "editItemSegue"

let documentInteractionController = UIDocumentInteractionController()

class SubliminalMakerViewController: UIViewController, BackButtonDelegate, MakerStateMachineDelegate, AudioHelperDelegate, UpdateMakerDelegate, ScriptViewDelegate, NSFetchedResultsControllerDelegate {

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
    
    var calledFromMediathek: Bool = false
    
    var fetchedResultsController: NSFetchedResultsController<LibraryItem>!
    
    let documentInteractionController = UIDocumentInteractionController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        documentInteractionController.delegate = self
  
        audioHelper.delegate = self
        MakerStateMachine.shared.delegate = self
        MakerStateMachine.shared.playerState = .playStopped
        MakerStateMachine.shared.recorderState = .recordStopped

        playerView.layer.cornerRadius = cornerRadius
        controlView.layer.cornerRadius = playerView.layer.cornerRadius
        controlView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        print(getDocumentsDirectory())
        audioHelper.checkForPermission()
        
        if calledFromMediathek {
            performSegue(withIdentifier: "addItemSegue", sender: self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.tintColor = .white
        
        updateGUI()
    }
    
    func updateGUI() {
        
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
            spokenAffirmation = String(format: audioTemplate, fileName)
            spokenAffirmationSilent = String(format: audioSilentTemplate, fileName)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlaying()
        //audioHelper.stopPlayingSingleAffirmation()
    }
    
    // MARK: Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let vc = segue.destination as? SpectrumViewController {
            spectrumViewController = vc
        }
        if let vc = segue.destination as? ScriptViewController {
            scriptViewController = vc
            scriptViewController?.delegate = self
        }
        if let vc = segue.destination as? MakerAddNewViewController {
            makerAddNewViewController = vc
            makerAddNewViewController?.isEditingMode = segue.identifier == editItemSegue
            makerAddNewViewController?.delegate = self
        }
    }

    // MARK: user actions
    
    // MARK: ScriptViewDelegate
    func editButtonTouched() {
        self.performSegue(withIdentifier: editItemSegue, sender: self)
    }
    
    // MARK: BackButtonDelegate
    func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: UpdateMakerDelegate
    func itemDidUpdate() {
        scriptViewController?.updateGUI()
        updateGUI()
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
    
    // MARK: Audio
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

        let url = getFileFromSandbox(filename: spokenAffirmation) 
               URLSession.shared.dataTask(with: url) { data, response, error in
                   guard let data = data, error == nil else { return }
                   let tmpURL = FileManager.default.temporaryDirectory
                       .appendingPathComponent(response?.suggestedFilename ?? "bell.aiff")
                   do {
                       try data.write(to: tmpURL)
                       DispatchQueue.main.async {
                           self.share(url: tmpURL)
                       }
                   } catch {
                       print(error)
                   }

               }.resume()
    }
    
    func share(url: URL) {
        documentInteractionController.url = url
        documentInteractionController.uti = url.typeIdentifier ?? "public.data, public.content"
        documentInteractionController.name = url.localizedName ?? url.lastPathComponent
        documentInteractionController.presentOptionsMenu(from: view.frame, in: view, animated: true)
        //documentInteractionController.presentPreview(animated: true)
    }
    

    // MARK: MakerStateMachineDelegate
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

    // MARK: AudioHelperDelegate
    func processAudioData(buffer: AVAudioPCMBuffer) {
        DispatchQueue.main.async {
            self.spectrumViewController?.processAudioData(buffer: buffer)
        }
    }
}


extension SubliminalMakerViewController: UIDocumentInteractionControllerDelegate {
    /// If presenting atop a navigation stack, provide the navigation controller in order to animate in a manner consistent with the rest of the platform
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        guard let navVC = self.navigationController else {
            return self
        }
        return navVC
    }
}
