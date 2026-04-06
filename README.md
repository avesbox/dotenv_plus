# DotEnv Plus

A powerful and flexible configuration loader for Dart, supporting nested keys, type conversion, and variable interpolation.

## Features

- Load configuration from .env files, environment variables, and custom sources.
- Support for nested keys using dot notation (e.g., `DATABASE.HOST`).
- Type conversion for common data types (e.g., int, bool, double).
- Variable interpolation to reference other configuration values (e.g., `API_URL=http://${HOST}:${PORT}`).
- Custom mappers to create complex configuration objects from the loaded values.

## Usage

```dart
import 'package:dotenv_plus/dotenv_plus.dart';

void main() async {
  final config = await Config.load(
    sources: [
      DotEnv('.env'),
      SystemEnv(),
    ],
    builder: (builder) {
      builder.map('DATABASE', (context) {
        return DatabaseConfig(
          host: context.get<String>('DATABASE.HOST'),
          port: context.get<int>('DATABASE.PORT'),
          username: context.get<String>('DATABASE.USERNAME'),
          password: context.get<String>('DATABASE.PASSWORD'),
        );
      });
    },
  );

  print(config.get<String>('API_URL')); // Output: http://localhost:3000
  final dbConfig = config.get<DatabaseConfig>('DATABASE');
  print(dbConfig.host); // Output: localhost
}
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
