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

	@IBAction func drop() {
		let piece = try! AHADropPieceData(defaultTitle: "Test title",
		                                  lengthMicroseconds: 50000,
		                                  tempo: AHAFixedTempo(fixedTempo: 123),
		                                  loopMarkers: AHALoopMarkers(startMicroseconds: 12, endMicroseconds: 34),
		                                  timeSignature: AHATimeSignature(upper: 8, lower: 4),
		                                  basedOnPieceIDs: [])

		let vc = AHAAllihoopaSDK.dropViewController(forPiece: piece, delegate: self)

		self.present(vc, animated: true, completion: nil)
	}

	@IBAction func share(_ sender: UIView?) {
		let piece = try! AHADropPieceData(defaultTitle: "Test title",
		                                  lengthMicroseconds: 50000,
		                                  tempo: AHAFixedTempo(fixedTempo: 123),
		                                  loopMarkers: AHALoopMarkers(startMicroseconds: 12, endMicroseconds: 34),
		                                  timeSignature: AHATimeSignature(upper: 8, lower: 4),
		                                  basedOnPieceIDs: [])

		let vc = UIActivityViewController(
			activityItems: [],
			applicationActivities: [AHAAllihoopaSDK.activity(forPiece: piece, delegate: self)])
		vc.modalPresentationStyle = .popover

		self.present(vc, animated: true, completion: nil)

		let pop = vc.popoverPresentationController!
		pop.sourceView = sender
		pop.sourceRect = sender!.bounds
	}
}

extension ViewController : AHADropDelegate {
	func renderMixStem(forPiece piece: AHADropPieceData, completion: @escaping (AHAAudioDataBundle?, Error?) -> Void) {
		DispatchQueue.global().async {
			do {
				let data = try Data(contentsOf: Bundle.main.url(forResource: "drop", withExtension: "wav")!)
				let bundle = AHAAudioDataBundle(format: .wave, data: data)

				DispatchQueue.main.async {
					completion(bundle, nil)
				}
			}
			catch let error {
				DispatchQueue.main.async {
					completion(nil, error)
				}
			}
		}
	}

	func renderCoverImage(forPiece piece: AHADropPieceData, completion: @escaping (UIImage?) -> Void) {
		completion(nil)
	}
}
