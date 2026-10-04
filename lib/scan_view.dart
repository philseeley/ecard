import 'package:flutter/material.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';

class ScanView extends StatefulWidget {

  const ScanView ({super.key});

  @override
  createState() => ScanViewState();
}

class ScanViewState extends State<ScanView> {
  final QRCodeDartScanController _scanController = QRCodeDartScanController();
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
                  _scanController.setFlash(_flashOn);
                });
              }
          )
        ],
      ),
      body: QRCodeDartScanView(
        controller: _scanController,
        onCapture: (ScanResult result) {
          // We have to stop scanning immediately, or else we get called multiple
          // times ad the Navigator gets confused with too many pops.
          _scanController.stopScan();
          Navigator.pop(context, result.text);
        },
      ),
    );
  }
}