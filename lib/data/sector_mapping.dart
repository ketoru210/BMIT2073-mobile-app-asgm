import '../models/sector.dart';

/// Maps raw DOSM sector codes (p1..p6) to the frozen [Sector] enum.
///
/// This is the ONE file that changes if DOSM ever renames a code.
/// `p0` (total GDP) is not a sector — the repository handles it.
Sector? sectorFromCode(String code) {
  switch (code) {
    case 'p1':
      return Sector.agriculture;
    case 'p2':
      return Sector.mining;
    case 'p3':
      return Sector.manufacturing;
    case 'p4':
      return Sector.construction;
    case 'p5':
      return Sector.services;
    case 'p6':
      return Sector.importDuties;
    default:
      return null; // p0 or unknown
  }
}

/// Raw code for [sector], e.g. Sector.manufacturing -> `p3`.
String sectorCode(Sector sector) {
  switch (sector) {
    case Sector.agriculture:
      return 'p1';
    case Sector.mining:
      return 'p2';
    case Sector.manufacturing:
      return 'p3';
    case Sector.construction:
      return 'p4';
    case Sector.services:
      return 'p5';
    case Sector.importDuties:
      return 'p6';
  }
}
