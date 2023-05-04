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

- Refactor the unit tests for `ExPlat` assignments request. [#256]

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
