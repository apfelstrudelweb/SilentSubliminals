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
    
    var pickerData: [Int]!
    
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
        
        let minNum = 2
        let maxNum = 20
        pickerData = Array(stride(from: minNum, to: maxNum + 1, by: 1))
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
    
    //    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
    //
    //        let string = "\(pickerData[row])"
    //        return NSAttributedString(string: string, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    //    }
    
}
