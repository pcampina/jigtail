<p align="center">
  <img src="docs/assets/icon.png" alt="JigTail app icon" width="128" height="128" />
</p>

<p align="center">
  <a href="https://www.buymeacoffee.com/pcampina">
    <img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=☕&slug=pcampina&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" alt="Buy Me A Coffee" />
  </a>
</p>

<h1 align="center">JigTail</h1>

<p align="center">
  <b>Keeps your Mac awake, but only when it actually needs to.</b>
</p>

<p align="center">
  A free menu bar app for macOS. It waits until you step away, then moves the pointer a
  couple of points every 40 seconds so your Mac doesn't lock, dim or fall asleep halfway
  through a long export, download or backup. Start using your Mac again and it goes back
  to waiting.
</p>

<p align="center">
  <a href="https://github.com/pcampina/jigtail/releases/latest/download/JigTail.dmg"><b>Download for Mac</b></a>
  &nbsp;·&nbsp;
  <a href="https://pcampina.github.io/jigtail/">Website</a>
</p>

<p align="center">
  <a href="https://github.com/pcampina/jigtail/actions/workflows/release.yml"><img alt="Release build" src="https://github.com/pcampina/jigtail/actions/workflows/release.yml/badge.svg"></a>
  <a href="https://github.com/pcampina/jigtail/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/pcampina/jigtail"></a>
  <a href="https://github.com/pcampina/jigtail/releases"><img alt="Downloads" src="https://img.shields.io/github/downloads/pcampina/jigtail/total"></a>
  <a href="#install"><img alt="macOS 13+ on Apple Silicon" src="https://img.shields.io/badge/macOS-13%2B%20%C2%B7%20Apple%20Silicon-000000?logo=apple"></a>
  <a href="#install"><img alt="Notarized by Apple" src="https://img.shields.io/badge/notarized-Developer%20ID-2ea44f?logo=apple"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/github/license/pcampina/jigtail"></a>
  <a href="https://www.buymeacoffee.com/pcampina"><img alt="Buy me a coffee" src="https://img.shields.io/badge/-Buy%20me%20a%20coffee-ffdd00?logo=buy-me-a-coffee&logoColor=black"></a>
  <a href="https://pcampina.github.io/jigtail/"><img alt="Website" src="https://img.shields.io/badge/website-pcampina.github.io%2Fjigtail-ff6b35"></a>
</p>

<p align="center">
  <img src="docs/popover-light.png" width="380" alt="JigTail's menu bar popover in light mode, jiggling, with the countdown ring running" />
  <img src="docs/popover-dark.png" width="380" alt="JigTail's menu bar popover in dark mode, switched off" />
</p>

## Why JigTail

Your Mac can't tell the difference between you walking away and you waiting on a render.
After a few idle minutes it dims the display, starts the screensaver or goes to sleep, and a
long download, render or backup can stall along with it.

JigTail sits in the menu bar and covers that gap. It leaves the pointer alone while you work
and only steps in once you've really been away. If you've used Jiggler before, this does the
same job as a native app that fits in on a current Mac.

## What it does

### Waits until you're gone

Choose how long you need to be idle before it starts: 1, 5, 15, 30 or 60 minutes straight from
the popover, or anything from 1 to 120 minutes in Settings. The default is 5.

### Nudges instead of dragging

Every 40 seconds it moves the pointer two points and puts it right back. The cursor flashes for
a split second so you know it was JigTail. You can set the interval anywhere from 10 seconds to
5 minutes. Before each nudge it checks for real mouse or keyboard input, and if you're back, it
stops and waits for you to go idle again.

### Only when something is running

Switch the trigger mode to Conditional and JigTail keeps the Mac awake only while at least one
of these is true:

- an app you pick is open, like your renderer, Transmission or a local CI runner
- CPU usage is above a threshold you set (30% by default)
- Music or Spotify is playing

It checks again every 10 seconds and goes back to waiting when none of them apply.

### Shows you what it's doing

Click the menu bar icon and one knob tells you the state: off, waiting for you to go idle, or
jiggling. A ring around it counts down to the next step, so you're never guessing.

### Keeps idle sleep away

While JigTail is switched on, it also tells macOS not to idle-sleep the system, which covers the
minutes before jiggling kicks in too.

### Stays out of the way

No Dock icon. It arms itself when it launches, can start at login, and follows your system
appearance or sticks to light or dark mode.

## Install

1. Download [JigTail.dmg](https://github.com/pcampina/jigtail/releases/latest/download/JigTail.dmg)
   from the latest release.
2. Open it and drag JigTail into Applications.
3. Launch JigTail. The first time, macOS asks for Accessibility access. Turn JigTail on in
   System Settings > Privacy & Security > Accessibility, then click the knob in the menu bar
   popover to start.

JigTail is signed with a Developer ID and notarized by Apple, so it opens like any other app.
It needs macOS 13 Ventura or later on an Apple Silicon Mac.

## Privacy

JigTail never connects to the internet. There's no account, no analytics and no crash
reporting, and your settings stay in the app's local preferences on your Mac.

It asks for two permissions:

- Accessibility, to move the pointer. Without it JigTail can't do its job, so it won't turn on.
- Automation for Music and Spotify, only if you enable the "Music or Spotify is playing"
  trigger. JigTail uses it to ask those apps whether they're playing, nothing else.

## FAQ

<details>
<summary>Will it move the pointer while I'm using my Mac?</summary>

No. Before every nudge it looks at when you last used the mouse or keyboard. If that was
recent, it skips the nudge and goes back to waiting.

</details>

<details>
<summary>Does it stop my Mac from sleeping when I close the lid?</summary>

No. It only prevents idle sleep. Closing the lid or choosing Sleep from the Apple menu works
exactly as before.

</details>

<details>
<summary>Why does it need Accessibility access?</summary>

macOS only lets apps with Accessibility access post mouse events. JigTail uses it for the
two-point nudge and for nothing else.

</details>

<details>
<summary>Does it run on Intel Macs?</summary>

Not at the moment. Builds are Apple Silicon only.

</details>

<details>
<summary>How do I update?</summary>

There's no auto-updater yet. Download the latest
[JigTail.dmg](https://github.com/pcampina/jigtail/releases/latest/download/JigTail.dmg) and
replace the app in Applications. That link and the website always point to the newest build.

</details>

<details>
<summary>Is it really free?</summary>

Yes. It's open source under the MIT license, with no paid tier and nothing to unlock.

</details>

## Support JigTail

I build and maintain JigTail on my own time, and it will stay free. If it saved one of your
exports, you can [buy me a coffee](https://www.buymeacoffee.com/pcampina). A star on the repo
helps other people find it, and if something doesn't work the way you expect,
[open an issue](https://github.com/pcampina/jigtail/issues).

## Contributing

Want to build it yourself or send a fix? [CONTRIBUTING.md](CONTRIBUTING.md) covers building,
tests, how releases are made and how the code is organized.

## License

MIT. See [LICENSE](LICENSE).
