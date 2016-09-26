Allihoopa SDK for iOS
=====================

[![Travis](https://img.shields.io/travis/allihoopa/Allihoopa-iOS/master.svg?maxAge=2592000&style=flat-square)]()
[![CocoaPods](https://img.shields.io/cocoapods/v/Allihoopa.svg?maxAge=2592000&style=flat-square)]()
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat-square)](https://github.com/Carthage/Carthage)

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

You need to add two keys to your `Info.plist`: 

* Set `AllihoopaSDKAppKey` to your Allihoopa app key
* Set `AllihoopaSDKAppSecret` to your Allihoopa app secret

Also, you will need to register for the `ah-{APP_KEY}` URL scheme; e.g. 
`ah-figure` if your app key is `figure`.


## Development setup

Look in the [SDKExample] folder for instructions how to work on this SDK.


# API documentation

## Setting up the SDK

```swift
import Allihoopa

// In your UIApplicationDelegate implementation
func applicationDidFinishLaunching(_ application: UIApplication) {
    AHAAllihoopaSDK.setup()
}

func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    if AHAAllihoopaSDK.handleOpen(url) {
        return true
    }

    return false
}
```

```objective-c
#import <Allihoopa/Allihoopa.h>

// In your UIApplicationDelegate implementation
- (void)applicationDidFinishLaunching:(UIApplication*)application {
    [AHAAllihoopaSDK setup];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if ([AHAAllihoopaSDK handleOpenURL:url]) {
        return YES;
    }

    return NO;
}
```

`setup` must be called *before* any other API calls can be made. It will
automatically read the API credentials from your `Info.plist` - check the
configuration heading above.

`handleOpenURL` must be called inside the URL handler of your application. It
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
