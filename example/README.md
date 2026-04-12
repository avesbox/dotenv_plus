# dotenv_plus usage

```dart
import 'package:dotenv_plus/dotenv_plus.dart';

void main() async {
  final config = await Config.load(
    sources: [
      DotEnv('.env'),
      SystemEnv(),
    ],
    extensions: [
      return (ConfigBuilder builder) {
        builder.map<ConfigMapper>('db', (ctx) {
          return ConfigMapper.fromKey(ctx.section);
        });
      };
    ]
  );

  print(config.get<String>('API_URL')); // Output: http://localhost:3000
  final dbConfig = config.get<DatabaseConfig>('DATABASE');
  print(dbConfig.host); // Output: localhost
}
```
