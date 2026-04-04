import 'package:dotenv_plus/dotenv_plus.dart';
import 'package:test/test.dart';

class TestConfigSource implements ConfigSource {
  final Map<String, dynamic> _data;

  TestConfigSource(this._data);

  @override
  Future<Map<String, dynamic>> load() async {
    return _data;
  }
}

void main() {
  test('Loads config from multiple sources', () async {
    final config = await Config.load(
      sources: [
        TestConfigSource({'env_key': 'env_value'}),
        TestConfigSource({'json_key': 'json_value'}),
      ],
    );

    expect(config.values['env_key'], 'env_value');
    expect(config.values['json_key'], 'json_value');
  });

  test('Supports interpolation', () async {
    final config = await Config.load(
      sources: [
        TestConfigSource({
          'env_key': 'env_value',
          'interpolated': '\${env_key}',
        }),
      ],
      useInterpolation: true,
    );

    expect(config.values['interpolated'], 'env_value');
  });

  test('Supports section keys', () async {
    final config = await Config.load(
      sources: [
        TestConfigSource({'db.host': 'localhost'}),
      ],
      useSectionKeys: true,
    );

    expect(config.section('db').getOrThrow('host'), 'localhost');
  });

  test('Supports section keys and interpolation', () async {
    final config = await Config.load(
      sources: [
        TestConfigSource({'db.host': 'localhost', 'db.port': '\${db.host}'}),
      ],
      useSectionKeys: true,
      useInterpolation: true,
    );

    expect(config.section('db').getOrThrow('port'), 'localhost');
  });

  test('Supports section keys with custom separator', () async {
    final config = await Config.load(
      sources: [
        TestConfigSource({'db_host': 'localhost'}),
      ],
      useSectionKeys: true,
      sectionSeparator: '_',
    );

    expect(config.section('db').getOrThrow('host'), 'localhost');
  });

  test('Throws error on invalid section key format', () async {
    expect(
      () async => await Config.load(
        sources: [
          TestConfigSource({'db.host': 'localhost', 'db': 'conflict'}),
        ],
        useSectionKeys: true,
      ),
      throwsException,
    );
  });

  test('Schema validation throws exception', () async {
    expect(
      () async => await Config.load(
        sources: [
          TestConfigSource({'port': 'not_a_number'}),
        ],
        schema: (values) {
          if (values['port'] is! int) {
            throw Exception('Port must be an integer');
          }
          return values;
        },
      ),
      throwsException,
    );
  });
}
