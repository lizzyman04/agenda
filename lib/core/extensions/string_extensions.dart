/// String convenience extensions used across layers.
extension StringExtensions on String {
  /// True when the string is empty after trimming whitespace.
  bool get isBlank => trim().isEmpty;

  /// Returns the string with its first character uppercased.
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

/// Nullable String convenience extensions.
extension NullableStringExtensions on String? {
  /// True when the string is null or empty after trimming.
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;
}
