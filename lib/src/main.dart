library crop_box;

import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'box_border.dart';
import 'grid_line.dart';

enum CropBoxType { Square, Circle }

typedef _CropRectUpdate = void Function(Rect rect);

class CropBox extends StatefulWidget {
  final Rect? cropRect;
  final Size clipSize;
  final Widget child;
  final Size? cropRatio;
  final Size? maxCropSize;
  final double maxScale;
  final Function? cropRectUpdateStart;
  final _CropRectUpdate? cropRectUpdate;
  final _CropRectUpdate cropRectUpdateEnd;
  final CropBoxType cropBoxType;
  final bool needInnerBorder;
  final GridLine? gridLine;
  final CropBoxBorder? cropBoxBorder;
  final Color? backgroundColor;
  final Color? maskColor;

  CropBox(
      {this.cropRect,
      required this.clipSize,
      required this.child,
      required this.cropRectUpdateEnd,
      this.cropRectUpdateStart,
      this.cropRectUpdate,
      this.cropRatio,
      this.maxCropSize,
      this.maxScale = 10.0,
      this.cropBoxType = CropBoxType.Square,
      this.needInnerBorder = false,
      this.gridLine,
      this.cropBoxBorder,
      this.backgroundColor,
      this.maskColor});

  @override
  _CropBoxState createState() => _CropBoxState();
}

class _CropBoxState extends State<CropBox> {
  double _tmpScale = 1.0;

  double _scale = 1.0;

  Offset _lastFocalPoint = Offset(0.0, 0.0);
  Offset _deltaPoint = Offset(0, 0);
  late Size _originClipSize;
  Size _resizeClipSize = Size(0, 0);

  double _containerWidth = 0;

  double _containerHeight = 0;
  double _containerPaddingTop = 0;
  double _containerPaddingBottom = 10;
  double _containerPaddingRL = 10;
  Size _cropBoxMaxSize = Size(0, 0);
  Size _cropBoxRealSize = Size(0, 0);
  Rect _cropBoxRealRect = Rect.fromLTWH(0, 0, 0, 0);
  Size _cropRatio = Size(16, 9);
  Offset _originPos = Offset(0, 0);

  Rect resultRect = Rect.fromLTRB(0, 0, 1, 1);

  bool isReady = false;

  @override
  void initState() {
    super.initState();
    resultRect = widget.cropRect ?? Rect.fromLTRB(0, 0, 1, 1);
    assert(resultRect.left >= 0 && resultRect.left <= 1);
    assert(resultRect.right >= 0 && resultRect.right <= 1);
    assert(resultRect.top >= 0 && resultRect.top <= 1);
    assert(resultRect.bottom >= 0 && resultRect.bottom <= 1);

    _originClipSize = widget.clipSize;
    if (widget.cropBoxType == CropBoxType.Circle) {
      _cropRatio = Size(1, 1);
    } else {
      _cropRatio = widget.cropRatio ?? Size(16, 9);
    }
  }

  bool initCrop() {
    caculateCropBoxSize();
    caculateInitClipSize();
    caculateInitClipPosition();
    return true;
  }

  void caculateCropBoxSize() {
    _originPos = Offset(_containerWidth / 2, (_containerHeight) / 2);

    _cropBoxRealSize = canculateInnerBoxRealSize(_cropBoxMaxSize, _cropRatio);
    _cropBoxRealRect = Rect.fromLTWH(
        (_containerWidth - _cropBoxRealSize.width) / 2,
        (_containerHeight - _cropBoxRealSize.height) / 2,
        _cropBoxRealSize.width,
        _cropBoxRealSize.height);
  }

  void caculateInitClipSize() {
    double _realWidth = 0;
    double _realHeight = 0;

    double _cropAspectRatio = _cropBoxRealSize.width / _cropBoxRealSize.height;
    double _clipAspectRatio = _originClipSize.width / _originClipSize.height;

    if (_cropAspectRatio > _clipAspectRatio) {
      _realWidth = _cropBoxRealSize.width;
      _realHeight = _realWidth / _clipAspectRatio;
    } else {
      _realHeight = _cropBoxRealSize.height;
      _realWidth = _realHeight * _clipAspectRatio;
    }
    _resizeClipSize = Size(_realWidth, _realHeight);

    print("_resizeClipSize: $_resizeClipSize");
  }

  void caculateInitClipPosition() {
    Rect? _clipRect;

    if (resultRect == Rect.fromLTRB(0, 0, 1, 1)) {
      _scale = 1.0;
      _deltaPoint = Offset(_originPos.dx - _resizeClipSize.width / 2,
          _originPos.dy - _resizeClipSize.height / 2);
      double _clipAspectRatio = _resizeClipSize.width / _resizeClipSize.height;
      double _cropAspectRatio =
          _cropBoxRealSize.width / _cropBoxRealSize.height;
      Rect _tempRect;
      if (_cropAspectRatio > _clipAspectRatio) {
        _tempRect = Rect.fromLTWH(
            0,
            (_resizeClipSize.height - _cropBoxRealSize.height) / 2,
            _cropBoxRealSize.width,
            _cropBoxRealSize.height);
      } else {
        _tempRect = Rect.fromLTWH(
            (_resizeClipSize.width - _cropBoxRealSize.width) / 2,
            0,
            _cropBoxRealSize.width,
            _cropBoxRealSize.height);
      }
      _clipRect = Rect.fromLTRB(
          _tempRect.left / _resizeClipSize.width,
          _tempRect.top / _resizeClipSize.height,
          _tempRect.right / _resizeClipSize.width,
          _tempRect.bottom / _resizeClipSize.height);
    } else {
      double _clipAspectRatio = _resizeClipSize.width / _resizeClipSize.height;
      double _cropAspectRatio =
          _cropBoxRealSize.width / _cropBoxRealSize.height;
      if (_cropAspectRatio > _clipAspectRatio) {
        _scale = 1 / resultRect.width;
      } else {
        _scale = 1 / resultRect.height;
      }
      double _scaledWidth = _scale * _resizeClipSize.width;
      double _scaledHeight = _scale * _resizeClipSize.height;

      double _scaledLeft = _originPos.dx -
          (_cropBoxRealSize.width / 2 + _scaledWidth * resultRect.left) /
              _scale;
      double _scaledTop = _originPos.dy -
          (_cropBoxRealSize.height / 2 + _scaledHeight * resultRect.top) /
              _scale;
      _deltaPoint = Offset(_scaledLeft, _scaledTop);
    }

    print('_clipRect: $_clipRect  _deltaPoint: $_deltaPoint');
  }

  void resizeRange() {
    Rect _result = transPointToCropArea();
    double left = _result.left;
    double right = _result.right;
    double top = _result.top;
    double bottom = _result.bottom;

    bool _isOutRange = false;
    if ((right - left > 1) || (bottom - top > 1)) {
      double _max = max(right - left, bottom - top);
      left = left / _max;
      right = right / _max;
      top = top / _max;
      bottom = bottom / _max;

      _scale = 1;
      _isOutRange = true;
    }

    if (left < 0) {
      right = right - left;
      left = 0;
      _isOutRange = true;
    }

    if (right > 1) {
      left = 1 - (right - left);
      right = 1;
      _isOutRange = true;
    }

    if (top < 0) {
      bottom = bottom - top;
      top = 0;
      _isOutRange = true;
    }

    if (bottom > 1) {
      top = 1 - (bottom - top);
      bottom = 1;
      _isOutRange = true;
    }

    if (_isOutRange) {
      resultRect = Rect.fromLTRB(left, top, right, bottom);
      try {
        caculateInitClipPosition();
      } catch (e) {
        print(e);
      }
    }
  }

  Rect transPointToCropArea() {
    double _scaledWidth = _scale * _resizeClipSize.width;
    double _scaledHeight = _scale * _resizeClipSize.height;

    double _left = ((_originPos.dx - _deltaPoint.dx) * _scale -
            _cropBoxRealSize.width / 2) /
        _scaledWidth;
    double _top = ((_originPos.dy - _deltaPoint.dy) * _scale -
            _cropBoxRealSize.height / 2) /
        _scaledHeight;

    double _clipAspectRatio = _resizeClipSize.width / _resizeClipSize.height;
    double _cropAspectRatio = _cropBoxRealSize.width / _cropBoxRealSize.height;
    if (_cropAspectRatio > _clipAspectRatio) {
      double _width = _resizeClipSize.width / _scale;
      double _right = _left + 1 / _scale;
      double _bottom =
          _top + _width / _cropAspectRatio / _resizeClipSize.height;
      resultRect = Rect.fromLTRB(_left, _top, _right, _bottom);
    } else {
      double _height = _resizeClipSize.height / _scale;
      double _bottom = _top + 1 / _scale;
      double _right =
          _left + _height * _cropAspectRatio / _resizeClipSize.width;
      _scale = 1 / resultRect.height;
      resultRect = Rect.fromLTRB(_left, _top, _right, _bottom);
    }

    return resultRect;
  }

  Size canculateInnerBoxRealSize(Size _maxSize, Size _ratioSize) {
    double _realWidth = 0;
    double _realHeight = 0;

    double _contentAspectRatio = _maxSize.width / _maxSize.height;
    double _renderAspectRatio = _ratioSize.width / _ratioSize.height;

    if (_contentAspectRatio > _renderAspectRatio) {
      _realHeight = _maxSize.height;
      _realWidth = _realHeight * _renderAspectRatio;
    } else {
      _realWidth = _maxSize.width;
      _realHeight = _realWidth / _renderAspectRatio;
    }

    return Size(_realWidth, _realHeight);
  }

  @override
  void didUpdateWidget(covariant CropBox oldWidget) {
    // setState(() {
    //   isReady = false;
    // });

    super.didUpdateWidget(oldWidget);
  }

  Future<void> updateViews(
      BuildContext context, BoxConstraints constrains) async {
    if (_containerWidth != constrains.maxWidth ||
        _containerHeight != constrains.maxHeight) {
      //orientation change?
      resultRect = widget.cropRect ?? Rect.fromLTRB(0, 0, 1, 1);

      _originClipSize = widget.clipSize;
      if (widget.cropBoxType == CropBoxType.Circle) {
        _cropRatio = Size(1, 1);
      } else {
        _cropRatio = widget.cropRatio ?? Size(16, 9);
      }
      isReady = false;
    }
    _containerWidth = constrains.maxWidth;
    _containerHeight = constrains.maxHeight;
    _containerPaddingTop = constrains.maxHeight / 100;
    _cropBoxMaxSize = widget.maxCropSize ??
        Size(_containerWidth - _containerPaddingRL * 2,
            _containerHeight - _containerPaddingTop - _containerPaddingBottom);
    if (initCrop()) {
      if (widget.cropRectUpdate != null) {
        resultRect = transPointToCropArea();
        if (isReady == false) {
          //Release this event only once!!!
          Future.delayed(Duration(milliseconds: 10), () {
            widget.cropRectUpdate!(resultRect);
          });
        }
      }
      isReady = true;
    }

    print(
        "isReady=$isReady  init data \n _containerWidth: $_containerWidth _containerHeight: $_containerHeight _containerPaddingTop: $_containerPaddingTop");
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains) {
      return OrientationBuilder(builder: (context, orientation) {
        updateViews(context, constrains);

        return ClipRect(
          child: Container(
            color: widget.backgroundColor ?? Color(0xff141414),
            child: GestureDetector(
              onScaleStart: _handleScaleStart,
              onScaleUpdate: (d) => _handleScaleUpdate(context.size!, d),
              onScaleEnd: _handleScaleEnd,
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                child: (isReady)
                    ? Stack(
                        children: [
                          Transform(
                            transform: Matrix4.identity()
                              ..scale(max(_scale, 1.0), max(_scale, 1.0))
                              ..translate(_deltaPoint.dx, _deltaPoint.dy),
                            origin: _originPos,
                            child: OverflowBox(
                              alignment: Alignment.topLeft,
                              maxWidth: double.infinity,
                              maxHeight: double.infinity,
                              child: Container(
                                width: _resizeClipSize.width,
                                height: _resizeClipSize.height,
                                child: widget.child,
                              ),
                            ),
                          ),
                          CustomPaint(
                            size: Size(double.infinity, double.infinity),
                            painter: widget.cropBoxType == CropBoxType.Circle
                                ? DrawCircleLight(
                                    clipRect: _cropBoxRealRect,
                                    centerPoint: _originPos,
                                    cropBoxBorder:
                                        widget.cropBoxBorder ?? CropBoxBorder(),
                                    maskColor: widget.maskColor)
                                : DrawRectLight(
                                    clipRect: _cropBoxRealRect,
                                    needInnerBorder: widget.needInnerBorder,
                                    gridLine: widget.gridLine,
                                    cropBoxBorder: widget.cropBoxBorder,
                                    maskColor: widget.maskColor),
                          ),
                        ],
                      )
                    : Center(
                        child: Container(
                          child: Center(
                              child: CupertinoActivityIndicator(
                            radius: 12,
                          )),
                        ),
                      ),
              ),
            ),
          ),
        );
      });
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _tmpScale = _scale;
    _lastFocalPoint = details.focalPoint;

    if (widget.cropRectUpdateStart != null) {
      widget.cropRectUpdateStart!();
    }
  }

  void _handleScaleUpdate(Size size, ScaleUpdateDetails details) {
    setState(() {
      _scale = min(widget.maxScale, max(_tmpScale * details.scale, 1.0));
      if (details.scale == 1) {
        _deltaPoint += (details.focalPoint - _lastFocalPoint);
        _lastFocalPoint = details.focalPoint;
      }
      resizeRange();
    });
    if (widget.cropRectUpdate != null) {
      widget.cropRectUpdate!(resultRect);
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    widget.cropRectUpdateEnd(resultRect);
  }
}

class DrawRectLight extends CustomPainter {
  final Rect clipRect;
  final bool needInnerBorder;
  final GridLine? gridLine;
  final CropBoxBorder? cropBoxBorder;
  final Color? maskColor;
  DrawRectLight(
      {required this.clipRect,
      this.needInnerBorder = false,
      this.gridLine,
      this.cropBoxBorder,
      this.maskColor});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    CropBoxBorder _cropBoxBorder = cropBoxBorder ?? CropBoxBorder();
    double _storkeWidth = _cropBoxBorder.width;
    Radius _borderRadius = _cropBoxBorder.noNullRaidus;
    RRect _rrect = RRect.fromRectAndRadius(clipRect, _borderRadius);
    RRect _borderRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(clipRect.left, clipRect.top - _storkeWidth / 2,
            clipRect.width, clipRect.height + _storkeWidth),
        _borderRadius);

    paint
      ..style = PaintingStyle.fill
      ..color = maskColor ?? Color.fromRGBO(0, 0, 0, 0.5);
    canvas.save();

    Path path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTRB(0, 0, size.width, size.height)),
      Path()
        ..addRRect(_rrect)
        ..close(),
    );
    canvas.drawPath(path, paint);
    canvas.restore();

    paint
      ..color = _cropBoxBorder.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _storkeWidth;

    canvas.drawRRect(_borderRRect, paint);

    if (gridLine != null) {
      canvas.save();

      paint
        ..color = gridLine!.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = gridLine!.width;
      Path gridLinePath = new Path();

      EdgeInsets _padding = gridLine!.padding ?? EdgeInsets.all(0);

      for (int i = 1; i < 3; i++) {
        gridLinePath.moveTo(
            ((clipRect.width / 3) * i + clipRect.left - gridLine!.width / 2),
            clipRect.top + _padding.top);
        gridLinePath.lineTo(
            ((clipRect.width / 3) * i + clipRect.left - gridLine!.width / 2),
            clipRect.top + clipRect.height - _padding.bottom);

        gridLinePath.moveTo(clipRect.left + _padding.left,
            ((clipRect.height / 3) * i + clipRect.top - gridLine!.width / 2));
        gridLinePath.lineTo(clipRect.left + clipRect.width - _padding.right,
            ((clipRect.height / 3) * i + clipRect.top - gridLine!.width / 2));
      }
      canvas.drawPath(gridLinePath, paint);
      canvas.restore();
    }

    if (needInnerBorder) {
      paint.style = PaintingStyle.fill;
      canvas.drawRect(
          Rect.fromLTWH(clipRect.left - _storkeWidth / 2,
              clipRect.top - _storkeWidth, 45.44 / 2, 7.57 / 2),
          paint);
      canvas.drawRect(
          Rect.fromLTWH(clipRect.left - _storkeWidth / 2,
              clipRect.top - _storkeWidth, 7.57 / 2, 45.44 / 2),
          paint);
      canvas.drawRect(
          Rect.fromLTWH(clipRect.left + clipRect.width + _storkeWidth / 2,
              clipRect.top - _storkeWidth, -45.44 / 2, 7.57 / 2),
          paint);
      canvas.drawRect(
          Rect.fromLTWH(clipRect.left + clipRect.width + _storkeWidth / 2,
              clipRect.top - _storkeWidth, -7.57 / 2, 45.44 / 2),
          paint);
      canvas.drawRect(
          Rect.fromLTWH(
              clipRect.left - _storkeWidth / 2,
              clipRect.top + clipRect.height + _storkeWidth,
              45.44 / 2,
              -7.57 / 2),
          paint);
      canvas.drawRect(
          Rect.fromLTWH(
              clipRect.left - _storkeWidth / 2,
              clipRect.top + clipRect.height + _storkeWidth,
              7.57 / 2,
              -45.44 / 2),
          paint);
      canvas.drawRect(
          Rect.fromLTWH(
              clipRect.left + clipRect.width + _storkeWidth / 2,
              clipRect.top + clipRect.height + _storkeWidth,
              -45.44 / 2,
              -7.57 / 2),
          paint);
      canvas.drawRect(
          Rect.fromLTWH(
              clipRect.left + clipRect.width + _storkeWidth / 2,
              clipRect.top + clipRect.height + _storkeWidth,
              -7.57 / 2,
              -45.44 / 2),
          paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class DrawCircleLight extends CustomPainter {
  final Rect clipRect;
  final Offset centerPoint;
  final CropBoxBorder? cropBoxBorder;
  final Color? maskColor;
  DrawCircleLight(
      {required this.clipRect,
      required this.centerPoint,
      this.cropBoxBorder,
      this.maskColor});

  @override
  void paint(Canvas canvas, Size size) {
    CropBoxBorder _cropBoxBorder = cropBoxBorder ?? CropBoxBorder();

    var paint = Paint();
    double _storkeWidth = _cropBoxBorder.width;
    double _radius = clipRect.width / 2;
    paint
      ..style = PaintingStyle.fill
      ..color = maskColor ?? Color.fromRGBO(0, 0, 0, 0.5);
    canvas.save();
    Path path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTRB(0, 0, size.width, size.height)),
      Path()
        ..addOval(Rect.fromCircle(center: centerPoint, radius: _radius))
        ..close(),
    );
    canvas.drawPath(path, paint);
    canvas.restore();

    paint
      ..color = _cropBoxBorder.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _storkeWidth;
    canvas.drawCircle(centerPoint, _radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
