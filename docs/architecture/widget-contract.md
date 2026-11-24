# Widget snapshot contract

Schema 1 includes `generatedAt` and `validUntil` as ISO 8601 UTC instants, display `zone`, `zodiac`, lunar `phase`, `illumination` as a fraction, `moonSign` and `universalDay`. The application renders a small Moon preview and medium combined preview from this contract. Preview instants follow the date selector.

A platform publisher should atomically replace the last complete snapshot, publish only live values, and stop exposing time-sensitive fields after expiry. Native readers should validate the schema, finite fraction, expiry order and accepted string fields, then offer a link back to the dashboard on missing, stale or corrupt data. App Group IDs and Android receiver names must follow platform packaging. Native publisher implementations and hardware acceptance are tracked in Milestone 4.

Android stores a rolling array of schema 1 snapshots. Entries add the waxing and hemisphere flags for the Moon illustration, the editorial colour name and palette, the next principal phase, and a reflection only when spiritual content is enabled. Intervals end at the next hourly refresh point or principal phase boundary, whichever comes first. The launcher chooses the entry covering the current instant.
