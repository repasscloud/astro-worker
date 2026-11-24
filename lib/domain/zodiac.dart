enum Zodiac {
  tropical('Tropical'),
  lahiri('Sidereal · Lahiri'),
  faganBradley('Sidereal · Fagan–Bradley');

  const Zodiac(this.label);

  final String label;

  /// Mean ayanamsa using the IAU 2006 longitude precession polynomial.
  double offset(DateTime instant) => switch (this) {
    tropical => 0,
    lahiri => 23 + 51 / 60 + 25.5324 / 3600 + _precession(instant),
    faganBradley =>
      24 +
          2 / 60 +
          31.36 / 3600 +
          _precession(instant) -
          _precession(DateTime.utc(1950)),
  };

  static double _precession(DateTime instant) {
    final days =
        instant.difference(DateTime.utc(2000, 1, 1, 12)).inMilliseconds /
        86400000;
    final t = days / 36525;
    return t *
        (5028.796195 +
            t *
                (1.1054348 +
                    t * (0.00007964 + t * (-0.000023857 - t * 0.0000000383)))) /
        3600;
  }
}
