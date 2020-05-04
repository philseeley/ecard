import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:eosdart_ecc/eosdart_ecc.dart';

void main() => runApp(new SAFAApp());

class SAFAApp extends StatefulWidget {
  @override
  _SAFAAppState createState() => new _SAFAAppState();
}

class CardLine {
  String _tag;
  Color _flag;
  String _value;

  CardLine(this._tag, this._flag, this._value);
}

class _SAFAAppState extends State<SAFAApp> {
  List<CardLine> _cardData;

  String barcode = "";
  String result = "";

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:  Scaffold(
        appBar: AppBar(
          title: Text('SAFA'),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.settings_overscan), onPressed: _scan)
          ],
        ),
        body: Column(children: [
          Expanded(child: ListView(children: _listView())),
          Image(image: AssetImage('assets/safa-stamp.jpg'))
        ])
      )
    );
  }
//            decoration: BoxDecoration(image: DecorationImage(image: AssetImage("assets/SAFA_Header.png"))),

  List<Widget> _listView() {
    List<Widget> w = [];

    if(_cardData == null) {
      w.add(Text(''));
      w.add(Text('                Tap to scan'));
    }
    else {
      for(CardLine l in _cardData) {
        w.add(Row(children: [
          Expanded(child: Text(l._tag)),
          Icon(Icons.close, color: l._flag),
          Expanded(child: Text(l._value))
        ]));
      }

    }

    return w;
  }

  void _scan() async {
    try {
      ScanResult scanResult = await BarcodeScanner.scan();
      String barcode = scanResult.rawContent;
      bool result = _process(barcode);
      setState(() {});
    } on PlatformException catch (e) {
      setState(() => this.barcode = 'Unknown error: $e');
    } on FormatException{
      setState(() => this.barcode = 'null (User returned using the "back"-button before scanning anything. Result)');
    } catch (e) {
      setState(() => this.barcode = 'Unknown error: $e');
    }
  }

  bool _process(String barcode) {
    String data = '';
    String signatureValue;

    _cardData = [];

    LineSplitter.split(barcode).forEach((String line) {

      if (line.startsWith('SIG_')) {
        signatureValue = line;
      }
      else {
        String tag;
        String value = '';
        Color flag = Colors.white;

        int sep = line.indexOf(':');

        data += line;
        data += '\n';

        if (sep == -1)
        {
          tag = line;
        }
        else
        {
          tag = line.substring(0, sep);
          value = line.substring(sep + 1);

          try {
            DateTime dt = DateFormat('yyyy-MM-dd').parseStrict(tag);
            String tmp = tag;
            tag = value;
            value = tmp;

            if (DateTime.now().isAfter(dt.add(Duration(days:1))))
              flag = Colors.red; //cancel close clear
          } on FormatException {}
        }

        _cardData.add(CardLine(tag, flag, value));
      }
    });

    if(signatureValue != null) {
      print('DATA is $data');
      print('SIG is $signatureValue');

      EOSPublicKey publicKey = EOSPublicKey.fromString('EOS5A3nF5u2TjeYU6hpwxz2WmhKmbTX1wns3uBSCN7VupfbYP5NSa');

      EOSSignature signature = EOSSignature.fromString(signatureValue);

      // Verify the data using the signature
      print('VERIFY ${signature.verify(data, publicKey)}');
      return signature.verify(data, publicKey);
    }

    return false;
  }
}
