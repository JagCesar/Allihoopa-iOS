//
//  AppDelegate.swift
//  SDKExample
//
//  Created by Magnus Hallin on 23/09/16.
//  Copyright © 2016 Allihoopa. All rights reserved.
//

import UIKit
import Allihoopa

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func applicationDidFinishLaunching(_ application: UIApplication) {
		AHAAllihoopaSDK.setup()
	}

	func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
		if AHAAllihoopaSDK.handleOpen(url) {
			return true
		}

		return false
	}

}

