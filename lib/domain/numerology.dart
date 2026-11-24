class Numerology {
  const Numerology({required this.keepMasterNumbers});
  final bool keepMasterNumbers;

  int reduce(int value) {
    while (value > 9) {
      if (keepMasterNumbers && const {11, 22, 33}.contains(value)) return value;
      value = value.toString().codeUnits.fold(
        0,
        (sum, digit) => sum + digit - 48,
      );
    }
    return value;
  }

  int universalYear(DateTime day) => reduce(day.year);
  int universalMonth(DateTime day) => reduce(universalYear(day) + day.month);
  int universalDay(DateTime day) => reduce(universalMonth(day) + day.day);
  int personalYear(DateTime day, DateTime birth) =>
      reduce(universalYear(day) + reduce(birth.month) + reduce(birth.day));
  int personalMonth(DateTime day, DateTime birth) =>
      reduce(personalYear(day, birth) + day.month);
  int personalDay(DateTime day, DateTime birth) =>
      reduce(personalMonth(day, birth) + day.day);
  int lifePath(DateTime birth) =>
      reduce(reduce(birth.year) + reduce(birth.month) + reduce(birth.day));
}
