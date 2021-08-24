import 'dart:typed_data';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:flutter/material.dart';

class ImageResultPage extends StatefulWidget {
  final Uint8List imageBytes;
  ImageResultPage({Key? key, required this.imageBytes}) : super(key: key);

  @override
  _ImageResultPageState createState() => _ImageResultPageState();
}

class _ImageResultPageState extends State<ImageResultPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Result'),
      ),
      body: Center(
        child: Container(
          width: 80.0.w,
          child: Image.memory(
            widget.imageBytes,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
