//
//  SettingsViewController.swift
//  Breadcrumb
//
//  Copyright (C) 2014 Apple Inc. All Rights Reserved.
//  See LICENSE.txt for this sample’s licensing information
//
//  Created by Backlin,Gene on 2/21/18.
//  Copyright © 2018 Backlin,Gene. All rights reserved.
//

import UIKit

let TrackLocationInBackgroundPrefsKey = "TrackLocationInBackgroundPrefsKey" // value is a BOOL
let LocationTrackingAccuracyPrefsKey = "LocationTrackingAccuracyPrefsKey"   // value is a CLLocationAccuracy (double)
let PlaySoundOnLocationUpdatePrefsKey = "PlaySoundOnLocationUpdatePrefsKey" // value is a BOOL

let SwitchOptionCellID = "SwitchOptionTableViewCell"
let PickerOptionCellID = "PickerOptionTableViewCell"

class SettingsViewController: UITableViewController {
    var settings: [AnyObject]?
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        settings = [AnyObject]()
        settings!.append(SwitchOption.withHeadline(description: "Background Updates:", details: "Label for switch that enables and disables background updates", defaultsKey: TrackLocationInBackgroundPrefsKey))
        settings!.append(AccuracyPickerOption.withHeadline(description: "Accuracy:", details: "Set level of accuracy when tracking your location.", defaultsKey: LocationTrackingAccuracyPrefsKey))
        settings!.append(SwitchOption.withHeadline(description: "Audio Feedback:", details: "Play a sound when a new location update is received.", defaultsKey: PlaySoundOnLocationUpdatePrefsKey))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

// MARK: - UITableViewController

extension SettingsViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings!.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var cellHeight: CGFloat = 0.0
        
        let option = settings![indexPath.row]
        
        if option is AccuracyPickerOption {
            cellHeight = 213.00;    // cell height for the accuracy cell (with UIPickerView)
        } else if option is SwitchOption {
            cellHeight = 105.0;     // cell height for the switch cell
        }
        
        return cellHeight
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let option = settings![indexPath.row]
        var cell: UITableViewCell?
        
        if option is AccuracyPickerOption {
            let pickerCell: PickerOptionTableViewCell = tableView.dequeueReusableCell(withIdentifier: PickerOptionCellID) as! PickerOptionTableViewCell
            pickerCell.configureWithOptions(options: option as! AccuracyPickerOption)
            cell = pickerCell
        } else if option is SwitchOption {
            let switchCell: SwitchOptionTableViewCell = tableView.dequeueReusableCell(withIdentifier: SwitchOptionCellID) as! SwitchOptionTableViewCell
            switchCell.configureWithOptions(options: option as! SwitchOption)
            cell = switchCell
        }
        
        return cell!
    }
}
