//
//  ViewController.swift
//  SDKExample
//
//  Created by Magnus Hallin on 23/09/16.
//  Copyright © 2016 Allihoopa. All rights reserved.
//

import UIKit
import Allihoopa

class ViewController: UIViewController {

	@IBAction func authenticate() {
		AHAAllihoopaSDK.authenticate { (successful) in
			let alert = UIAlertController(title: "Auth done", message: "Successful: \(successful)", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Alright", style: .default, handler: nil))

			self.present(alert, animated: true, completion: nil)
		}
	}

}
