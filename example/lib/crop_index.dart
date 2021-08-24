import 'dart:typed_data';

import 'package:example/image_result_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:crop_box/crop_box.dart';

enum ClipType { networkImage, localImage }

class CropIndex extends StatefulWidget {
  final double width;
  final double height;
  final ClipType clipType;
  final Uint8List? localImageData;
  final String? imageUrl;
  CropIndex(
      {Key? key,
      required this.width,
      required this.height,
      required this.clipType,
      this.localImageData,
      this.imageUrl})
      : super(key: key);

  @override
  _CropIndexState createState() => _CropIndexState();
}

class _CropIndexState extends State<CropIndex> {
  Rect _resultRect = Rect.zero;
  Size _maxCropSize = Size(300, 300);
  Size _cropRatio = Size(16, 9);
  Rect? _cropRect;

  bool exportLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Detail'),
      ),
      body: Container(
        child: Column(
          children: [
            Expanded(
              child: CropBox(
                // cropRect: Rect.fromLTRB(1 - 0.4083, 0.162, 1, 0.3078), // 2.4倍 模拟随机位置
                // cropRect: Rect.fromLTRB(0, 0, 0.4083, 0.1457), //2.4倍，都是0,0
                // cropRect: Rect.fromLTRB(0, 0, 1, 0.3572), // 1倍
                // cropBoxType: CropBoxType.Circle,
                // borderColor: Colors.white,
                gridLine: GridLine(),
                cropRect: _cropRect,
                clipSize: Size(widget.width, widget.height),
                maxCropSize: _maxCropSize,
                cropRatio: _cropRatio,
                cropBoxBorder: CropBoxBorder(
                  color: Colors.white,
                  radius: Radius.circular(5),
                ),
                cropRectUpdateEnd: (rect) {
                  _resultRect = rect;
                  print("裁剪区域最终确定 $rect");
                  setState(() {});
                },
                cropRectUpdate: (rect) {
                  _resultRect = rect;
                  print("裁剪区域变化 $rect");
                  setState(() {});
                },
                child: widget.clipType == ClipType.networkImage
                    ? Image.network(
                        widget.imageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded
                                          .toDouble() /
                                      loadingProgress.expectedTotalBytes!
                                          .toDouble()
                                  : null,
                            ),
                          );
                        },
                      )
                    : Image.memory(
                        widget.localImageData!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                      ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              child: Container(
                height: 15.0.h,
                padding: EdgeInsets.all(8.0.dp),
                child: Row(
                  children: [
                    Expanded(
                      flex: 0,
                      child: Container(
                        width: 40.0.w,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "left: ${_resultRect.left.toStringAsFixed(5)}",
                              style: TextStyle(
                                fontFamily: "PingFang SC",
                                fontSize: 14.0.dp,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "top: ${_resultRect.top.toStringAsFixed(5)}",
                              style: TextStyle(
                                fontFamily: "PingFang SC",
                                fontSize: 14.0.dp,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "right: ${_resultRect.right.toStringAsFixed(5)}",
                              style: TextStyle(
                                fontFamily: "PingFang SC",
                                fontSize: 14.0.dp,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "bottom: ${_resultRect.bottom.toStringAsFixed(5)}",
                              style: TextStyle(
                                fontFamily: "PingFang SC",
                                fontSize: 14.0.dp,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          ElevatedButton(
                            child: Text(
                              "1:1",
                              style: TextStyle(
                                fontFamily: "PingFang SC",
                                fontSize: 14.0.dp,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _cropRatio = Size(1, 1);
                              });
                            },
                          ),
                          SizedBox(
                            height: 10.0.dp,
                          ),
                          ElevatedButton(
                            child: Text(
                              exportLoading ? "Exporting" : "Export",
                              style: TextStyle(
                                fontFamily: "PingFang SC",
                                fontSize: 14.0.dp,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: exportLoading
                                ? null
                                : () async {
                                    setState(() {
                                      exportLoading = true;
                                    });

                                    /// get origin image uint8List
                                    Uint8List bytes;
                                    if (widget.clipType ==
                                        ClipType.networkImage) {
                                      bytes = (await NetworkAssetBundle(
                                                  Uri.parse(widget.imageUrl!))
                                              .load(widget.imageUrl!))
                                          .buffer
                                          .asUint8List();
                                    } else {
                                      bytes = widget.localImageData!;
                                    }

                                    /// get result uint8List
                                    Uint8List result =
                                        (await ImageCrop.getResult(
                                            clipRect: _resultRect,
                                            image: bytes))!;

                                    setState(() {
                                      exportLoading = false;
                                    });

                                    /// if you need to export to gallery
                                    /// you can use this https://pub.dev/packages/image_gallery_saver
                                    /// ... your export code ...
                                    ///
                                    /// my code is only to show result in other page
                                    Navigator.of(context).push(
                                        new MaterialPageRoute(builder: (_) {
                                      return ImageResultPage(
                                        imageBytes: result,
                                      );
                                    }));
                                  },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
