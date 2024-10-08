import 'package:eco_bites/core/config/theme.dart';
import 'package:eco_bites/core/ui/layouts/main_layout.dart';
import 'package:eco_bites/core/utils/create_text_theme.dart';
import 'package:eco_bites/features/address/presentation/screens/address_screen.dart';
import 'package:eco_bites/features/auth/presentation/screens/login_screen.dart';
import 'package:eco_bites/features/auth/presentation/screens/register_screen.dart';
import 'package:eco_bites/features/splash/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyApp extends StatelessWidget {

  const MyApp({super.key, required this.appLaunchTime});

  final DateTime appLaunchTime;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness =
        View.of(context).platformDispatcher.platformBrightness;

    // Use with Google Fonts package to use downloadable fonts
    final TextTheme textTheme = createTextTheme(context, 'Roboto', 'Roboto');

    final MaterialTheme theme = MaterialTheme(textTheme);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor:
            Brightness.light == brightness ? Colors.white : Colors.black,
        systemNavigationBarIconBrightness:
            Brightness.light == brightness ? Brightness.dark : Brightness.light,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.light == brightness ? Brightness.dark : Brightness.light,
      ),
    );
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eco Bites',
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => SplashScreen(appLaunchTime: appLaunchTime),
        '/main': (BuildContext context) => MainLayout(appLaunchTime: appLaunchTime),
        '/login': (BuildContext context) => const LoginScreen(),
        '/register': (BuildContext context) => const RegisterScreen(),
        '/address': (BuildContext context) => const AddressScreen(),
      },
    );
  }
}
