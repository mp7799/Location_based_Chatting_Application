import 'package:flutter/material.dart';
import 'package:module_group_chat/testScreen.dart';
import 'chat_screen.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TestScreen(),
    routes: {
      ChatScreen.routeName: (context) => ChatScreen(),
    },
  ));
}
