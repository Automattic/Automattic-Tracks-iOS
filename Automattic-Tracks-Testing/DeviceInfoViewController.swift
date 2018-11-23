//
//  DeviceInfoViewController.swift
//  Automattic-Tracks-Testing
//
//  Created by Jeremy Massel on 2018-11-23.
//  Copyright © 2018 Automattic Inc. All rights reserved.
//

import UIKit

class DeviceInfoViewController: UITableViewController {

    @IBOutlet weak var hasAppleWatchCell: UITableViewCell!

    @IBOutlet weak var hasVoiceOverCell: UITableViewCell!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let info = TracksDeviceInformation()
        self.hasAppleWatchCell.detailTextLabel?.text = String(describing: info.isAppleWatchConnected)
        self.hasVoiceOverCell.detailTextLabel?.text = String(describing: info.isVoiceOverEnabled)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
