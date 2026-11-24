# Privacy

The app calculates astronomy and selects editorial content on the device. The baseline has no accounts, analytics, advertising or background transmission. The optional birth date is local and can be removed in Settings. The app stores display timezone and preferences. Optional manually entered observer coordinates stay in local preferences and can be cleared in Settings. The app does not request a device location permission. Browser deployment fetches its own static app resources and may create standard server access logs.

Future observer and birth chart features should collect only the details required for the chosen calculation. Keep personal values out of widget snapshots by default, avoid logging them, and document storage, backup and deletion behaviour before releasing.

Settings backup copies a versioned JSON document to the clipboard on request. It excludes the birth date and observer coordinates by default. If you choose to include them, treat the copied text as personal data. Astro Worker never reads the clipboard in the background. Restore validates the pasted document before writing settings and preserves existing personal records when the backup excludes them. Reset removes app preferences and both optional personal records. The app migrates legacy settings to a single local record and removes the old copies.
