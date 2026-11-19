---
name: release-tracks
description: Prepare, verify, and publish releases for Automattic Tracks Apple, the Automattic-Tracks-iOS Swift Package. Use when asked to cut a Tracks release, prepare a release branch or release PR, update the Tracks changelog for a version, create the GitHub Release that creates the release tag, or verify the Tracks release process.
---

# Release Tracks

Use this only for `Automattic/Automattic-Tracks-iOS`.
Read `AGENTS.md`, `CHANGELOG.md`, `.buildkite/pipeline.yml`, and current GitHub state before acting.
If those conflict with this skill, follow the repository files and current GitHub state.

Tracks is distributed as a Swift Package.
There is no separate publish command, `fastlane` release lane, podspec, or version file in `Package.swift`.
The release is the GitHub Release and the Git tag it creates.

## Release Contract

- Default branch: `trunk`.
- Release branch: `release/<version>`.
- Version source: `CHANGELOG.md`.
- Tag format: bare semantic version, for example `4.3.0`; do not prefix with `v`.
- Release tag target: the merged release commit on `trunk`, not the pre-merge release branch commit.
- Tag creation: create a GitHub Release and let GitHub create the tag.
  Do not push the tag manually unless the maintainer explicitly changes the release process.

## Workflow

1. Confirm the release target.
   Identify the requested version and whether it is major, minor, or patch.
   Check the current latest tag with `git tag --sort=-v:refname | head` after fetching tags.
   Check open PRs against `trunk` with `gh pr list --base trunk --state open --json number,title,url,isDraft,reviewDecision,mergeStateStatus,statusCheckRollup`.
   Call out non-draft PRs that look ready to merge before the release, especially approved PRs with passing checks, and ask whether the release should wait for them.

2. Create the release branch from current `origin/trunk`.
   Use `release/<version>`, for example `release/4.3.0`.
   Do not use an author-prefixed branch for the actual release branch.

3. Update `CHANGELOG.md`.
   Follow the instructions in the changelog comment.
   Remove empty sections for the release, rename `## Unreleased` to `## <version>`, and add a fresh `## Unreleased` section above it with the existing template.
   Keep release notes factual and based on already-merged changes.

4. Verify locally before opening the release PR.
   Use the repository wrappers:

   ```bash
   bundle exec fastlane ios test clean:true
   bundle exec fastlane mac test clean:true
   make lint
   ```

   If the system `bundle` cannot find the locked Bundler, run Bundler through the Ruby version from `.ruby-version`.
   With the current `.ruby-version`, `mise exec ruby@3.2.2 -- ruby -S bundle install` bootstraps the repo and installs gems into `./vendor/bundle`.
   Keep the `mise` Ruby version aligned with `.ruby-version` if it changes.
   Do not change `Gemfile.lock` or use the global SwiftLint binary to work around local environment issues.

5. Open the release PR.
   Title it `Release <version>`.
   The PR only needs the changelog change unless the repository gained an explicit version file.
   Do not update `Package.swift` for the release version.
   Monitor Buildkite and GitHub checks until they pass.

6. After the PR merges, create the GitHub Release.
   Use the changelog section for that version as the release notes.
   Set the tag and release title to the bare version, for example `4.3.0`.
   Target `trunk` so GitHub creates the tag on the merge commit.
   `gh release create <version> --target trunk --title <version> --notes-file <notes-file>` is acceptable when the notes file contains only the released changelog section.

7. Verify the published release.
   Fetch tags and confirm the tag points at `origin/trunk`:

   ```bash
   git fetch origin --tags
   git rev-parse <version>
   git rev-parse origin/trunk
   ```

   Confirm the GitHub Release exists and shows the intended notes.

## CI Notes

At the time this skill was written, `.buildkite/pipeline.yml` contains iOS tests, macOS tests, and SwiftLint only.
It does not define tag-specific release or publish behavior.
Re-check the file before each release; if tag-specific Buildkite behavior appears later, follow the repository config before creating the GitHub Release.

## Guardrails

- Do not create a tag before the release PR is merged.
- Do not tag the release branch commit after the PR has merged.
- Do not invent release notes from commit titles when `CHANGELOG.md` already has the release notes.
- Do not skip ready-PR discovery before cutting the release branch.
- Do not run SwiftLint with a global `swiftlint`; use `make lint`.
