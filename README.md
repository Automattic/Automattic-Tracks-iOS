# Automattic-Tracks-iOS
Client library for tracking user events for later analysis

## Introduction

Tracks for iOS is a client library used to help track events inside of an application. This project solely is responsible for collecting the events, storing them locally, and on a schedule send them out to the Automattic servers. Realistically this library is only useful for Automattic-based projects but the idea is to share what we've made.

## Installation

You can install the Tracks component in your app via [CocoaPods](http://cocoapods.org):

```ruby
pod 'Automattic-Tracks-iOS', :git => 'git@github.com:Automattic/Automattic-Tracks-iOS.git', :branch => 'develop'
```

1. Create an instance of `TracksService`.
2. Set an appropriate event name prefix using the propert `eventNamePrefix`. As an Automattician you will know how to get a prefix whitelisted.
3. Keep this instance in a stable place and only instantiate one for your application.

## Usage

Check out the **TracksDemo** project for more information on how to track events.

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
