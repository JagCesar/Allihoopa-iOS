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
  pod 'Allihoopa', '~> 0.2.0'
end
```

And then running the following command to download the dependency:

```bash
pod install
```

If you use [Carthage], you instead add this SDK to your `Cartfile`:

```
github "Allihoopa/Allihoopa-iOS" ~> 0.2.0
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
[info@allihoopa.com](mailto:info@allihoopa.com).


## Development setup

Look in the [SDKExample] folder for instructions how to work on this SDK.


# API documentation

## Setting up the SDK

```swift
import Allihoopa

// In your UIApplicationDelegate implementation
func applicationDidFinishLaunching(_ application: UIApplication) {
    AHAAllihoopaSDK.setup(
        applicationIdentifier: "your-application-identifier",
        apiKey: "your-api-key")
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
    [AHAAllihoopaSDK setupWithApplicationIdentifier:@"your-application-identifier"
                                             apiKey:@"your-api-key"];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if ([AHAAllihoopaSDK handleOpenURL:url]) {
        return YES;
    }

    // Call other SDKs' URL handling methods

    return NO;
}
```

`setupWithApplicationIdentifier:apiKey:` must be called *before* any other API
calls can be made. It will throw an exception if the SDK is improperly setup: if
the credentials are missing or if you've not set up the URL scheme properly. For
more information, see the "Steting up the SDK" heading above.

`handleOpenURL:` must be called inside the URL handler of your application. It
will only return true if it successfully handled the URL, making it possible to
chain this call with other URL handlers.


## Authenticating users

```swift
import Allihoopa

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
#import <Allihoopa/Allihoopa.h>

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
