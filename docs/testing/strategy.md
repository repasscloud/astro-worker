# Test strategy

Run `scripts/check.sh` and the five-target CI workflow. Independent fixtures cover principal lunar phases. Deterministic unit tests exercise timezones, numerology, event ranges, aspects and positions. A widget test covers small-screen navigation and saved preferences. The integration test exercises the production bootstrap on macOS, with Android or other Flutter integration targets usable when available.

Expand cross-platform coverage with independent positions, rise/set and eclipse fixtures, corrupt resource fixtures, screen-reader runs, widget refresh and browser offline upgrades. Profile long event searches and launch with agreed memory and frame budgets.

For the PWA smoke test, run `scripts/build_web.sh --base-href /astro/` and then `node scripts/check_web_offline.mjs`. Set `CHROME_EXECUTABLE` if Chrome is installed elsewhere. The test serves two packaged builds on loopback and uses a disposable Chrome profile to check installability, startup with an unavailable server, upgrade activation, and rollback. Launcher installation and standalone behaviour on other browsers require separate verification.
