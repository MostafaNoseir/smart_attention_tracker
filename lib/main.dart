// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart'; // الملف اللي اتعمل من الـ CLI
// import 'screens/login_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   // السطرين دول أساسيين عشان فايربيز يشتغل على الديسكتوب
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
  
//   runApp(const SmartTrackerApp());
// }

// class SmartTrackerApp extends StatelessWidget {
//   const SmartTrackerApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Attention Tracker MVP',
//       theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Arial'),
//       home: const LoginScreen(),
//     );
//   }
// }
///////////////////////////////////////
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:smart_attention_tracker/cubits/auth_cubit/auth_cubit.dart';
// import 'firebase_options.dart';
// import 'views/auth/login_view.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   runApp(const SmartTrackerApp());
// }

// class SmartTrackerApp extends StatelessWidget {
//   const SmartTrackerApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider(create: (context) => AuthCubit()),
//         // هنحط الـ TrackerCubit هنا لما نعمله
//       ],
//       child: MaterialApp(
//         debugShowCheckedModeBanner: false,
//         title: 'Attention Tracker',
//         theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Arial'),
//         home: LoginView(),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:eye_focus/firebase_options.dart';
import 'package:window_manager/window_manager.dart';
import 'theme/app_theme.dart';
import 'services/router.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

//   await windowManager.ensureInitialized();
//   await windowManager.setMinimumSize(const Size(1200, 700));
//   await windowManager.setSize(const Size(1440, 900));
//   await windowManager.setTitle('EyeFocus — Eye Tracking & Attention Analysis');
//   await windowManager.center();
//   await windowManager.show();

//   runApp(const ProviderScope(child: EyeFocusApp()));
// }

class EyeFocusApp extends ConsumerWidget {
  const EyeFocusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'EyeFocus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: router,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 700),
      minimumSize: Size(1000, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal, // <--- Ensure this is 'normal'
      title: 'EyeFocus — Eye Tracking & Attention Analysis',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: EyeFocusApp()));
}