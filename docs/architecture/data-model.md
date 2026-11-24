# Data model

`CelestialPosition` stores degrees and degrees per day, with optional distance in kilometres. `SkyEvent` stores a UTC instant, category and associated body. Event results are derived in memory.

Preferences use the `astro.v1.` namespace. Theme, display timezone, editorial visibility, master-number mode, schematic hemisphere, optional birth date and aspect orb have individual keys. Birth dates are encoded as date-only values using midnight UTC for storage. The date components are read directly for civil calculations.

Shared Preferences maps to lightweight platform preferences and web local storage. Drift and SQLite become relevant if chart profiles or queryable event caches outgrow key-value storage. IndexedDB is a candidate for larger browser resources or transactional data. A native widget consumer should use its platform's shared storage with a versioned payload.
