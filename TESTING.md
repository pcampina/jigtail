# Testing JigTail

Idle detection, sleep prevention, and synthetic input aren't meaningfully unit-testable
end-to-end — they depend on real OS state. `JigTailTests` covers the pure-logic pieces
(`SettingsStore` persistence, `TimedAutoStopService` scheduling). Everything else needs
manual verification, below. Phase 0 findings are recorded inline since they shaped the
implementation.

## Phase 0 findings (already verified, informing the current implementation)

**Does a zero-delta synthetic mouse event reset the idle timer, with no visible cursor
movement?** Yes, confirmed empirically:

```bash
swift path/to/spike.swift
# idle before: 44.1s
# idle after 3s untouched wait: 47.1s
# fired zero-delta mouseMoved CGEvent at current cursor position
# idle right after synthetic event: 0.3s
# cursor moved: false
```

This is why `JiggleService` posts a `.mouseMoved` `CGEvent` at the cursor's own current
location rather than an actual displace-and-restore — it's invisible on screen and can't
show up as a real pointer delta to any foreground app or a screen share.

Caveat: this ran unsigned via `swift file.swift` in a Terminal session and worked without
any Accessibility/Input Monitoring permission prompt. Depending on the exact macOS version
and how the shipped, signed `.app` is invoked, `CGEventPost` can silently no-op if the
process isn't trusted for Accessibility — if jiggling appears to do nothing on a fresh
install, check System Settings → Privacy & Security → Accessibility. Not yet handled in
code (no `AXIsProcessTrusted()` check/prompt) — flagged for Phase 1 hardening.

**Does `IOPMAssertionCreateWithName` actually register with powerd?** Yes, confirmed via
`pmset -g assertions` while the assertion was held — it showed up as
`PreventUserIdleSystemSleep named: "JigTail Phase 0 spike"` under the holding PID, and was
gone after `IOPMAssertionRelease`.

## Phase 2 findings (CPUBusyTrigger)

**Does the Mach `host_statistics` sampling actually distinguish idle from busy?** Yes,
confirmed empirically on this (fairly busy) dev machine: ~25% while idle, ~96% while
spinning a busy loop across all cores. The default 30% threshold is close to this
machine's idle baseline — on a quieter Mac 30% is a reasonable default, but if the trigger
fires too eagerly, raise the threshold in Settings > Trigger Conditions.

## Manual smoke-test checklist

- [ ] **Idle timing**: set idle threshold to 1 minute, leave the machine untouched, confirm
      the popover status text flips from "Waiting for idle" to "Awake — jiggling every Ns"
      within one poll interval (~5–10s) of the threshold.
- [ ] **`IOPMAssertion` prevents sleep**: `pmset -g assertions` while JigTail is active
      should show a `PreventUserIdleSystemSleep` line owned by JigTail's PID. Set system
      sleep to 1 minute, confirm the Mac stays awake past that window while JigTail is
      running. Toggle off, confirm the assertion disappears from `pmset -g assertions` and
      the Mac subsequently sleeps on schedule (no leak).
- [ ] **Jiggle doesn't disrupt foreground apps**: leave a blinking text cursor or a
      mid-stroke drawing app open during a jiggle cycle, confirm no visible glitch. Soak-test
      during an active screen share to confirm nothing is visible to viewers.
- [ ] **User-activity backoff**: while JigTail is actively jiggling, move the mouse or type
      for real. Confirm it drops back to "Waiting for idle" rather than fighting you (this is
      the `JiggleService.tick()` heuristic — see its doc comment).
- [ ] **Timed auto-stop**: set a 1–2 minute test duration, confirm a clean stop (state → Off,
      countdown clears, `IOPMAssertion` released) at expiry, and that toggling off manually
      before expiry doesn't leave a dangling timer that still fires later.
- [ ] **Menu bar icon states**: off = `moon.zzz`; armed/waiting = dimmed
      `cursorarrow.motionlines`; active = pulsing `cursorarrow.motionlines`.
- [ ] **Stays out of the Dock**: confirm JigTail never shows a Dock icon or appears in
      Cmd+Tab (LSUIElement / `.accessory` activation policy).
- [ ] **App-running trigger**: Settings > Trigger Conditions > Conditional, enable "Specific
      app is running," choose an app. Confirm jiggling only starts (once idle) while that
      app is running, and stops within ~10s of quitting it (without needing to leave and
      re-cross the idle threshold).
- [ ] **CPU-busy trigger**: enable it, run something CPU-heavy (e.g. `yes > /dev/null` in
      Terminal on a few cores). Confirm jiggling starts while busy and stops within ~10s of
      the load ending.
- [ ] **Media-playing trigger**: enable it, play/pause Music.app or Spotify. Confirm state
      follows playback within one check cycle. Confirm it does **not** launch either app if
      neither is already running.
- [ ] **Conditional mode with nothing enabled**: switch to Conditional with all three
      triggers off — confirm jiggling never starts (this is deliberate: no enabled triggers
      means "never," not "always" — see `TriggerEngine.isAnySatisfied`).
- [ ] **Launch at login**: toggle on in Settings > General, fully restart the Mac, confirm
      JigTail reappears in the menu bar. Check System Settings > General > Login Items for
      the entry. If status shows "requires approval," confirm the button opens System
      Settings to the right place.
- [ ] **Theme override**: switch Settings > General > Theme between System/Light/Dark,
      confirm both the popover and the Settings window follow immediately.
- [ ] **Settings changes apply live**: with JigTail actively jiggling, change the idle
      threshold, CPU threshold, or target app in Settings and confirm the running session
      picks it up without needing to toggle off/on (`refreshTriggerConfiguration()`).

## Running the automated tests

```bash
xcodegen generate
xcodebuild -project JigTail.xcodeproj -scheme JigTail -configuration Debug test
```
