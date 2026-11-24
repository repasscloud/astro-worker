# Test strategy

Run `scripts/check.sh` and the five-target CI workflow. Independent fixtures cover principal lunar phases. Deterministic unit tests exercise timezones, numerology, event ranges, aspects and positions. A widget test covers small-screen navigation and saved preferences. The integration test exercises the production bootstrap on macOS, with Android or other Flutter integration targets usable when available.

Expand cross-platform coverage with independent positions, rise/set and eclipse fixtures, corrupt resource fixtures, screen-reader runs, widget refresh and browser offline upgrades. Profile long event searches and launch with agreed memory and frame budgets.

For the PWA smoke test, run `scripts/build_web.sh --base-href /astro/` and then `node scripts/check_web_offline.mjs`. Set `CHROME_EXECUTABLE` if Chrome is installed elsewhere. The test serves two packaged builds on loopback and uses a disposable Chrome profile to check installability, startup with an unavailable server, upgrade activation, and rollback. Launcher installation and standalone behaviour on other browsers require separate verification.

Run the Android widget timeline tests with `cd android && ./gradlew :app:testDebugUnitTest`. These checks exercise interval boundaries, expiry, and corrupt payload rejection. They complement the launcher checks in [platform widgets](../platforms/widgets.md).

Initial performance samples on an Apple M2 Pro used a warmed Dart VM, 100 fixed dates, and the current Meeus provider. Sky snapshots took about 3.4 ms median and 3.8 ms at p95. One-year calendar queries took about 0.22 ms median and 0.40 ms at p95. The Chromium loopback smoke test measured roughly 0.8 s to the first controlled render and 0.18 s after an offline start in a primed profile. These are measurements from a development host. Device-specific startup, scroll frame pacing, and memory budgets remain separate checks.

Calendar export smoke checks verified that a single event selected in Chromium downloaded an ICS file and that the Samsung Android share chooser received an ICS attachment containing the selected event's UTC time. Import into desktop and mobile calendar clients remains a separate acceptance check.
