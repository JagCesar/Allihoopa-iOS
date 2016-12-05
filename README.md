Allihoopa SDK for iOS
=====================

[![Travis](https://travis-ci.org/allihoopa/Allihoopa-iOS.svg?branch=master)](https://travis-ci.org/allihoopa/Allihoopa-iOS)
[![CocoaPods](https://cocoapod-badges.herokuapp.com/v/Allihoopa/badge.svg)](https://cocoapods.org/pods/Allihoopa)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg)](https://github.com/Carthage/Carthage)

----

> Objective-C/Swift SDK to interface with [Allihoopa].

# Installation

There are multiple ways of installing the Allihoopa SDK depending on how your
setup looks like.

If you use [CocoaPods], you can simply add this SDK to your `Podfile`:

```ruby
target 'TargetName' do
  pod 'Allihoopa', '~> 0.4.1'
end
```

And then running the following command to download the dependency:

```bash
pod install
```

If you use [Carthage], you instead add this SDK to your `Cartfile`:

```
github "Allihoopa/Allihoopa-iOS" ~> 0.4.1
```

After this, you run `carthage` to build the framework, and then drag the
resulting `Allihoopa.framework` from the `Carthage/Build` folder into your
project.

Alternatively, you can simply download the latest built framework from the
[Releases tab].

## Configuration

You need to add a URL scheme to your app's `Info.plist`: `ah-{APP_IDENTIFIER}`,
e.g. `ah-figure` if your application identifier is `figure`. You will receive
your application identifier and API key when your register your application with
Allihoopa. If you want to get on board, please send an email to
[developer@allihoopa.com](mailto:developer@allihoopa.com).

For the drop flow to work, you will _also_ need to add the following keys to
your `Info.plist`:

```plist
<key>NSCameraUsageDescription</key>
<string>$(PRODUCT_NAME) wants to access your camera</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>$(PRODUCT_NAME) wants to access your photo library</string>
```


## Development setup

Look in the [SDKExample] folder for instructions how to work on this SDK.


# API documentation

## Setting up the SDK

You need a class, e.g. your app delegate, to implement the
`AHAAllihoopaSDKDelegate` to support the "open in" feature. See below how to
implement this feature.

```swift
import Allihoopa

// In your UIApplicationDelegate implementation
func applicationDidFinishLaunching(_ application: UIApplication) {
    AHAAllihoopaSDK.setup([
        .applicationIdentifier: "your-application-identifier",
        .apiKey: "your-api-key",
        .delegate: self,
    ])
}

func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    if AHAAllihoopaSDK.handleOpen(url) {
        return true
    }

    // Call other SDKs' URL handling methods

    return false
}
```

```objective-c
#import <Allihoopa/Allihoopa.h>

// In your UIApplicationDelegate implementation
- (void)applicationDidFinishLaunching:(UIApplication*)application {
    [AHAAllihoopaSDK setupWithConfiguration:@{
        AHAConfigKeyApplicationIdentifier: @"your-application-identifier",
        AHAConfigKeyAPIKey: @"your-api-key",
        AHAConfigKeySDKDelegate: self,
    }];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if ([AHAAllihoopaSDK handleOpenURL:url]) {
        return YES;
    }

    // Call other SDKs' URL handling methods

    return NO;
}
```

`setupWithConfiguration:` must be called *before* any other API calls can be
made. It will throw an exception if the SDK is improperly setup: if the
credentials are missing or if you've not set up the URL scheme properly. For
more information, see the "Steting up the SDK" heading above.

The configuration dictionary supports the following keys - names in Objective-C
vs. Swift:

* `AHAConfigKeyApplicationIdentifier`/`.applicationIdentifier`: required string
  containing the application identifier provided by Allihoopa.
* `AHAConfigKeyAPIKey`/`.apiKey`: required string containing the app's API key.
* `AHAConfigKeySDKDelegate`/`.sdkDelegate`: optional instance used to notify
  the application when a user tries to import a piece into this app. If provided,
  the instance must conform to the `AHAAllihoopaSDKDelegate` protocol.
* `AHAConfigKeyFacebookAppID`/`.facebookAppID`: optional string containing the
  Facebook App ID of the application. This will enable secondary social sharing
  through the Accounts and Social frameworks built into iOS.

`handleOpenURL:` must be called inside the URL handler of your application. It
will only return true if it successfully handled the URL, making it possible to
chain this call with other URL handlers.

## Dropping pieces

```swift
let piece = try! AHADropPieceData(
    defaultTitle: "Default title", // The default title of the piece
    lengthMicroseconds: 40000000, // Length of the piece, in microseconds
    tempo: nil,
    loopMarkers: nil,
    timeSignature: nil,
    basedOn: [])

let vc = AHAAllihoopaSDK.dropViewController(forPiece: piece, delegate: self)

self.present(vc, animated: true, completion: nil)
```

```swift
extension ViewController : AHADropDelegate {
    // The drop view controller will ask your application for audio data.
    // You should perform work in the background and call the completion
    // handler on the main queue. If you already have the data available,
    // you can just call the completion handler directly.
    //
    // This method *must* call completion with a data bundle for the drop to
    // succeed. If it doesn't, an error screen will be shown.
    func renderMixStem(forPiece piece: AHADropPieceData, completion: @escaping (AHAAudioDataBundle?, Error?) -> Void) {
        DispatchQueue.global().async {
            // Render Wave data into an NSData object
            let bundle = AHAAudioDataBundle(format: .wave, data: data)
            DispatchQueue.main.async {
                completion(bundle, nil)
            }
        }
    }
}
```

---

```objective-c
NSError* error;
AHADropPieceData* piece = [[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
                                                      lengthMicroseconds:40000000
                                                                   tempo:nil
                                                             loopMarkers:nil
                                                           timeSignature:nil
                                                         basedOnPieceIDs:@[]
                                                                   error:&error];
if (piece) {
    UIViewController* vc = [AHAAllihoopaSDK dropViewControllerForPiece:piece delegate:self];
    [self presentViewController:vc animated:YES completion:nil];
}
```

```objective-c
@implementation ViewController

- (void)renderMixStemForPiece:(AHADropPieceData *)piece
                   completion:(void (^)(AHAAudioDataBundle * _Nullable, NSError * _Nullable))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Render wave data into an NSData object
        AHAAudioDataBundle* bundle = [[AHAAudioDataBundle alloc] initWithFormat:AHAAudioFormatWave data:data];

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(bundle, nil);
        });
    });
}

@end
```


`dropViewController` creates a view controller responsible for dropping the
piece you supplied with the help of the delegate object. If the user is not
logged in, a log in dialog is presented first. When the user is finished, or if
they cancel, the view controller will dismiss itself and inform the delegate.

A piece can contain different kinds of metadata. The above example shows off the
minimum amount of data we require: a default title, the length of the piece
audio data, and a delegate method that renders the audio into a known format.

The `AHADropPieceData` performs basic validation on the inputs: it will return a
`NSError` containing information on what went wrong. Errors can include things
like the loop markers being inverted or the length outside of reasonable limits.
These are *usually* programmer errors - not runtime errors that can be handled
in a meaningful way.

If your application knows about it, it can supply a lot more metadata to
`AHADropPieceData` more information, as well as implementing more methods on
`AHADropDelegate` than shown above. Here's a complete example showing all data
you can set:

```swift
let piece = try! AHADropPieceData(
    defaultTitle: "Default title",
    lengthMicroseconds: 100000000,
    // The fixed tempo in BPM. Allowed range: 1 - 999.999 BPM
    tempo: AHAFixedTempo(fixedTempo: 128), 

    // If the piece is a loop, you can provide the loop markers.
    loopMarkers: AHALoopMarkers(startMicroseconds: 0, endMicroseconds: 500000),

    // If the time signature is available and fixed, you can provide a time
    // signature object.
    //
    // The upper numeral can range from 1 to 16, incnlusive. The lower numeral
    // must be one of 2, 4, 8, and 16.
    timeSignature: AHATimeSignature(upper: 8, lower: 4),

    // If the piece is based on other pieces, provide a list of the IDs of those
    // pieces here.
    basedOn: [])
```

```swift
extension ViewController : AHADropDelegate {
    // The "mix stem" is the audio data that should be used to place the piece
    // on a timeline. Call the completion handler with a data bundle instance
    // on the main queue when data is available.
    //
    // The mix stem is mandatory.
    func renderMixStem(forPiece piece: AHADropPieceData, completion: @escaping (AHAAudioDataBundle?, Error?) -> Void) {
    }

    // You can supply a default cover image that the user can upload or change.
    // Call the completion handler with an image of size 640x640 px, or nil.
    func renderCoverImage(forPiece piece: AHADropPieceData, completion: @escaping (UIImage?) -> Void) {
        completion(nil)
    }

    // If the audio to be placed on the timeline is different from what users
    // should listen to, use this delegate method to provide a "preview"
    // audio bundle.
    //
    // For example, if you're providing a short loop you can supply only the
    // loop data in a lossless format as the mix stem, and then a longer track
    // containing a few loops with fade in/out in a lossy format in the
    // preview audio.
    //
    // The preview audio is what's going to be played on the website.
    //
    // If no preview audio is provided, the mix stem will be used instead. This
    // replacement is done server-side, the mix stem data will only be uploaded
    // once from the client.
    func renderPreviewAudio(forPiece piece: AHADropPieceData, completion: @escaping (AHAAudioDataBundle?, Error?) -> Void) {
    }

    // You can implement this method to get notified when the user either
    // cancels or completes a drop.
    func dropViewController(forPieceWillClose piece: AHADropPieceData, afterSuccessfulDrop successfulDrop: Bool) {
    }
}
```

### Dropping from `UIActivityViewController`

```swift
@IBAction func share(_ sender: UIView?) {
    let piece = try! AHADropPieceData(
        defaultTitle: "Default title",
        lengthMicroseconds: 100000000,
        tempo: nil,
        loopMarkers: nil,
        timeSignature: nil,
        basedOn: [])

    let vc = UIActivityViewController(
        activityItems: [],
        applicationActivities: [AHAAllihoopaSDK.activity(forPiece: piece, delegate: self)])
    vc.modalPresentationStyle = .popover

    self.present(vc, animated: true, completion: nil)

    let pop = vc.popoverPresentationController!
    pop.sourceView = sender
    pop.sourceRect = sender!.bounds
}
```

If you are already using `UIActivityViewController` to present a share popover
to your users, you can use `activityForPiece:delegate:` to create a
`UIActivity`. It has the same interface as for creating the drop view controller
above, and uses the same delegate protocol.

## Importing pieces

When a user picks "Open in [your app]" on the website, the SDK will pick up the
request, fetch piece metadata, and call the `openPieceFromAllihoopa:error:` with
the piece the user wanted to open. The `AHAPiece` instance has methods for
downloading the audio data in the specified format, which you can use to import
the audio into the current document, or save it for later. `AHAPiece` also
contain metadata, similar to `AHADropPiece`.

```swift
func openPiece(fromAllihoopa piece: AHAPiece?, error: Error?) {
    if let piece = piece {
        // The user wanted to open a piece

        // Download the mix stem audio in Ogg format. You can also use .wave
        piece.downloadMixStem(format: .oggVorbis, completion: { (data, error) in
            if let data = data {
                // Data downloaded successfully
            }
        })
    }
    else {
        // Handle the error
        //
        // This should not *usually* happen, but if the piece was removed after
        // opening, or if there were some connection issues we can end up here
    }
}
```

```objective-c
- (void)openPieceFromAllihoopa:(AHAPiece*)piece error:(NSError*)error {
    if (piece != nil) {
        // The user wanted to open a piece
        [piece downloadMixStemWithFormat:AHAAudioFormatOggVorbis completion:^(NSData* data, NSError* error) {
            if (data != nil) {
                // Data downloaded successfully
            }
        }];
    }
    else {
        // Handle the error
    }
}
```

## Authenticating users

```swift
AHAAllihoopaSDK.authenticate { (successful) in
    if successful {
        // The user is now logged in
    }
    else {
        // The user canceled log in/sign up
    }
}
```

```objective-c
[AHAAllihoopaSDK authenticate:^(BOOL successful) {
    if (successful) {
        // The user is now logged in
    }
    else {
        // The user canceled log in/sign up
    }
}];
```

This opens a login/signup dialog where the user can authenticate with Allihoopa.
You should not *really* have to call this method yourself: the SDK will
automatically show a login screen before dropping, for example.

It uses `SFSafariViewController`, which lets the user avoid entering
username/password into the app if they are already signed into allihoopa.com in
their browser.

NOTE: If you call this method, the view controller appears and you manage to
login, but the callback isn't invoked, please check the configuration and
application delegate: *both* the URL scheme *and* the `handleOpenURL` call must
be in place for this to work.


[Allihoopa]: https://allihoopa.com
[CocoaPods]: https://cocoapods.org
[Carthage]: https://github.com/carthage/carthage
[Releases tab]: https://github.com/allihoopa/Allihoopa-iOS/releases
[SDKExample]: SDKExample
