//
//  AccuracyPickerOption.swift
//  Breadcrumb
//
//  Copyright (C) 2014 Apple Inc. All Rights Reserved.
//  See LICENSE.txt for this sample’s licensing information
//
//  Created by Backlin,Gene on 2/21/18.
//  Copyright © 2018 Backlin,Gene. All rights reserved.
//

import UIKit

class AccuracyPickerOption: NSObject {
    var headline: String?
    var details: String?
    var defaultsKey: String?

    class func withHeadline (description: String, details: String, defaultsKey: String) -> AccuracyPickerOption {
        let option: AccuracyPickerOption = AccuracyPickerOption()
        option.headline = description
        option.details = details
        option.defaultsKey = defaultsKey
        
        return option
    }
}

