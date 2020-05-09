import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:eosdart_ecc/eosdart_ecc.dart';

import 'package:file_picker/file_picker.dart';

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

class ECard {
  String _name;
  String _publicKey;
  Image _stamp;
  Image _qrCode;

  ECard(this._name, this._publicKey, this._stamp, this._qrCode);
}

class _SAFAAppState extends State<SAFAApp> {
  List<ECard> _ecards = [];
  ECard _ecard;
  Icon _result;
  List<CardLine> _cardData;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget _tmp = Icon(Icons.card_giftcard);

    if(_ecard != null)
      _tmp = _ecard._stamp;

    List<Widget> r = [_tmp];

    if(_result != null)
      r.add(_result);

    Stack st = Stack(alignment: AlignmentDirectional.center, children: r);
    Widget lv = Expanded(child: ListView(children: _listView()));

    OrientationBuilder layout = OrientationBuilder(builder: (context, orientation) {
      if (MediaQuery.of(context).orientation == Orientation.portrait)
        return Column(children: [Row(children: [Spacer(), st]), lv]);
      else
        return Row(children: [lv, Column(children: [st, Spacer()])]);
    });

    return MaterialApp(
      home:  Scaffold(
        appBar: AppBar(
          title: Text('ECards'),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.add), onPressed: _addECard),
            IconButton(icon: Icon(Icons.settings_overscan), onPressed: _scan),
          ],
        ),
        body: layout
      )
    );
  }

  List<Widget> _listView() {
    List<Widget> w = [];

    if(_cardData != null) {
      for(CardLine l in _cardData) {
        w.add(Row(children: [
          Expanded(child: Text(l._tag)),
          Icon(Icons.close, color: l._flag),
          Expanded(child: Text(l._value))
        ]));
      }
    }
    else if(_ecard != null) {
        w.add(_ecard._qrCode);
    }

    return w;
  }

  void _scan() async {
    try {
      _result = null;

      ScanResult scanResult = await BarcodeScanner.scan(options: ScanOptions(android: AndroidOptions(aspectTolerance: 0.1)));

      if(scanResult.type == ResultType.Barcode)
        _process(scanResult.rawContent);
      
      setState(() {});
    } catch (e) {
      setState(() => _cardData.add(CardLine(e.toString(), Colors.white, '')));
    }
  }

  void _process(String barcode) {
    String data = '';
    String signatureValue;

//    _result = Text('Fake', style: Theme.of(context).textTheme.body2.apply(color: Colors.red, fontSizeFactor: 2.0));
    _result = Icon(Icons.close, color: Colors.red, size: 64);
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

        data += '$line\n';

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
      for(ECard ecard in _ecards) {
        EOSPublicKey publicKey = EOSPublicKey.fromString(ecard._publicKey);
        EOSSignature signature = EOSSignature.fromString(signatureValue);

        if(signature.verify(data, publicKey))
          _result = Icon(Icons.check, color: Colors.green, size: 64);
      }
    }
  }

  void _addECard() async {
    File ecard = await FilePicker.getFile();
    if(ecard != null) {
      Map<String, dynamic> data = json.decode(ecard.readAsStringSync());
      _ecard = ECard(
        data['name'],
        data['publickey'],
        Image.memory(base64Decode(data['stamp'])),
        Image.memory(base64Decode(data['qrcode']))
      );

      _ecards.add(_ecard);
      setState(() {});
    }
  }
}
