import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'database/app_database.dart';
import 'firebase_options.dart';
import 'pages/sample_list_page.dart';
import 'repositories/sample_event_repository.dart';
import 'services/sample_event_remote_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    debugPrint('No se pudo inicializar Firebase: $error');
  }

  final repository = SampleEventRepository(
    database: AppDatabase(),
    remote: SampleEventRemoteService(),
  );

  runApp(SampleTrackApp(repository: repository));
}

class SampleTrackApp extends StatelessWidget {
  const SampleTrackApp({super.key, required this.repository});

  final SampleEventRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SampleTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: SampleListPage(repository: repository),
    );
  }
}
