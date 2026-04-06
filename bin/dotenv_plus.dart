import 'package:dotenv_plus/dotenv_plus.dart';

class ConfigMapper {
  final String host;

  final int port;

  final String user;

  final String password;

  ConfigMapper(this.host, this.port, this.user, this.password);

  factory ConfigMapper.fromKey(Map<String, dynamic> config) {
    return ConfigMapper(
      config['host'] as String,
      config['port'] as int,
      config['user'] as String,
      config['password'].toString(),
    );
  }

  static ConfigExtension register() {
    return (ConfigBuilder builder) {
      builder.map<ConfigMapper>('db', (ctx) {
        return ConfigMapper.fromKey(ctx.section);
      });
    };
  }
}

Future<void> main(List<String> arguments) async {
  final config = await Config.load(
    sources: [EnvFile('.env'), JsonFile('config.json')],
    useInterpolation: true,
    useSectionKeys: true,
    extensions: [ConfigMapper.register()],
  );
  print(config.values);
  print(config.getOrThrow<Map<String, dynamic>>('db')['host']);
}
