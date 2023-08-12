import 'package:flutter/material.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';

class ScanView extends StatefulWidget {

  const ScanView ({super.key});

  @override
  createState() => ScanViewState();
}

class ScanViewState extends State<ScanView> {
  QRCodeDartScanController _scanController = QRCodeDartScanController();
  bool _flashOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan"),
        actions: <Widget>[
          IconButton(
              icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
              onPressed: () {
                setState(() {
                  _flashOn = !_flashOn;
                  _scanController.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
                });
              }
          )
        ],
      ),
      body: QRCodeDartScanView(
        controller: _scanController,
        onCapture: (Result result) {
          // We have to stop scanning immediately, or else we get called multiple
          // times ad the Navigator gets confused with too many pops.
          _scanController.setScanEnabled(false);
          Navigator.pop(context, result.text);
        },
      ),
    );
  }
}