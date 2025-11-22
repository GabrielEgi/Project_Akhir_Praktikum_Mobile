import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.username});
  final String username;

  @override
  State <MainScreen> createState() =>  MainScreenState();
}

class  MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}