extension StringExtensions on String {
  /// Capitalizes the first letter and lowers the rest. Example: "makkah" -> "Makkah"
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';

  /// Converts the string to Title Case (capitalizing the first letter of each word).
  /// Example: "al baqarah" -> "Al Baqarah"
  String toTitleCase() => replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');
}
