import 'package:dotenv_plus/src/config_source.dart';
import 'package:dotenv_plus/src/converter.dart';

/// Core configuration class that loads and manages configuration values from multiple sources.
typedef ConfigValidationSchema =
    Map<String, dynamic> Function(Map<String, dynamic> values);

final _interpolationRegex = RegExp(r'\$\{([^}]+)\}');

/// Core configuration class that loads and manages configuration values from multiple sources.
final class Config {
  final Map<String, dynamic> _config;

  /// Returns an unmodifiable view of the loaded configuration values.
  Map<String, dynamic> get values => Map.unmodifiable(_config);

  static final Converter _converter = const Converter();

  /// Creates a new Config instance by loading configuration values from the specified sources.
  Config._(this._config);

  /// Loads configuration values from the specified sources and returns a Config instance.
  static Future<Config> load({
    required List<ConfigSource> sources,
    String? sectionSeparator = '.',
    bool useInterpolation = false,
    bool useSectionKeys = false,
    ConfigValidationSchema? schema,
  }) async {
    final tempConfig = <String, dynamic>{};

    // Load all sources
    for (final source in sources) {
      final loadedConfig = await source.load();
      tempConfig.addAll(loadedConfig);
    }

    final interpolationStack = <String, String>{};

    // Step 1: Remove quotes from string values
    for (final entry in tempConfig.entries) {
      var value = entry.value;

      if (value is String) {
        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.substring(1, value.length - 1);
        } else if (value.startsWith("'") && value.endsWith("'")) {
          value = value.substring(1, value.length - 1);
        }
        tempConfig[entry.key] = value;
      }

      if (useInterpolation) {
        if (value is String) {
          if (_interpolationRegex.hasMatch(value)) {
            interpolationStack[entry.key] = value;
          }
        }
      }
    }

    if (useSectionKeys) {
      final separator = sectionSeparator ?? '.';
      for (final entry in [...tempConfig.entries]) {
        if (entry.key.contains(separator)) {
          final parts = entry.key.split(separator);
          var currentMap = tempConfig;
          for (int i = 0; i < parts.length - 1; i++) {
            final part = parts[i];
            if (currentMap[part] == null) {
              currentMap[part] = <String, dynamic>{};
            } else if (currentMap[part] is! Map<String, dynamic>) {
              throw Exception(
                'Config key "${entry.key}" conflicts with existing non-map value at section "$part"',
              );
            }
            currentMap = currentMap[part] as Map<String, dynamic>;
          }
          final lastPart = parts.last;
          if (currentMap.containsKey(lastPart)) {
            throw Exception(
              'Config key "${entry.key}" conflicts with existing value at "$lastPart"',
            );
          }
          currentMap[lastPart] = entry.value;
          tempConfig.remove(entry.key);
        }
      }
    }

    final config = <String, dynamic>{};

    for (final entry in interpolationStack.entries) {
      final interpolatedValue = _interpolate(
        entry.value,
        tempConfig,
        useSectionKeys,
        sectionSeparator: sectionSeparator,
      );
      if (useSectionKeys && entry.key.contains(sectionSeparator ?? '.')) {
        final parts = entry.key.split(sectionSeparator ?? '.');
        var sectionConfig = tempConfig;
        for (int i = 0; i < parts.length - 1; i++) {
          final part = parts[i];
          if (sectionConfig[part] == null) {
            sectionConfig[part] = <String, dynamic>{};
          } else if (sectionConfig[part] is! Map<String, dynamic>) {
            throw Exception(
              'Interpolation error: section "$part" not found for variable "${entry.key}"',
            );
          }
          sectionConfig = sectionConfig[part] as Map<String, dynamic>;
        }
        final key = parts.last;
        sectionConfig[key] = _converter.convertValue(interpolatedValue);
      } else {
        tempConfig[entry.key] = _converter.convertValue(interpolatedValue);
      }
    }

    config.addAll(tempConfig);

    // Step 4: Apply schema validation if provided
    if (schema != null) {
      final validatedConfig = schema(config);
      return Config._(validatedConfig);
    }

    return Config._(config);
  }

  static String _interpolate(
    String value,
    Map<String, dynamic> config,
    bool useSectionKeys, {
    String? sectionSeparator,
  }) {
    final results = _interpolationRegex.allMatches(value);
    for (int i = 0; i < results.length; i++) {
      final match = results.elementAt(i);
      final varName = match.group(1)!;
      String replacement;
      if (useSectionKeys && varName.contains(sectionSeparator ?? '.')) {
        final parts = varName.split(sectionSeparator ?? '.');
        var sectionConfig = config;
        for (int i = 0; i < parts.length - 1; i++) {
          final part = parts[i];
          if (sectionConfig[part] is Map<String, dynamic>) {
            sectionConfig = sectionConfig[part] as Map<String, dynamic>;
          } else {
            throw Exception(
              'Interpolation error: section "$part" not found for variable "$varName"',
            );
          }
        }
        final key = parts.last;
        replacement = sectionConfig[key]?.toString() ?? '';
      } else {
        replacement = config[varName]?.toString() ?? '';
      }
      value = value.replaceFirst(match.group(0)!, replacement);
    }
    return value;
  }

  /// Retrieves the value associated with the specified key and casts it to the expected type [T].
  /// If the key is not found and a [fallbackValue] is provided, it returns the [fallbackValue]. If the key is not found and no [fallbackValue] is provided, it throws an exception.
  /// If the key is found but the value cannot be cast to type [T], it throws an exception
  T getOrThrow<T>(String key, {T? fallbackValue}) {
    if (!_config.containsKey(key)) {
      if (fallbackValue != null) {
        return fallbackValue;
      }
      throw Exception('Required config key not found: $key');
    }
    final value = _config[key];
    if (value is! T) {
      throw Exception(
        'Config key "$key" has invalid type. Expected: $T, Found: ${value.runtimeType}',
      );
    }
    return value;
  }

  /// Retrieves the value associated with the specified key and casts it to the expected type [T]. If the key is not found, it returns null.
  /// If the key is found but the value cannot be cast to type [T], it throws an exception.
  T? get<T>(String key) {
    if (!_config.containsKey(key)) {
      return null;
    }
    final value = _config[key];
    if (value is! T) {
      throw Exception(
        'Config key "$key" has invalid type. Expected: $T, Found: ${value.runtimeType}',
      );
    }
    return value;
  }

  /// Retrieves a nested Config section based on the specified [sectionKey].
  /// The section is expected to be a map of key-value pairs.
  /// If the section is not found or is not a valid map, it throws an exception.
  Config section(String sectionKey) {
    final sectionValue = _config[sectionKey];
    if (sectionValue is! Map<String, dynamic>) {
      throw Exception(
        'Config section "$sectionKey" is not a valid map. Found: ${sectionValue.runtimeType}',
      );
    }
    return Config._(sectionValue);
  }
}
