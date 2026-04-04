import 'dart:convert';
import 'dart:io';

import 'package:dotenv_plus/src/parser.dart';

/// Core configuration class that loads and manages configuration values from multiple sources.
abstract class ConfigSource {
  const ConfigSource();

  /// Loads configuration values from this source and returns them as a map.
  Future<Map<String, dynamic>> load();
}

/// A ConfigSource that loads configuration from a .env file.
/// The .env file should contain key-value pairs in the format `KEY=VALUE`, with optional comments starting with `#`.
/// Example .env file:
/// ```env
/// # Database configuration
/// db.host=localhost
/// db.port=5432
/// db.user=admin
/// db.password=secret
/// ```
class EnvFile implements ConfigSource {
  final String _path;

  const EnvFile(this._path);

  @override
  Future<Map<String, dynamic>> load() async {
    final file = File(_path);
    if (!await file.exists()) {
      throw Exception('Config file not found: $_path');
    }
    final lines = await file.readAsLines();
    final parser = DotEnvParser();
    final config = parser.parse(lines);
    return config;
  }
}

/// A ConfigSource that loads configuration from the system environment variables.
class SystemEnv implements ConfigSource {
  @override
  Future<Map<String, dynamic>> load() async {
    return Platform.environment;
  }
}

/// A ConfigSource that loads configuration from a JSON file.
/// The JSON file should contain a flat key-value structure, where values can be strings, numbers, booleans, or null.
/// Example JSON file:
/// ```json
/// {
/// "db.host": "localhost",
/// "db.port": 5432
/// }
class JsonFile implements ConfigSource {
  static final _jsonUtf8Decoder = utf8.decoder.fuse(json.decoder);

  final String _path;

  const JsonFile(this._path);

  @override
  Future<Map<String, dynamic>> load() async {
    final file = File(_path);
    if (!await file.exists()) {
      throw Exception('Config file not found: $_path');
    }
    final content = file.readAsBytesSync();
    if (content.isEmpty) {
      return {};
    }
    final decoded = _jsonUtf8Decoder.convert(content);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid config format in file: $_path');
    }
    return decoded;
  }
}
