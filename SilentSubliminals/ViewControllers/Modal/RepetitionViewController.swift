//
//  RepetitionViewController.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 08.02.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import PureLayout

class RepetitionViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate  {
    
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var numberPicker: UIPickerView!
    
    var currentPlaylist: Playlist?
    var pickerData: [Int]!
    //var numberOfRepetitions: Int = 1
    var totalTime: TimeInterval = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        numberPicker.delegate = self
        numberPicker.dataSource = self
        
        closeButton.setTitleColor(lightColor, for: .normal)
        durationLabel.textColor = lightColor
        
        numberPicker.setValue(lightColor, forKeyPath: "textColor")

        let pickerSelectionIndicatorTopLine = UIView()
        let pickerSelectionIndicatorBottomLine = UIView()
        
        pickerSelectionIndicatorTopLine.backgroundColor = lightColor.withAlphaComponent(0.8)
        pickerSelectionIndicatorBottomLine.backgroundColor = lightColor.withAlphaComponent(0.8)
        
        numberPicker.addSubview(pickerSelectionIndicatorTopLine)
        numberPicker.addSubview(pickerSelectionIndicatorBottomLine)

        pickerSelectionIndicatorTopLine.autoAlignAxis(.horizontal, toSameAxisOf: numberPicker, withOffset: -15)
        pickerSelectionIndicatorBottomLine.autoAlignAxis(.horizontal, toSameAxisOf: numberPicker, withOffset: 15)
        
        pickerSelectionIndicatorTopLine.autoAlignAxis(.vertical, toSameAxisOf: numberPicker, withMultiplier: 1.03)
        pickerSelectionIndicatorBottomLine.autoAlignAxis(.vertical, toSameAxisOf: numberPicker, withMultiplier: 1.03)
        
        pickerSelectionIndicatorTopLine.autoMatch(.width, to: .width, of: numberPicker, withMultiplier: 0.2)
        pickerSelectionIndicatorBottomLine.autoMatch(.width, to: .width, of: numberPicker, withMultiplier: 0.2)
        
        pickerSelectionIndicatorTopLine.autoSetDimension(.height, toSize: 2)
        pickerSelectionIndicatorBottomLine.autoSetDimension(.height, toSize: 2)
        
        pickerData = Array(stride(from: 1, to: 41, by: 1))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let numberOfRepetitions = UserDefaults.standard.integer(forKey: userDefaults_subliminalNumRepetitions)
        
        numberPicker.selectRow(numberOfRepetitions - 1, inComponent: 0, animated: true)
        calculateTotalTime(numberOfRepetitions: numberOfRepetitions)
    }
    
    @IBAction func closeButtonTouched(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(pickerData[row])"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        let numberOfRepetitions = row + 1
        
        print("number of repetitions: \(numberOfRepetitions)")
        UserDefaults.standard.setValue(numberOfRepetitions, forKey: userDefaults_subliminalNumRepetitions)
        calculateTotalTime(numberOfRepetitions: numberOfRepetitions)
    }
    
    func calculateTotalTime(numberOfRepetitions: Int) {
        
        totalTime = 0
        
        for item in currentPlaylist?.libraryItems ?? [] {
            
            do {
                let soundFile = try Soundfile(item: item as! LibraryItem)
                totalTime += (soundFile.duration ?? 0) * Double(numberOfRepetitions + 1)
            } catch {
                print(error)
            }
        }
        
        durationLabel.text = totalTime.stringFromTimeInterval(showSeconds: true)
        UserDefaults.standard.setValue(totalTime, forKey: userDefaults_subliminalPlaylistTotalTime)
    }
}
