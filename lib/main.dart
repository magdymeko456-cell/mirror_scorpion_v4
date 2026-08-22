import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'app/mirror_scorpion_app.dart';
import 'core/pro/premium_verification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final premiumService = PremiumVerificationService();
  await premiumService.initialize();
  runApp(
    ChangeNotifierProvider.value(
      value: premiumService,
      child: const MirrorScorpionApp(),
    ),
  );
}
