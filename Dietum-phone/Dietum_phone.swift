//
//  Dietum_phone.swift
//  Dietum-phone
//
//  Created by Kushal Nawalakha on 11/17/26.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct Dietum_phone: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // Create a report for each DeviceActivityReport.Context that your app supports.
        TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }
        // Add more reports here...
    }
}
