# Changelog

The format of this document is inspired by [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and the project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- This is a comment, you won't see it when GitHub renders the Markdown file.

When releasing a new version:

1. Remove any empty section (those with `_None._`)
2. Update the `## Unreleased` header to `## <version_number>`
3. Add a new "Unreleased" section for the next iteration, by copy/pasting the following template:

## Unreleased

### Breaking Changes

_None._

### New Features

_None._

### Bug Fixes

_None._

### Internal Changes

_None._

-->

## Unreleased

### Breaking Changes

_None._

### New Features

_None._

### Bug Fixes

_None._

### Internal Changes

_None._

## 3.4.0

### Bug Fixes

- Fix a deadlock while getting device info. [#282]

### Internal Changes

- The `device_info_status_bar_height` event property value now will always be zero. [#281]
- Calculate `device_info_orientation` event property value based on "device orientation" rather than "interface orientation". [#281]

## 3.3.0

### New Features

- Add function to log JavaScript exceptions in `CrashLogging` [#278]

## 3.2.0

### New Features

- CrashLogging new API that supports logging Errors with Tag/Value [#274]

## 3.1.0

### New Features

- CrashLoggingDataProvider now allows to specify the events sampling rate [#271]

## 3.0.0

### Breaking Changes

- Sentry: The default `releaseName` value is now the Sentry default of `package@version+build` (e.g. com.bundle.identifier@1.2+1.2.3.4) instead of only providing the `CFBundleVersionKey` [#267]

## 2.4.0

### Breaking Changes

_None._

### New Features

- `TracksService.trackEventName:withCustomProperties:` now returns a boolean that indicates whether the event creation is successful.

### Bug Fixes

- `TracksLogging` now works when the library is integrated with Cocoapods for internal Tracks error/warning messages.

### Internal Changes

- `TracksService.trackEventName:withCustomProperties:` now logs the event name when there is a validation error from creating a Tracks event.

_None._

## 2.3.0

### Breaking Changes

_None._

### New Features

- Add options to configure Sentry's app hang and HTTP client error tracking. [#261]

### Bug Fixes

_None._

### Internal Changes

_None._

## 2.2.0

### Internal Changes

- Refactor `ExPlat` configuration logic to allow clients to explicitly specify the platform to use. [#253]

## 2.1.0

### New Features

- The Sentry SDK has been updated to version 8.0.0, and now exposes [Performance Profiling](https://docs.sentry.io/product/profiling/) as an option. [#245]

## 2.0.0

### Breaking Changes

- `ExPlat` returns optional instead of assuming `control` as variant. This lets the client know that there is no variant for an experiment. [#247]

### Internal Changes

- Make `Variation` confirm to `Codable`. [#247]

## 1.0.0

### Breaking Changes

- `logErrorImmediately` and `logErrorsImmediately` no longer have a `Result` parameter in their callback [#232]
- `logErrorImmediately` and `logErrorsImmediately` no longer `throws` [#236]
- `ExPlat` returns optional instead of assuming `control` as variant. This lets the client know that there is no variant for an experiment. [#247]

### Internal Changes

- Add this changelog file [#234]
- Log a message if events won't be collected because the user opted out [#239]
- Tracks now requires at least Xcode 13. [#244]
