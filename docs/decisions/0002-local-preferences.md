# ADR 0002 — Use namespaced local preferences

Accepted. Use Shared Preferences for the baseline's small configuration values and optional civil birth date. Keep derived astronomy in memory. Evaluate transactional storage when profiles or persistent ephemeris assets warrant it. Use a separately versioned widget snapshot so native readers never need to access the Flutter settings store.
