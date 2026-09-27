/// Shared registration codes used to gate account creation.
///
/// Registration is two-tier:
///   1. A BARANGAY code confirms which community the person belongs to.
///   2. A ROLE code (resident/responder) determines their permissions
///      within that community.
///
/// ⚠️ REPLACE THESE PLACEHOLDER VALUES before your beta/demo — anyone with
/// the RESPONDER code can register as a responder, so treat it like a
/// password and only share it with actual barangay officials.
class RegistrationCodes {
  static const String resident = 'OURWATCH-RESIDENT-2026';
  static const String responder = 'OURWATCH-RESPONDER-2026';

  static bool isValidResidentCode(String code) =>
      code.trim() == resident;

  static bool isValidResponderCode(String code) =>
      code.trim() == responder;
}

/// Maps a barangay code to a human-readable barangay name/ID. Add one
/// entry per barangay OurWatch supports. Every account registers under
/// exactly one barangay, confirmed by this code.
class BarangayCodes {
  static const Map<String, String> validCodes = {
    'PARDO-2026': 'Pardo',
    'BRGY001': 'Barangay 1',
    'BRGY002': 'Barangay 2',
    // Add more barangays here as needed
  };

  /// Validates if the entered code exists in the system.
  static bool isValidCode(String code) {
    return validCodes.containsKey(code.trim().toUpperCase());
  }

  /// Resolves the code to a human-readable barangay name.
  static String? getBarangayName(String code) {
    return validCodes[code.trim().toUpperCase()];
  }

  /// Backwards-compatible lookup method.
  static String? resolve(String code) => getBarangayName(code);
}