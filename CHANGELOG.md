
Change log
==========

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

[0.4.0]: https://github.com/allihoopa/Allihoopa-iOS/compare/v0.3.2...v0.4.0
[0.3.2]: https://github.com/allihoopa/Allihoopa-iOS/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/allihoopa/Allihoopa-iOS/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/allihoopa/Allihoopa-iOS/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/allihoopa/Allihoopa-iOS/compare/v0.1.0...v0.2.0
