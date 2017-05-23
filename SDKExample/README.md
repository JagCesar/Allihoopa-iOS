# Allihoopa SDK example project

This is a test harness for the Allihoopa SDK. It is intended to be used in
conjunction with developing new SDK features or tracking down bugs.

Since `Allihoopa-iOS` depends on the shared `AllihoopaCore-ObjC` library,
getting the example up and running requires some setup:

1. Install [Carthage], `brew install carthage` if you're using [Homebrew].
2. Run `carthage bootstrap` in the parent folder
3. Copy `SDKExample/Credentials.template.xcconfig` to
   `SDKExample/Credentials.xcconfig` and insert your application identifier and
   API key into the file.
4. Open up `SDKExample.xcworkspace` in Xcode.
5. Select the `SDKExample` project and make sure `Credentials.xcconfig` has been
   picked as the configuration set for the application target.
6. Hit Run - everything should work now.


### Modifying the Core library

Often you need to update the [AllihoopaCore-ObjC] library and try out the
changes in this project. To do that, build the Core library through Carthage and copy the `Carthage` folder over to this repository:

```
# In the AllihoopaCore-ObjC checkout
carthage build --no-skip-current --platform ios --configuration Debug
cp -r Carthage ../Allihoopa-iOS
```

This also has the upside of producing a logging debug build with optimizations
disabled for easier debugging.


[Carthage]: https://github.com/carthage/carthage
[Homebrew]: http://brew.sh
[AllihoopaCore-ObjC]: https://github.com/allihoopa/AllihoopaCore-ObjC
