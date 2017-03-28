//
//  ViewController.m
//  SDKExample-ObjC
//
//  Created by Magnus Hallin on 23/11/16.
//  Copyright © 2016 Allihoopa. All rights reserved.
//

#import "ViewController.h"

#import <Allihoopa/Allihoopa.h>

@interface ViewController () <AHADropDelegate>

@end

@implementation ViewController

- (IBAction)authenticate {
	[[AHAAllihoopaSDK sharedInstance] authenticate:^(BOOL successful) {
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Auth done"
																	   message:[NSString stringWithFormat:@"Successful: %i", successful]
																preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:@"Alright" style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:alert animated:YES completion:nil];
	}];
}

- (IBAction)drop {
	NSError* error;
	AHADropPieceData* piece = [[AHADropPieceData alloc] initWithDefaultTitle:@"Test title"
														  lengthMicroseconds:10000000
																	   tempo:[[AHAFixedTempo alloc] initWithFixedTempo:123]
																 loopMarkers:[[AHALoopMarkers alloc] initWithStartMicroseconds:12 endMicroseconds:34]
															   timeSignature:[[AHATimeSignature alloc] initWithUpper:8 lower:4]
															 basedOnPieceIDs:@[]
																	tonality:[AHATonality tonalityWithTonalData:AHAGetMajorScale(0) root:0]
																	   error:&error];

	if (error) {
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
																	   message:error.localizedDescription
																preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:@"Bummer" style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:alert animated:YES completion:nil];
	}
	else {
		UIViewController* vc = [[AHAAllihoopaSDK sharedInstance] dropViewControllerForPiece:piece delegate:self];
		[self presentViewController:vc animated:YES completion:nil];
	}
}

- (IBAction)share:(UIView*)sender {
	NSError* error;
	AHADropPieceData* piece = [[AHADropPieceData alloc] initWithDefaultTitle:@"Test title"
														  lengthMicroseconds:10000000
																	   tempo:[[AHAFixedTempo alloc] initWithFixedTempo:123]
																 loopMarkers:[[AHALoopMarkers alloc] initWithStartMicroseconds:12 endMicroseconds:34]
															   timeSignature:[[AHATimeSignature alloc] initWithUpper:8 lower:4]
															 basedOnPieceIDs:@[]
																	tonality:[AHATonality tonalityWithTonalData:AHAGetMajorScale(0) root:0]
																	   error:&error];

	if (error) {
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
																	   message:error.localizedDescription
																preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:@"Bummer" style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:alert animated:YES completion:nil];
	}
	else {
		UIActivity* activity = [[AHAAllihoopaSDK sharedInstance] activityForPiece:piece delegate:self];

		UIActivityViewController* vc = [[UIActivityViewController alloc] initWithActivityItems:@[] applicationActivities:@[ activity ]];
		vc.modalPresentationStyle = UIModalPresentationPopover;

		[self presentViewController:vc animated:YES completion:nil];

		UIPopoverPresentationController* pop = vc.popoverPresentationController;
		pop.sourceView = sender;
		pop.sourceRect = sender.bounds;
	}
}


#pragma mark - AHADropDelegate

- (void)renderMixStemForPiece:(AHADropPieceData *)piece completion:(void (^)(AHAAudioDataBundle * _Nullable, NSError * _Nullable))completion {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError* error;
		NSData* data = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"drop" withExtension:@"wav"] options:0 error:&error];

		if (data) {
			AHAAudioDataBundle* bundle = [[AHAAudioDataBundle alloc] initWithFormat:AHAAudioFormatWave data:data];
			dispatch_async(dispatch_get_main_queue(), ^{
				completion(bundle, nil);
			});
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				completion(nil, error);
			});
		}
	});
}

- (void)renderCoverImageForPiece:(AHADropPieceData *)piece completion:(void (^)(UIImage * _Nullable))completion {
	completion(nil);
}

@end
