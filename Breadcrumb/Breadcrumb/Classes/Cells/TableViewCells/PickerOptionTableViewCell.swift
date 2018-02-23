//
//  PickerOptionTableViewCell.swift
//  Breadcrumb
//
//  Copyright (C) 2014 Apple Inc. All Rights Reserved.
//  See LICENSE.txt for this sample’s licensing information
//
//  Created by Backlin,Gene on 2/21/18.
//  Copyright © 2018 Backlin,Gene. All rights reserved.
//

import UIKit
import MapKit

let kAccuracyTitleKey = "accuracyTitle"
let kAccuracyValueKey = "accuracyValue"

class PickerOptionTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    
    var defaultsKey: String?

    // MARK: - TableViewCell lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: - Utility methods
    
    func configureWithOptions(options: AccuracyPickerOption) {
        titleLabel.text = options.headline
        detailsLabel.text = options.details
        defaultsKey = options.defaultsKey
        
        // set the picker to match the value of the default CLLocationAccuracy
        let accuracyNum: NSNumber = UserDefaults.standard.value(forKeyPath: defaultsKey!) as! NSNumber
        let accuracy: CLLocationAccuracy = accuracyNum.doubleValue
        
        var row = 0
        switch accuracy {
        case kCLLocationAccuracyBestForNavigation:
            row = 0
        case kCLLocationAccuracyBest:
            row = 1
        case kCLLocationAccuracyNearestTenMeters:
            row = 2
        case kCLLocationAccuracyHundredMeters:
            row = 3
        case kCLLocationAccuracyKilometer:
            row = 4
        case kCLLocationAccuracyThreeKilometers:
            row = 5
        default:
            row = 0
        }
        
        pickerView.selectRow(row, inComponent: 0, animated: false)
    }
    
    func accuracyTitleAndValue(forRow: Int) -> [String : AnyObject]? {
        var title: String = ""
        var accuracyValue: CLLocationAccuracy = -1
        
        switch forRow {
        case 0:
            title = "kCLLocationAccuracyBestForNavigation"
            accuracyValue = kCLLocationAccuracyBestForNavigation
        case 1:
            title = "kCLLocationAccuracyBest"
            accuracyValue = kCLLocationAccuracyBest
        case 2:
            title = "kCLLocationAccuracyNearestTenMeters"
            accuracyValue = kCLLocationAccuracyNearestTenMeters
        case 3:
            title = "kCLLocationAccuracyHundredMeters"
            accuracyValue = kCLLocationAccuracyHundredMeters
        case 4:
            title = "kCLLocationAccuracyKilometer"
            accuracyValue = kCLLocationAccuracyKilometer
        case 5:
            title = "kCLLocationAccuracyThreeKilometers"
            accuracyValue = kCLLocationAccuracyThreeKilometers
        default:
            title = "Unknown Accuracy"
            accuracyValue = -1
        }
        
        return [kAccuracyTitleKey: title as AnyObject, kAccuracyValueKey: accuracyValue as AnyObject]
    }
}

// MARK: - UIPickerViewDataSource

extension PickerOptionTableViewCell: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 6
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 18
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var customLabel: UILabel? = view as? UILabel
        
        if customLabel == nil {
            customLabel = UILabel(frame: .zero)
        }

        // find the accuracy title for the given row
        let resultDict: [String : AnyObject] = accuracyTitleAndValue(forRow: row)!
        let title: String = resultDict[kAccuracyTitleKey] as! String
        
        let attrString: NSMutableAttributedString = NSMutableAttributedString(string: title)
        let font: UIFont = UIFont.systemFont(ofSize: 12.0)
        attrString.addAttribute(NSAttributedStringKey.font, value: font, range: NSMakeRange(0, title.count))
        
        customLabel!.attributedText = attrString
        customLabel!.textAlignment = .center
        
        return customLabel!
    }
}

// MARK: - UIPickerViewDelegate

extension PickerOptionTableViewCell: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // find the accuracy value from the selected row
        let resultDict: [String : AnyObject] = accuracyTitleAndValue(forRow: row)!
        let accuracy: CLLocationAccuracy = resultDict[kAccuracyValueKey]!.doubleValue
        
        // this will cause an NSNotification to occur (NSUserDefaultsDidChangeNotification)
        // ultimately calling BreadcrumbViewController - (void)settingsDidChange:(NSNotification *)notification
        //
        let defaults: UserDefaults = UserDefaults.standard
        defaults.set(accuracy, forKey: LocationTrackingAccuracyPrefsKey)
    }
}

