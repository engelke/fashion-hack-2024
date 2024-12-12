import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'widgets/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "AIzaSyBxGXe52FxSSqPqoC6J9Y47DzulYmcjJ-E",
        authDomain: "fashion-hack-2024.firebaseapp.com",
        projectId: "fashion-hack-2024",
        storageBucket: "fashion-hack-2024.appspot.com",
        messagingSenderId: "1096125721547",
        appId: "1:1096125721547:web:b1e2f2f2f2f2f2f2f2f2f2"),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fashion Hack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
