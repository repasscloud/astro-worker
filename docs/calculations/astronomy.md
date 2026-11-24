# Astronomy

The baseline uses Meeus algorithms and VSOP87B through Astronomia. The configured interval is 2000-01-01 through 2050-12-31 UTC. Positions are apparent geocentric, referenced to the equinox and ecliptic of date. The lunar model adds nutation in longitude and the solar model uses the low-order apparent longitude formula with zero approximated ecliptic latitude. Planetary reductions include light time, aberration, FK5 and nutation. Right ascension is presented in hours and declination in degrees. Distances for the Sun and Moon are shown in kilometres. Daily speed is a central longitude difference over ±0.01 day.

UTC is used as an approximation to UT1. The app applies the Espenak and Meeus piecewise delta-T polynomials to evaluate dynamical ephemerides and convert terrestrial event times back to approximate UTC. Leap-second instants and Earth orientation tables are outside this baseline. [NASA delta-T polynomials](https://eclipse.gsfc.nasa.gov/SEhelp/deltatpoly2004.html)

Moon illumination uses the actual Sun/Moon distance geometry and lunar latitude. Phase labels use nearest 45° elongation sectors, whereas exact phase events use the separate Meeus phase equations. Lunar age is elapsed time since the previous calculated new Moon. The disc represents illumination fraction with a conventional hemisphere selection. Observer position angle and local horizon events remain open.

The calendar applies Meeus phase, eclipse, apsis and seasonal equations, enumerates candidate lunations from seven-day seeds and deduplicates overlapping candidates. Eclipse times denote global estimated maximum. Local contacts and visibility are pending. Calendar windows filter UTC events against civil date boundaries in the display zone.

## Horizon events

Users can enter decimal latitude and east-positive longitude. The selected display timezone defines the civil-day interval, including daylight-saving changes. The engine converts apparent geocentric equatorial coordinates to altitude, brackets threshold crossings on a five-minute grid and refines them to one second. At shallow or grazing crossings, threshold geometry and sampling limit precision.

Sunrise and sunset use a −50 arcminute solar centre threshold. Civil, nautical and astronomical twilight use −6°, −12° and −18°. Moonrise and moonset use distance-dependent parallax and a conventional 34 arcminute atmospheric correction. Solar noon is the refined maximum altitude in the civil interval. Mountains, weather, elevation and observer-dependent lunar orientation are outside this implementation. Missing events are represented explicitly and daylight is clipped to the civil interval.

The Moon screen lists perigee and apogee alongside its phase history. With an observer location, the disc rotates its illuminated limb relative to the local zenith using apparent geocentric Sun and Moon coordinates. Without a location, or when the zenith direction is undefined, it uses the selected hemisphere schematic. The observer display is approximate because it uses geocentric directions for the limb geometry. [U.S. Naval Observatory limb methods](https://aa.usno.navy.mil/downloads/reports/Tayloretal2011.pdf)

The traditional void-of-course feature uses the last exact major lunar aspect before the next sign ingress in the chosen zodiac. The classical option includes the Sun and Mercury through Saturn. The extended option also includes Uranus and Neptune. If the Moon makes no major aspect in a sign, the window starts at the previous ingress. The app shows this separately from lunar observations and honours the spiritual visibility setting.

The January 2025 reference fixtures check the bright-limb position angle and apsides. Geocentric Ephemeris for the Sun, Moon and Planets Courtesy of Fred Espenak, www.Astropixels.com. [2025 lunar ephemeris](https://www.astropixels.com/ephemeris/moon/moon2025.html), [2025 Sky Event Almanac](https://astropixels.com/almanac/almanac21/almanac2025gmt.html)
