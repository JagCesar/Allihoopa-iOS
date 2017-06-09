Allihoopa SDK for iOS
=====================

[![Travis](https://travis-ci.org/allihoopa/Allihoopa-iOS.svg?branch=master)](https://travis-ci.org/allihoopa/Allihoopa-iOS)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg)](https://github.com/Carthage/Carthage)

----

> Objective-C/Swift SDK to interface with [Allihoopa].

# Installation

There are different ways of installing the Allihoopa SDK depending on how your
setup looks like.

If you use [Carthage], you instead add this SDK to your `Cartfile`:

```
github "Allihoopa/Allihoopa-iOS" ~> 1.3.2
```

After this, you run `carthage update` to build the framework, and then drag the
resulting `Allihoopa.framework` _and_ `AllihoopaCore.framework` from the
`Carthage/Build` folder into the "Embedded binaries" of your target.


### Manual build

If you want, you can include the `Allihoopa-iOS` project as a sub-project
to your application and build the the framework as a dependency. In this case,
you will need to include
[AllihoopaCore-ObjC](https://github.com/allihoopa/AllihoopaCore-ObjC) too as a
dependency since this project share a lot of code and functionality with the
iOS SDK.

If you use one of the methods described above, this dependency is managed
automatically for you.

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

iOS 10 started enforcing these keys - the app will crash when the user taps the
edit cover image button unless these are specified. Read more about this in the
[Technical Q&A QA1937](Technical Q&A QA1937: Resolving the Privacy-Sensitive
Data App Rejection).

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
    AHAAllihoopaSDK.shared().setup([
        .applicationIdentifier: "your-application-identifier",
        .apiKey: "your-api-key",
        .delegate: self,
    ])
}

func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    if AHAAllihoopaSDK.shared().handleOpen(url) {
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
    [[AHAAllihoopaSDK sharedInstance] setupWithConfiguration:@{
        AHAConfigKeyApplicationIdentifier: @"your-application-identifier",
        AHAConfigKeyAPIKey: @"your-api-key",
        AHAConfigKeySDKDelegate: self,
    }];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if ([[AHAAllihoopaSDK sharedInstance] handleOpenURL:url]) {
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

let vc = AHAAllihoopaSDK.shared().dropViewController(forPiece: piece, delegate: self)

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
    UIViewController* vc = [[AHAAllihoopaSDK sharedInstance] dropViewControllerForPiece:piece delegate:self];
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
    basedOn: [],

    // If the piece has a known tonality, provide the scale and root here.
    // Other values are AHATonality.unknown() (default if omitted), and
    // AHATonality.atonal() for pieces that contain audio that doesn't have a
    // tonality, e.g. drum loops.
    tonality: AHATonality(tonalScale: AHAGetMajorScale(4), root: 4)
)
```

```swift
extension ViewController : AHADropDelegate {
    // The "mix stem" is the audio data that should be used to place the piece
    // on a timeline. Call the completion handler with a data bundle instance
    // on the main queue when data is available.
    //
    // The mix stem is mandatory.
    func renderMixStem(forPiece piece: AHADropPieceData, completion: @escaping (AHAAudioDataBundle?, Error?) -> Void) {
		...
    }

    // You can supply a default cover image that the user can upload or change.
    // Call the completion handler with an image of size 640x640 px, or nil.
    func renderCoverImage(forPiece piece: AHADropPieceData, completion: @escaping (UIImage?) -> Void) {
		...
    }

    // You can supply a file as an attachment to the piece. The file can be of
    // any format. This file can be read back by clients when fetching a piece.
    // Attachment max size is 30mb.
    // Call the completion handler with a data bundle instance on the main queue
    // when data is available.
    renderAttachment(forPiece piece: AHADropPieceData, completion: @escaping (AHAAttachmentBundle?, Error?) -> Void) {
        ...
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
        applicationActivities: [AHAAllihoopaSDK.shared().activity(forPiece: piece, delegate: self)])
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

### Some notes on tonality

#### Representation

In Allihoopa, a piece's tonality can be in one of three different states:

* _Unknown_, used when the application can't determine the tonal content of the
  piece when dropping.
* _Atonal_, used when the application knows that the piece does not contain
  tonal content. This is true in e.g. drum loops.
* _Tonal_, used when the application knows about the tonal content of the piece.

For pieces with known tonal content, tonality is represented by two values: a
_scale_ and a _root_. The scale consists of twelve boolean values each
representing whether that pitch class is a member of the tonality. The root
indicates on which index in the array the tonality begins.

This can be a bit confusing, but a simple example might help. C major is
represented by "all white keys" in the scale:

```
        C  C#   D  D#   E   F  F#   G  G#   A  A#   B
Scale: [1,  0,  1,  0,  1,  1,  0,  1,  0,  1,  0,  1]
Root:   0
```

If we instead look at A minor; the parallel minor scale of C major, we can see
that the scale array is the same, but the root has been shifted:

```
        C  C#   D  D#   E   F  F#   G  G#   A  A#   B
Scale: [1,  0,  1,  0,  1,  1,  0,  1,  0,  1,  0,  1]
Root:                                       9
```

#### Application

How to deal with the tonality metadata of a piece is very dependent on the type
of app. Generally, if your app contains a tonality field in its document format
it _should_ be used both when importing and dropping. For a more in-depth
integration you can look at [Take], our vocal recording app:

* If a known and defined tonality is available, it is used to set up the auto-
  tuning system to only tune to pitches that are in the song's key.
* The user can adjust which key they want to sing in. The imported piece is
  pitch shifted to accomodate for the new key, _unless_ it's an atonal piece in
  which case pitch shifting makes no sense.

#### Display

Since there are 12 * 2^12 possible values for the tonality field, we make no
attempt at displaying the _name_ of the tonality correctly. The Allihoopa
website is currently very naive: it completely ignores the root value and shows
the name of the matching major scale. If no matching major scale can be found,
the website will instead display "Exotic". Both examples above would be labeled
"C".

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

        // Download the mix stem audio in AAC/M4A format. You can also use .wave
        // and .oggVorbis
        piece.downloadMixStem(format: .AACM4A, completion: { (data, error) in
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
        [piece downloadMixStemWithFormat:AHAAudioFormatAACM4A completion:^(NSData* data, NSError* error) {
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


[Allihoopa]: https://allihoopa.com
[Carthage]: https://github.com/carthage/carthage
[Releases tab]: https://github.com/allihoopa/Allihoopa-iOS/releases
[SDKExample]: SDKExample
