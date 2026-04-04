import 'package:dotenv_plus/src/converter.dart';

/// A simple parser for .env files that supports basic key-value pairs, comments, and optional interpolation.
final class DotEnvParser {
  final Converter _converter = const Converter();

  /// Creates a new instance of the DotEnvParser.
  const DotEnvParser();

  /// Parses the given list of lines from a .env file and returns a map of configuration values.
  Map<String, dynamic> parse(List<String> lines) {
    final config = <String, dynamic>{};

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
        continue; // Skip empty lines and comments
      }

      final separatorIndex = trimmedLine.indexOf('=');
      if (separatorIndex == -1) {
        continue; // Skip lines that don't contain '='
      }

      var key = trimmedLine.substring(0, separatorIndex).trim();

      var value = trimmedLine.substring(separatorIndex + 1).trim();
      if (value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      } else if (value.startsWith("'") && value.endsWith("'")) {
        value = value.substring(1, value.length - 1);
      }

      config[key] = _converter.convertValue(value);
    }

    return config;
  }
}
