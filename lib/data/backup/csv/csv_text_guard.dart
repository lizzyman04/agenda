// CSV formula-injection guard (CWE-1236).
//
// A spreadsheet executes a cell that starts with = + - @ tab or CR. Export
// neutralises such text with ONE leading apostrophe; import removes exactly
// the apostrophe the export could have added. The pair is lossless for every
// string, including text that already begins with an apostrophe.

const String _apostrophe = "'";
const Set<String> _dangerousLeads = {'=', '+', '-', '@', '\t', '\r'};

/// True when [s] would be interpreted as a formula, or begins with an
/// apostrophe followed by something that would be (so that [unguardCsvText]
/// can tell a guard apostrophe from a literal one).
bool needsCsvGuard(String s) {
  if (s.isEmpty) return false;
  final lead = s[0];
  if (_dangerousLeads.contains(lead)) return true;
  return lead == _apostrophe && needsCsvGuard(s.substring(1));
}

/// Prefixes one apostrophe when [s] needs it.
String guardCsvText(String s) => needsCsvGuard(s) ? '$_apostrophe$s' : s;

/// Removes one leading apostrophe exactly when the remainder needs the guard.
String unguardCsvText(String s) =>
    s.startsWith(_apostrophe) && needsCsvGuard(s.substring(1))
        ? s.substring(1)
        : s;
