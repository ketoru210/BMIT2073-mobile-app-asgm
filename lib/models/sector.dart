/// The six GDP sectors published by DOSM (p1..p6).
///
/// Raw API codes are mapped to this enum in exactly one file:
/// `data/sector_mapping.dart`. Pages only ever see this enum, never
/// the raw strings — if DOSM renames a label, one file changes.
enum Sector {
  agriculture('Agriculture'),
  mining('Mining'),
  manufacturing('Manufacturing'),
  construction('Construction'),
  services('Services'),
  importDuties('Import duties');

  const Sector(this.label);

  /// Human-readable label for charts and insight lines.
  final String label;
}
