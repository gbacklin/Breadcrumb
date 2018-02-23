//
//  SwitchOptionTableViewCell.swift
//  Breadcrumb
//
//  Copyright (C) 2014 Apple Inc. All Rights Reserved.
//  See LICENSE.txt for this sample’s licensing information
//
//  Created by Backlin,Gene on 2/21/18.
//  Copyright © 2018 Backlin,Gene. All rights reserved.
//

import UIKit

class SwitchOptionTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var switchControl: UISwitch!
    
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
    
    // MARK: - @IBAction methods
    
    @IBAction func toggleSwitch(_ sender: UISwitch) {
        updatePreferencesFromView(sender)
    }
    
    // MARK: - Utility methods
    
    func configureWithOptions(options: SwitchOption) {
        titleLabel.text = options.headline
        detailsLabel.text = options.details
        defaultsKey = options.defaultsKey
        switchControl.isOn = UserDefaults.standard.bool(forKey: defaultsKey!)
    }
    
    func updatePreferencesFromView(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: defaultsKey!)
   }
    
}
