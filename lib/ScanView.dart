import 'package:flutter/material.dart';
import 'package:qrcode_flutter/qrcode_flutter.dart';

class ScanView extends StatefulWidget {
  @override
  _ScanViewState createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> {
  QRCaptureController _controller = QRCaptureController();
  BuildContext _context;
  bool _torchOn = false;

  _ScanViewState() {
    _controller.onCapture(_onCapture);
  }

  @override
  void dispose() {
    _controller.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _context = context;

    return Scaffold(
      appBar: AppBar(
        title: Text('Scan'),
        actions: <Widget>[
          IconButton(icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off), onPressed: _torch),
        ],
      ),
      body: Container(alignment: Alignment(0.0, -1.0), child: Container(padding: EdgeInsets.all(10), height: 300, child: QRCaptureView(controller: _controller)))
    );
  }

  void _torch() {
    setState(() {
      _torchOn = ! _torchOn;
      _controller.torchMode = _torchOn ? CaptureTorchMode.on : CaptureTorchMode.off;
    });
  }

  void _onCapture(String barcode) {
    _controller.pause();

    Navigator.pop(_context, barcode);
  }
}