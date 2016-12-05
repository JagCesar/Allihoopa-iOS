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
		let facebookAppID = Bundle.main.object(forInfoDictionaryKey: "AllihoopaSDKFacebookAppID") as! String?

		var config: [AHAConfigKey: Any] = [
			.applicationIdentifier: applicationIdentifier,
			.apiKey: apiKey,
			.sdkDelegate: self,
		]

		if let facebookAppID = facebookAppID {
			config[.facebookAppID] = facebookAppID
		}

		AHAAllihoopaSDK.setup(config)
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
		if let piece = piece {
			print("Open piece \(piece.title)")

			piece.downloadMixStem(format: .oggVorbis, completion: { (data, error) in
				print("Got mix stem data \(data)")
			})

			piece.downloadAudioPreview(format: .oggVorbis, completion: { (data, error) in
				print("Got audio preview data \(data)")
			})

			piece.downloadCoverImage(completion: { (image, error) in
				print("Got cover image \(image)")
			})
		} else {
			print("Error: \(error!)")
		}
	}
}
