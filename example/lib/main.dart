import 'package:example/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_sizer/flutter_sizer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primaryColor: Color(0xff44D7B6),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: FlutterSizer(builder: (context, orientation, screenType) {
          return PageIndex();
        }));
  }
}
