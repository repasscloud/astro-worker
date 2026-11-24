import 'package:flutter/material.dart';

enum Destination {
  today('Today', Icons.auto_awesome_outlined),
  moon('Moon', Icons.brightness_3_outlined),
  planets('Planets', Icons.public),
  calendar('Calendar', Icons.calendar_month_outlined),
  astrology('Astrology', Icons.explore_outlined),
  numerology('Numerology', Icons.numbers),
  spiritual('Spiritual', Icons.spa_outlined),
  widgets('Widgets', Icons.widgets_outlined),
  settings('Settings', Icons.settings_outlined);

  const Destination(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum MoonSection { phase, reflection, colour, calendar }
