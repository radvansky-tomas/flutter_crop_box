import 'package:flutter/material.dart';

class CropBoxBorder {
  final Radius? radius;
  Radius get noNullRaidus => radius ?? Radius.circular(0);

  final double width;

  final Color color;

  CropBoxBorder({this.radius, this.width = 2, this.color = Colors.white});
}
