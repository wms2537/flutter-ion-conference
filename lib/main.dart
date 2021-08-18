import 'package:flutter/material.dart';
import 'package:flutter_ion_conference/providers/ion.dart';
import 'package:flutter_ion_conference/screens/chat_screen.dart';
import 'package:flutter_ion_conference/screens/home_screen.dart';
import 'package:flutter_ion_conference/screens/meeting_screen.dart';
import 'package:flutter_ion_conference/screens/settings_page.dart';
import 'package:flutter_ion_conference/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'configure_nonweb.dart' if (dart.library.html) 'configure_web.dart';

void main() {
  configureApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<IonController>(
            create: (_) => IonController()..init(),
          ),
        ],
        child: Consumer<IonController>(
          builder: (ctx, controller, _) => MaterialApp(
            title: 'Ion Conference',
            theme: ThemeData(
                primaryColor: Colors.pink.shade200,
                fontFamily: 'Lato',
                colorScheme: ColorScheme.light(
                    primary: Colors.pink,
                    secondary: Colors.cyanAccent.shade700)),
            home: FutureBuilder(
              future: controller.init(),
              builder: (context, snapshot) =>
                  snapshot.connectionState == ConnectionState.waiting
                      ? const SplashScreen()
                      : const HomeScreen(),
            ),
            routes: {
              HomeScreen.routeName: (ctx) => const HomeScreen(),
              MeetingScreen.routeName: (ctx) => const MeetingScreen(),
              ChatScreen.routeName: (ctx) => const ChatScreen(),
              SettingsScreen.routeName: (ctx) => const SettingsScreen(),
            },
          ),
        ));
  }
}
