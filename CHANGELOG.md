
Change log
==========

## [1.0.0] — 2017-01-04

### Breaking changes

* The `AHAAllihoopaSDK` methods are now accessed through a singleton interface;
  use `[AHAAllihoopaSDK sharedInstance]` or `AHAAllihoopaSDK.shared()`.
* The `AHADropDelegate`'s completion method has been renamed
  `dropViewController:forPieceWillClose:afterSuccessfulDrop:`/`dropViewController(_:willClose:successfulDrop:)`
* The SDK itself now depends on the [AllihoopaCore-
  ObjC](https://github.com/allihoopa/AllihoopaCore-ObjC) library. Developers
  using Carthage or manual inclusion will need to add that framework to their
  projects.

## [0.4.2] — 2016-12-06

### Added

* Social quick-posting to Facebook and Twitter. The application must provide
  a Facebook App ID for Facebook posting to show up.
* `AHAInvalidUsageException` will now be raised when calling the render methods'
  completion handlers multiple times.
* Note in README about the `Info.plist` permissions required for the camera and
  photo library to work in iOS 10.
* New setup method taking a configuration object. The old setup method will be
  marked deprecated in 0.5.0 and removed in 0.6.0.

### Bugfixes

* The drop flow would call the delegate's render methods multiple times
  after using the camera/photo library on iPad.

## [0.4.1] — 2016-11-23

### Bugfixes

* Including the SDK in a project with Objective-C module support disabled caused
  compiler errors.

## [0.4.0] — 2016-11-09

### Breaking changes

* `+[AHAAllihoopaSDK setupWithApplicationIdentifier:apiKey:]` now requires an
  application-global delegate argument and has thusly been renamed to
  `+[AHAAllihoopaSDK setupWithApplicationIdentifier:apiKey:delegate]`.

### Added

* Support for the "Open in" feature from the website. Users can now pick your
  app from the list of applications to open an application in, and your delegate
  will receive the `openPieceFromAllihoopa:error:` message.

## [0.3.2] — 2016-10-19

### Bugfixes

* Login through Facebook did not work properly

## [0.3.1] — 2016-10-19

### Bugfixes

* CocoaPods project was missing source files and resources

## [0.3.0] — 2016-10-19

### Breaking changes

* The `+[AHAAllihoopaSDK setup:]` method and storing credentials in the Info
  plist were replaced with
  `+[AHAAllihoopaSDK setupWithApplicationIdentifier:apiKey:]`
* "App key" concept renamed to "Application identifier"
* "App secret" concept renamed to "API  key"

### Added

* Support for dropping pieces to Allihoopa

## [0.2.0] — 2016-09-26

### Added

* SDK configuration function/Info.plist support
* User authentication popup support

## 0.1.0 — 2016-09-23

Empty release

[1.0.0]: https://github.com/allihoopa/Allihoopa-iOS/compare/0.4.2...1.0.0
[0.4.2]: https://github.com/allihoopa/Allihoopa-iOS/compare/0.4.1...0.4.2
[0.4.1]: https://github.com/allihoopa/Allihoopa-iOS/compare/0.4.0...0.4.1
[0.4.0]: https://github.com/allihoopa/Allihoopa-iOS/compare/v0.3.2...0.4.0
[0.3.2]: https://github.com/allihoopa/Allihoopa-iOS/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/allihoopa/Allihoopa-iOS/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/allihoopa/Allihoopa-iOS/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/allihoopa/Allihoopa-iOS/compare/v0.1.0...v0.2.0
