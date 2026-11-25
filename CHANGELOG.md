# Changelog

## Unreleased

- Refresh Android launcher widgets from their offline timeline after a resize, reboot, or manual clock change. Replace expired values with a tap-to-refresh tile. ([#12](https://github.com/repasscloud/astro-worker/issues/12), [#13](https://github.com/repasscloud/astro-worker/issues/13))
- Accept consistent licence filenames across Flutter SDK archives while continuing to verify their content hashes. ([#42](https://github.com/repasscloud/astro-worker/issues/42))

- Verify rise, set, and solar noon for Adelaide, San Francisco, and Apia against independent sea-level calculations. ([#5](https://github.com/repasscloud/astro-worker/issues/5))

- Label UTC and the selected local time zone in calendar event details. ([#9](https://github.com/repasscloud/astro-worker/issues/9))
- Check bundled Windows licence notices and confirm that Web startup uses only same-origin resources. ([#25](https://github.com/repasscloud/astro-worker/issues/25), [#42](https://github.com/repasscloud/astro-worker/issues/42))

- Cross-check house systems at three latitudes and qualify sample personal chart comparisons and a solar return against Swiss Ephemeris reference values. ([#21](https://github.com/repasscloud/astro-worker/issues/21), [#22](https://github.com/repasscloud/astro-worker/issues/22))

- Regenerate Flutter's release plugin registrants when staging packages and check the Android release-mode APK in hosted validation. ([#26](https://github.com/repasscloud/astro-worker/issues/26))

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
- Add opt-in Android and macOS reminders for lunar and seasonal events, with advance timing, quiet hours, and rolling local scheduling. ([#18](https://github.com/repasscloud/astro-worker/issues/18))
- Validate Sun, Moon and seven planetary positions against JPL Horizons samples at the supported range boundaries and a midpoint. ([#3](https://github.com/repasscloud/astro-worker/issues/3))
- Add opt-in Android GPS lookup for observer coordinates, with manual entry and local confirmation. ([#5](https://github.com/repasscloud/astro-worker/issues/5))
- Add private birth profiles, date-only sign previews, and known-time natal charts with Whole Sign or Equal houses. ([#20](https://github.com/repasscloud/astro-worker/issues/20), [#21](https://github.com/repasscloud/astro-worker/issues/21))
- Add dated transits, solar returns, synastry and composite midpoints for local profiles with known birth times. ([#22](https://github.com/repasscloud/astro-worker/issues/22))
- Stage non-iOS release candidates with artifact and exact-revision source checksums, support private Android release signing, and document the distribution gates. ([#26](https://github.com/repasscloud/astro-worker/issues/26), [#29](https://github.com/repasscloud/astro-worker/issues/29), [#31](https://github.com/repasscloud/astro-worker/issues/31), [#32](https://github.com/repasscloud/astro-worker/issues/32), [#33](https://github.com/repasscloud/astro-worker/issues/33), [#34](https://github.com/repasscloud/astro-worker/issues/34), [#35](https://github.com/repasscloud/astro-worker/issues/35))
- Add pinned Swiss Ephemeris qualification probes for native and Wasm, including checksum, coverage, and fallback checks. ([#4](https://github.com/repasscloud/astro-worker/issues/4), [#36](https://github.com/repasscloud/astro-worker/issues/36), [#38](https://github.com/repasscloud/astro-worker/issues/38), [#39](https://github.com/repasscloud/astro-worker/issues/39), [#40](https://github.com/repasscloud/astro-worker/issues/40))
