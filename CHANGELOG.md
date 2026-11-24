# Changelog

## Unreleased

- Initialise the shared Flutter application and platform runners.
- Add offline astronomy, numerology and daily editorial content.
- Calculate local horizon events from optional observer coordinates.
- Adopt AGPL-3.0 and document the approved pricing, self-build and source distribution model. ([#1](https://github.com/repasscloud/astro-worker/issues/1))
- Set the initial version to 1.0.0, add commit-based official build identity and expose the app licence and corresponding source in About. ([#1](https://github.com/repasscloud/astro-worker/issues/1))
- Verify lunar phase timing at both ends of the supported date range against U.S. Naval Observatory data. ([#3](https://github.com/repasscloud/astro-worker/issues/3))
- Keep Android screen content above the system navigation buttons.
- Add four Android home-screen widgets: Moon Glance, Lunar Reflection, Lunar Colour, and Moon Phase & Info. Widgets use a 48-hour offline timeline and open the matching section of the app. ([#12](https://github.com/repasscloud/astro-worker/issues/12), [#13](https://github.com/repasscloud/astro-worker/issues/13))
- Export selected astronomy events as an offline `.ics` file with stable identifiers and UTC event times. ([#19](https://github.com/repasscloud/astro-worker/issues/19))
- Document worked numerology examples and verify master-number settings, leap-day birth dates, and deletion of stored birth dates. ([#10](https://github.com/repasscloud/astro-worker/issues/10))
- Reuse calendar calculations while toggling filters or refreshing the same date range. ([#24](https://github.com/repasscloud/astro-worker/issues/24))
- Add a Chromium smoke test for web installability, offline startup, service-worker upgrades, and rollback. ([#17](https://github.com/repasscloud/astro-worker/issues/17))
- Expose the current screen title as a heading for assistive technology and verify keyboard event selection at increased text scale. ([#23](https://github.com/repasscloud/astro-worker/issues/23))
- Validate the full Android widget timeline before replacing cached data and ignore corrupt or expired snapshots. ([#12](https://github.com/repasscloud/astro-worker/issues/12))
- Recover from malformed saved preference types and accept a legacy integer aspect orb. ([#25](https://github.com/repasscloud/astro-worker/issues/25))
- Cross-check the 2025 seasonal events and sample solar and lunar eclipse timings against USNO and NASA references. ([#9](https://github.com/repasscloud/astro-worker/issues/9))
- Show previous and upcoming tropical zodiac ingresses and direct and retrograde stations in planet details. ([#7](https://github.com/repasscloud/astro-worker/issues/7))
- Add English and Spanish editorial editions with daily intentions, interpretations and offline language fallback. ([#11](https://github.com/repasscloud/astro-worker/issues/11))
- Add a manual GitHub Actions workflow to validate Android, macOS, Web and Windows builds. ([#2](https://github.com/repasscloud/astro-worker/issues/2))
- Add a zodiac wheel, Lahiri and Fagan–Bradley settings, and exact major-aspect searches. Use the selected zodiac for sign labels, ingresses, and widget snapshots. ([#8](https://github.com/repasscloud/astro-worker/issues/8))
- Audit licence evidence for every locked Dart package and verify dependency notices are available from the app offline. ([#41](https://github.com/repasscloud/astro-worker/issues/41), [#42](https://github.com/repasscloud/astro-worker/issues/42))
- Show lunar apsides, approximate observer-oriented Moon artwork, and a separately labelled traditional void-of-course window with two body sets. ([#6](https://github.com/repasscloud/astro-worker/issues/6))
- Add local settings backup, validated restore, and reset. Migrate existing preferences and exclude personal details from backups by default. ([#25](https://github.com/repasscloud/astro-worker/issues/25))
- Embed a small and medium Moon widget for macOS with offline WidgetKit timelines and an App Group signing template. ([#15](https://github.com/repasscloud/astro-worker/issues/15))
- Record the Windows Widgets Board packaging path and the Windows 11 host checks still required. ([#16](https://github.com/repasscloud/astro-worker/issues/16))
