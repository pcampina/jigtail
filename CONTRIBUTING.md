# Contributing to JigTail

Bug reports, ideas and pull requests are welcome. For anything bigger than a small fix, please
open an [issue](https://github.com/pcampina/jigtail/issues) first so we can agree on the
approach before you put time into it.

## Requirements

- macOS 13 (Ventura) or later, on Apple Silicon
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`). The
  `.xcodeproj` is generated from [`project.yml`](project.yml), which is the source of truth
  for the project structure. Don't hand-edit `JigTail.xcodeproj`: change `project.yml`, run
  `xcodegen generate`, and commit both.

## Building

```bash
xcodegen generate
open JigTail.xcodeproj
```

Or entirely from the command line:

```bash
xcodegen generate
xcodebuild -project JigTail.xcodeproj -scheme JigTail -configuration Debug build
```

Debug builds use automatic signing with the maintainer's team. To build under your own
account, pick your team in Xcode (Signing & Capabilities) and leave that change out of your
pull request. Release builds are signed by CI with Developer ID, see [Releasing](#releasing).

## Tests

```bash
xcodebuild -project JigTail.xcodeproj -scheme JigTail -configuration Debug test
```

Or exactly the way CI runs them:

```bash
bundle install
bundle exec fastlane test
```

Idle detection, sleep prevention and the jiggle itself depend on real OS state, so unit tests
can't cover them. [`TESTING.md`](TESTING.md) explains how to check that behavior by hand.

## Architecture

- `JiggleCoordinator` (`JigTail/State`) is the central orchestrator. It wires idle detection,
  the jiggle mechanism, sleep prevention and (in conditional mode) the trigger engine
  together, and exposes a single state enum (`off` / `idleWaiting` / `activeJiggling`) that
  the UI renders from.
- `Services/` holds the system-facing pieces: `IdleMonitorService`, `JiggleService` (the
  actual `CGEventPost` cursor nudge), `SleepPreventionService` (`IOPMAssertion`),
  `LaunchAtLoginService` (`SMAppService`), `PermissionsService` (Accessibility), and
  `TriggerEngine` with its pluggable `Services/Triggers/*` conditions. `SettingsStore`
  (`JigTail/State`) persists user settings to `UserDefaults`.
- `Views/` (`MenuBar/`, `Settings/`) is SwiftUI, built on a small neumorphic design system in
  `DesignSystem/` (tokens and components) ported from `neurocampx-ds`.

## Releasing

Releases are cut by pushing a version tag:

```bash
git tag v0.2.0 && git push origin v0.2.0
```

[`.github/workflows/release.yml`](.github/workflows/release.yml) runs the unit tests, then
`bundle exec fastlane release_mac` ([`fastlane/Fastfile`](fastlane/Fastfile)). That lane pulls
the Developer ID certificate and profile from the shared `pcampina/certificates` match repo
(readonly), archives with the tag's version, notarizes and staples the app, and wraps it in a
signed, notarized `JigTail.dmg` that's published as the latest GitHub Release. The landing
page links to `releases/latest/download/JigTail.dmg`, so it picks the new build up on its own.
Running the workflow manually (**Actions → Release → Run workflow**) builds the DMG as a run
artifact without publishing anything.

The workflow needs these repository secrets: `MATCH_PASSWORD`, `MATCH_GIT_PRIVATE_KEY`
(base64 of a deploy key with read access to the certificates repo), `ASC_KEY_ID`,
`ASC_ISSUER_ID`, and `ASC_PRIVATE_KEY` (an App Store Connect API key, used for notarization).

The Developer ID provisioning profile is created once, from a machine with write access to the
certificates repo, using an App Store Connect API key for the same team. The `.p8` is read from
`~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8` unless `key_path:` says otherwise:

```bash
bundle install
bundle exec fastlane sync_signing key_id:<KEY_ID> issuer_id:<ISSUER_ID>
```
