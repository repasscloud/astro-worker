/// Return the first known instant at or after a bracketed transition.
DateTime refineEvent(
  DateTime left,
  DateTime right,
  bool Function(DateTime) after,
) {
  while (right.difference(left) > const Duration(seconds: 1)) {
    final mid = left.add(
      Duration(microseconds: right.difference(left).inMicroseconds ~/ 2),
    );
    if (after(mid)) {
      right = mid;
    } else {
      left = mid;
    }
  }
  return right;
}
