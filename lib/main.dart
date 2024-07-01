import 'package:drinking_with_jenga/pages/add_and_edit.dart';
import 'package:drinking_with_jenga/pages/versions.dart';
import 'package:drinking_with_jenga/pages/loading.dart';
import 'package:drinking_with_jenga/pages/home.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(MaterialApp(
    initialRoute: '/loading',
    routes: {
      '/home': (context) => Home(),
      '/loading': (context) => Loading(),
      '/versions': (context) => Versions(),
      '/add_and_edit': (context) => AddAndEdit(),
    },
  ));
}