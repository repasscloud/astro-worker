# Verification and tolerances

The first reference fixtures compare four January 2025 lunar phases with the U.S. Naval Observatory annual table at a 120-second UTC tolerance. A JPL Horizons observer fixture checks apparent ecliptic and equatorial lunar coordinates (0.02°), geocentric distance (50 km) and illumination (0.05 percentage points) for 13 January 2025 at 22:27 UTC. An Adelaide USNO fixture checks sunrise, sunset, noon, civil twilight and lunar rise and set events to three minutes. Polar day and night have separate boundary tests. Unit tests also cover Julian epoch, date-range guards, event enumeration, zodiac wraparound and selected IANA transitions. [USNO phase API](https://aa.usno.navy.mil/api/moon/phases/year?year=2025)

All 49 principal phases in each of 2000 and 2050 were also compared
in chronological order against the USNO annual tables. The tests verify
counts, phase names and a 120-second tolerance across both boundary
years. Initial measurements differed by less than 35 seconds from the
minute-resolution Universal Time references. [USNO 2000](https://aa.usno.navy.mil/api/moon/phases/year?year=2000),
[USNO 2050](https://aa.usno.navy.mil/api/moon/phases/year?year=2050)

Production qualification requires position grids against JPL Horizons and events against independent USNO and eclipse tables. Proposed initial tolerances are 0.02° for apparent ecliptic longitude and latitude, 0.5 percentage points for lunar illumination, two minutes for principal phases, and five minutes for eclipse maxima and horizon events. These are acceptance targets, pending broad measurement. Convention matching must include geocentre versus observer, ecliptic of date versus J2000, aberration, timescale, refraction and observer elevation. Test past and future range boundaries and compare native and browser results. [JPL Horizons](https://ssd.jpl.nasa.gov/horizons/)

Calendar fixtures cover all four 2025 seasonal events and sample greatest-eclipse times for the April 2024 solar eclipse and March 2025 lunar eclipse. The tests convert the USNO Eastern civil times to UTC and compare NASA Universal Time predictions at calendar precision, with a three-minute tolerance for both event groups. [USNO 2025 seasons](https://aa.usno.navy.mil/calculated/seasons?dst=true&submit=Get+Data&tz=5&tz_label=true&tz_sign=-1&year=2025), [NASA solar eclipse](https://eclipse.gsfc.nasa.gov/SEbeselm/SEbeselm2001/SE2024Apr08Tbeselm.html), [NASA lunar eclipse](https://eclipse.gsfc.nasa.gov/LEplot/LEplot2001/LE2025Mar14T.pdf)
