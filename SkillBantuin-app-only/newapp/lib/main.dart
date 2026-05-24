import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/providers.dart';
import 'screens/splash_screen.dart';
import 'services/realtime_service.dart';
import 'utils/language_notifier.dart';
import 'widgets/app_theme.dart';
import 'widgets/language_builder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageNotifier.instance.init();
  runApp(const SkillBantuinApp());
}

class SkillBantuinApp extends StatelessWidget {
  const SkillBantuinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Core ─────────────────────────────────────────────────
        // Auth — harus paling atas agar provider lain bisa read
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),

        // ── Feature Providers ─────────────────────────────────────
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => FreelancerProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),

        // ── Offer ─────────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => OfferProvider()),

        // ── Notifikasi ────────────────────────────────────────────
        // NotificationProvider: mengelola list & unread count
        ChangeNotifierProvider(create: (_) => NotificationProvider()),

        // ── Realtime Polling ──────────────────────────────────────
        // RealtimeService membaca NotificationProvider melalui ProxyProvider
        // sehingga unread notif di-inject saat service di-create.
        //
        // Catatan: startPolling() harus dipanggil setelah login berhasil,
        // biasanya di AuthProvider.init() atau di screen pasca-login.
        ChangeNotifierProxyProvider<NotificationProvider, RealtimeService>(
          create: (_) => RealtimeService(),
          update: (ctx, notifProvider, realtimeSvc) {
            // Inject NotificationProvider ke RealtimeService supaya polling
            // notifikasi berjalan tanpa circular dependency.
            realtimeSvc!.injectNotificationProvider(notifProvider);
            return realtimeSvc;
          },
        ),
      ],
      child: LanguageBuilder(
        builder: (context, lang) => MaterialApp(
          title: 'SkillBantuin',
          theme: buildAppTheme(),
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}