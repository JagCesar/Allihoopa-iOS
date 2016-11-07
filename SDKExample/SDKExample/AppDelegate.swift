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
		let applicationIdentifier = Bundle.main.object(forInfoDictionaryKey: "AllihoopaSDKApplicationIdentifier") as! String
		let apiKey = Bundle.main.object(forInfoDictionaryKey: "AllihoopaSDKAPIKey") as! String
		AHAAllihoopaSDK.setup(applicationIdentifier: applicationIdentifier, apiKey: apiKey, delegate: self)
	}

	func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
		if AHAAllihoopaSDK.handleOpen(url) {
			return true
		}

		return false
	}

}

extension AppDelegate: AHAAllihoopaSDKDelegate {
	func openPiece(fromAllihoopa piece: AHAPiece?, error: Error?) {
		print("Open piece \(piece?.title)")
	}
}
