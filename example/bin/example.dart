import 'package:dotenv_plus/dotenv_plus.dart';

Future<void> main(List<String> arguments) async {
  final config = await Config.load(
    sources: [EnvFile('.env'), JsonFile('config.json')],
    useInterpolation: true,
    useSectionKeys: true,
  );
  config.section('db').getOrThrow('host');
}
