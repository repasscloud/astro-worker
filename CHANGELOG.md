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
