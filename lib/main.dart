import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:poutendance/Screen/profilekey.dart';
import 'package:poutendance/Screen/profileuser.dart';
import 'package:poutendance/Screen/signup.dart';
import 'package:poutendance/firebase_options.dart';
import 'package:poutendance/Screen/Login.dart';
import 'package:poutendance/Screen/qrkey_screen.dart';
import 'package:poutendance/Screen/qrkey_scan.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: SignInScreen(),
    );
  }
}
