import 'sector.dart';

/// One cleaned data row: state x sector x year.
///
/// [value] is RM million at constant 2015 prices and may be null —
/// the source has one missing cell (W.P. Putrajaya manufacturing 2023).
/// [growthYoy] is real year-on-year growth in percent; the source only
/// publishes it for the 13 states from 2016 onwards, so it is nullable.
class GdpRecord {
  const GdpRecord({
    required this.state,
    required this.sector,
    required this.year,
    this.value,
    this.growthYoy,
  });

  final String state;
  final Sector sector;
  final int year;
  final double? value;
  final double? growthYoy;
}
