# Astronomy

The baseline uses Meeus algorithms and VSOP87B through Astronomia. The configured interval is 2000-01-01 through 2050-12-31 UTC. Positions are apparent geocentric, referenced to the equinox and ecliptic of date. The lunar model adds nutation in longitude and the solar model uses the low-order apparent longitude formula with zero approximated ecliptic latitude. Planetary reductions include light time, aberration, FK5 and nutation. Right ascension is presented in hours and declination in degrees. Distances for the Sun and Moon are shown in kilometres. Daily speed is a central longitude difference over ±0.01 day.

UTC is used as an approximation to UT1. The app applies the Espenak and Meeus piecewise delta-T polynomials to evaluate dynamical ephemerides and convert terrestrial event times back to approximate UTC. Leap-second instants and Earth orientation tables are outside this baseline. [NASA delta-T polynomials](https://eclipse.gsfc.nasa.gov/SEhelp/deltatpoly2004.html)

Moon illumination uses the actual Sun/Moon distance geometry and lunar latitude. Phase labels use nearest 45° elongation sectors, whereas exact phase events use the separate Meeus phase equations. Lunar age is elapsed time since the previous calculated new Moon. The disc represents illumination fraction with a conventional hemisphere selection. Observer position angle and local horizon events remain open.

The calendar applies Meeus phase, eclipse, apsis and seasonal equations, enumerates candidate lunations from seven-day seeds and deduplicates overlapping candidates. Eclipse times denote global estimated maximum. Local contacts and visibility are pending. Calendar windows filter UTC events against civil date boundaries in the display zone.
