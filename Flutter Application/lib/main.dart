import 'package:flutter/material.dart';
import 'AuthServices_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'Home_page.dart';
import 'connect_bluetooth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      routes: {
        '/': (context) => AuthServices_page(),
        '/home': (context) => Home_page(),
        '/bluetooth': (context) => ConnectBluetoothPage(),
      },

      initialRoute: '/',
    );
  }
}
