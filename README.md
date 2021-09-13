# Automattic-Tracks-iOS
Client library for tracking user events for later analysis

## Introduction

Tracks for iOS is a client library used to help track events inside of an application. This project solely is responsible for collecting the events, storing them locally, and on a schedule send them out to the Automattic servers. Realistically this library is only useful for Automattic-based projects but the idea is to share what we've made.

## Installation


You can install the Tracks component in your app via Swift Package Manager:

```swift
.package(url: "https://github.com/Automattic/Automattic-Tracks-iOS", from: "0.10.0")
```

You can import the entire library, using `import AutomatticTracks`. Or, you can import just one particular part of the library:

```swift
// Reporting events to the internal 'Tracks' service
import AutomatticTracksEvents

// Uploading app logs and crash logs to internal monitoring tools
import AutomatticRemoteLogging

// Running experiments using the internal 'ExPlat' tool
import AutomatticExperiments

// Displaying crash logs in your app
import AutomatticCrashLoggingUI
```

Tracks can also be installed via CocoaPods, though we encourage users to use Swift Package Manager instead. To install via Cocoapods:

```ruby
pod 'Automattic-Tracks-iOS'
```

## Usage

### To report events:

1. Create an instance of `TracksService`.
2. Set an appropriate event name prefix using the propert `eventNamePrefix`. As an Automattician you will know how to get a prefix allowed.
3. Keep this instance in a stable place and only instantiate one for your application.

Check out the **TracksDemo** project for more information on how to track events.

### To run experiments:

1. Call `ExPlat.configure(platform:oauthToken:userAgent:anonId:)` to configure the experiment platform. (If you are using `TracksService`, it will make this call for you when you create the Tracks service.)
2. Register the experiments the app should use via `Explat.shared.register(experiments:)`.
3. Check `ExPlat.shared.experiment("my_experiment_name")` to determine which variant of an experiment should be used.

### To upload files:

1. Create an instance of `EventLogging` using `init(dataSource:delegate:)`.
2. Call `enqueueLogForUpload(log:)` to schedule log files for uploading.


### Logging

Tracks logs about some of its activity. By default, this logging will just go to the console. If you'd like to include this logging in your own logging solution, you can create and assign a logging delegate conforming to `TracksLoggingDelegate`:

```swift
TracksLogging.delegate = MyLoggingHandler()
```


## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## Credits

Original source: https://github.com/Automattic/Automattic-Tracks-iOS

Created by initially: Aaron Douglas @astralbodies

## License

Automattic-Tracks-iOS is available under the MIT license. See the [LICENSE](https://raw.githubusercontent.com/Automattic/Automattic-Tracks-iOS/develop/LICENSE) file for more info.
