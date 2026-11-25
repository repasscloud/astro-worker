# Birth charts and house conventions

A local profile can include a birth date, an IANA timezone, a birth time, and observer coordinates. Unknown birth time is explicit. The date-only view shows sign labels from samples across the local birth day and marks signs that differ. The app omits degrees, angles, and houses in that view. Wall times skipped by daylight saving are rejected. Repeated times use the earlier UTC instant, consistent with the observatory. Dates outside the ephemeris range can be saved and display the range limitation.

With a known time and usable coordinates, the ascendant is the eastern intersection of the apparent ecliptic and observer horizon. The chart suppresses it at geographical poles or a degenerate intersection. Whole sign starts house one at the beginning of the rising sign. Equal houses start at the ascendant degree. Both then divide the zodiac into 30° sectors. For an ascendant of 347°, the first two whole-sign cusps are 330° and 0°. The first two equal cusps are 347° and 17°.

Porphyry divides the four ecliptic quadrants set by the angles. Placidus and Koch use time-based constructions with high-latitude limits. Campanus and Regiomontanus divide a reference great circle and project the divisions onto the ecliptic. Their cusps differ from equal and whole-sign houses and need dedicated latitude and reference-chart checks before exposing them in the app. [House method reference](https://www.astro.com/swisseph-download/doc/swissephprg.pdf)

The table compares second house cusps in degrees from Swiss Ephemeris 2.10.03 `swe_houses` at 2025-01-13 22:27 UTC (UT JD 2460689.435416667). The app tests the supported Whole Sign and Equal systems against these reference charts, including the ascendant. Placidus and Koch returned an error and wrote Porphyry cusps for Tromsø.

| Site | Ascendant | Whole Sign | Equal | Placidus | Koch | Porphyry | Regiomontanus | Campanus |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Adelaide (−34.9285°, 138.6007°) | 325.934 | 330 | 355.934 | 350.034 | 354.482 | 354.431 | 350.508 | 354.893 |
| San Francisco (37.7749°, −122.4194°) | 78.130 | 90 | 108.130 | 99.951 | 102.532 | 100.661 | 103.212 | 107.524 |
| Tromsø (69.6492°, 18.9553°) | 189.704 | 210 | 219.704 | error | error | 222.424 | 206.433 | 232.940 |

A chart with a known time can be compared with the sky on a chosen UTC transit date. Synastry compares two known-time profiles. Both list major aspects within 4°. Composite positions use the shorter-arc midpoint for each pair of like bodies. Exact oppositions have two valid midpoints, so the app leaves those positions unresolved. These comparisons do not calculate composite houses.

The solar return brackets the first return of the Sun to its natal longitude around the selected year's UTC anniversary. The natal and return longitudes use the selected zodiac. Results are calculated offline and remain within the ephemeris range.
