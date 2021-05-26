import 'package:flutter/material.dart';
import 'package:my_audio_player_project/screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Congenial Octo Eureka',
      theme: ThemeData(
        primaryColor: Color(0xff38726C),
        accentColor: Color(0xffD34E24),
        //primarySwatch: Color(0xff38726C),
      ),
      home: HomeScreen(),
    );
  }
}
