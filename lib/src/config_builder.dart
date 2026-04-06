class ConfigContext {
  /// The current section (already scoped)
  final Map<String, dynamic> section;

  final Map<String, dynamic> _definedObjects;

  final bool _useSectionKeys;

  final String _sectionSeparator;

  const ConfigContext(
    this.section,
    this._definedObjects,
    this._useSectionKeys,
    this._sectionSeparator,
  );

  /// Get another mapped config (lazy + cached)
  T getOrThrow<T>(String key) {
    if (_definedObjects.containsKey(key)) {
      final factory = _definedObjects[key]!;
      if (factory is T) {
        return factory;
      }
      throw Exception(
        'Mapped config for key $key is not of type ${T.runtimeType}',
      );
    } else {
      throw Exception('Missing mapped config key: $key');
    }
  }

  /// Same as get, but returns null if missing
  T? get<T>(String key) {
    try {
      return getOrThrow<T>(key);
    } on Exception {
      return null;
    }
  }

  /// Read a raw value (dot notation supported)
  T getValueOrThrow<T>(String path) {
    return _getValueFromPath<T>(path, section) ??
        (throw Exception('Missing config key: $path'));
  }

  /// Safe version of getValue
  T? getValue<T>(String path) {
    return _getValueFromPath<T>(path, section);
  }

  T? _getValueFromPath<T>(String path, Map<String, dynamic> config) {
    if (_useSectionKeys) {
      final parts = path.split(_sectionSeparator);
      var currentSection = section;
      for (var i = 0; i < parts.length - 1; i++) {
        final part = parts[i];
        if (currentSection[part] is Map<String, dynamic>) {
          currentSection = currentSection[part] as Map<String, dynamic>;
        } else {
          return null;
        }
      }
      return currentSection[parts.last] as T?;
    } else {
      return section[path] as T?;
    }
  }

  /// Check existence (raw or mapped)
  bool has(String path) {
    return getValue(path) != null || _definedObjects.containsKey(path);
  }
}

typedef ConfigFactory<T> = T Function(ConfigContext context);

class ConfigBuilder {
  final _factories = <String, ConfigFactory>{};

  Map<String, ConfigFactory> get factories => Map.unmodifiable(_factories);

  void map<T>(String key, ConfigFactory<T> factory) {
    _factories[key] = factory;
  }
}
