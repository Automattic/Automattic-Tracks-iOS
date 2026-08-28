## Project overview

Tracks is Automattic's analytics and event-tracking platform.
This project is the Tracks client for Apple platforms, distributed as Swift Package.

The codebase is a mix of Objective-C (legacy) and Swift (active).
There is an incremental ObjC → Swift migration in progress for in the Event Logging module.
The desired end state is for the whole library to be pure, modern Swift.

## Directory structure

```
Sources/
├── AutomatticTracks/          # Umbrella module (re-exports everything)
├── Event Logging/             # ObjC event tracking (being migrated)
├── Event Logging (Swift)/     # Swift migration path for events
├── Encrypted Logs/            # Log encryption and upload
├── Remote Logging/            # Crash logging via Sentry
├── Experiments/               # A/B testing (ExPlat)
├── UI/                        # Crash logging UI components
├── Model/
│   ├── ObjC/Common/           # Shared ObjC models
│   ├── ObjC/Constants/        # ObjC constants
│   └── Swift/                 # Swift models
└── Workaround-SPM/            # SPM-specific workarounds

Tests/
├── Tests/                     # Swift unit tests
│   ├── ABTesting/
│   ├── CoreData/
│   ├── Event Logging/
│   └── ObjC/                  # ObjC tests (separate target)
├── Test Helpers/
└── Mock Data/

TracksDemo/                    # Demo apps (iOS + macOS)
```

## Bootstrap

Requires the Xcode version in `.xcode-version` and Ruby in `.ruby-version`.

```
bundle install
bundle exec fastlane ios test clean:true
```

That's it — SPM dependencies resolve automatically during the build.

## Commands

### Build and test (iOS)

```
bundle exec fastlane ios test
```

### Build and test (macOS)

```
bundle exec fastlane mac test
```

Both lanes accept `clean:true` for a clean build with full SPM dependency resolution.
The default (`clean:false`) skips SPM resolution for faster incremental builds.

### Lint

```
make lint
```

Autofix available via `make format`.

SwiftLint runs via the `BuildTools/` SPM plugin, which reads the version from `.swiftlint.yml`.
Do not use the global `swiftlint` binary — it may be a different version.

## Conventions

### Commits and PRs

- Default branch: `trunk`.
- PRs should update `CHANGELOG.md` when warranted. See PR template @.github/PULL_REQUEST.md. See PR template @.github/PULL_REQUEST_TEMPLATE.md .
- `CHANGELOG.md` follows [Keep a Changelog](https://keepachangelog.com/).

### Releases

Use @.claude/skills/release-tracks/SKILL.md when preparing or publishing a Tracks release.

### Tests

Two test targets in `Package.swift`:

- `AutomatticTracksTests` — Swift tests.
- `AutomatticTracksTestsObjC` — ObjC tests using OCMock.

HTTP interactions are stubbed with OHHTTPStubs.

When adding new tests, prefer Swift Testing over XCTest.

## Architecture

### Module graph

`AutomatticTracks` is the umbrella module.
We expect most consumers import it to get everything.

`AutomatticEncryptedLogs` can be imported standalone for apps that only need log encryption.

Dependency flow:

```
AutomatticTracks
├── AutomatticTracksEvents (ObjC) → AutomatticTracksEventsForSwift (Swift bridge)
├── AutomatticRemoteLogging → Sentry, Sodium, EncryptedLogs
├── AutomatticExperiments (ExPlat)
├── AutomatticCrashLoggingUI → RemoteLogging
└── AutomatticTracksModel / ModelObjC / ConstantsObjC
```

### Core Data

The library uses Core Data for local event persistence.
Model files live alongside source code, not in a separate bundle.

In the long run, we wish to remove Core Data in favor of a leaner persistence layer for transient events.

## Common pitfalls

- **fastlane test scheme**: tests run via the `TracksDemo` / `TracksDemo Mac` Xcode schemes, not the SPM package directly.
  The demo project at `TracksDemo/TracksDemo.xcodeproj` must stay buildable.
- **Spaces in directory names**: several source directories have spaces (`Event Logging`, `Event Logging (Swift)`, `Encrypted Logs`, `Remote Logging`).
  Be careful with shell commands and path handling.
- **ObjC interop**: the `Event Logging` module exposes ObjC headers.
  Changes to ObjC public headers can break Swift consumers.
