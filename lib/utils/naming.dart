/// Name-casing helpers shared by every generator so that file names, class
/// names, and route constants are derived consistently from a single input.
///
/// Input may be `snake_case`, `camelCase`, `PascalCase`, `kebab-case`, or
/// `space separated` — all are normalized to a list of lowercase words first.
class Naming {
  Naming._();

  /// Splits an arbitrary identifier into its lowercase component words.
  static List<String> _words(String input) {
    final spaced = input
        // insert a separator between a lower/upper boundary: fooBar -> foo Bar
        .replaceAllMapped(
            RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        // any run of separators becomes a single space
        .replaceAll(RegExp(r'[_\-\s]+'), ' ')
        .trim();
    if (spaced.isEmpty) return const [];
    return spaced.split(' ').map((w) => w.toLowerCase()).toList();
  }

  /// `my_cool_page` -> `my_cool_page` (the canonical file/folder form).
  static String snake(String input) => _words(input).join('_');

  /// `my_cool_page` -> `MyCoolPage` (class names, types).
  static String pascal(String input) => _words(input).map(_capitalize).join();

  /// `my_cool_page` -> `myCoolPage` (variables, route names, providers).
  static String camel(String input) {
    final words = _words(input);
    if (words.isEmpty) return '';
    return words.first + words.skip(1).map(_capitalize).join();
  }

  /// `my_cool_page` -> `My Cool Page` (titles, prompts, AppBar labels).
  static String title(String input) => _words(input).map(_capitalize).join(' ');

  static String _capitalize(String word) =>
      word.isEmpty ? word : word[0].toUpperCase() + word.substring(1);
}
