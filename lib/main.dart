import 'dart:convert';
import 'dart:io';
import 'package:ecardapp/ScanView.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'package:eosdart_ecc/eosdart_ecc.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';

import 'ECard.dart';
import 'ECardsListView.dart';
import 'ECardsStore.dart';

void main() => runApp(ECardApp());

class ECardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    TextStyle? ts = Theme.of(context).textTheme.titleMedium?.apply(fontWeightDelta: 4);

    return MaterialApp(
      home: Main(),
      theme: ThemeData(textTheme: TextTheme(bodyText2: ts, subtitle1: ts)),
      debugShowCheckedModeBanner: false
    );
  }
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  _MainState createState() => _MainState();
}

class CardLine {
  String _tag;
  Color _flag;
  String _value;

  CardLine(this._tag, this._flag, this._value);
}

class CurrentCard {
  ECard? ecard;
  List<CardLine>? cardLines;
  Text? result;

  CurrentCard();
}

class _MainState extends State<Main> with WidgetsBindingObserver {
  late ECards _ecards;
  CurrentCard? _currentCard;

  _MainState() {
    init();
  }

  void init() async {
    _ecards = await ECardsStore.loadCards();

    if(_ecards.defaultPublicKey != null) {
      setState(() {
        _currentCard = CurrentCard();
        _currentCard?.ecard = _ecards.cards[_ecards.defaultPublicKey];
      });
    }
  }

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch(state)
    {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        ECardsStore.saveCards(_ecards);
        break;
      case AppLifecycleState.resumed:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'ECards';

    List<Widget> header = [];
    List<Widget> body = [Row(children: header)];

    if(_currentCard != null) {
      if(_currentCard!.ecard != null) {
        title = _currentCard!.ecard!.organisation;
        header.add(_currentCard!.ecard!.stampImage);
      }

      if(_currentCard!.result != null) {
        header.add(_currentCard!.result!);
      }
    }

    body.add(Expanded(child: _body()));

    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            IconButton(icon: const Icon(Icons.list), onPressed: () {_listECards(context);}),
            IconButton(icon: const Icon(Icons.settings_overscan), onPressed: () {_scan(context);}),
          ],
        ),
        body: Container(padding: const EdgeInsets.all(5), child: Column(children: body))
      );
  }

  Widget _body() {
    if(_currentCard != null) {
      if(_currentCard!.cardLines != null) {
        List<Widget> list = [];

        for(CardLine l in _currentCard!.cardLines!) {
          list.add(Row(children: [
            Expanded(child: Text(l._tag)),
            Icon(Icons.close, color: l._flag),
            Expanded(child: Text(l._value))
          ]));
        }

        return ListView(children: list);
      }
      else if(_currentCard!.ecard != null) {
        return SingleChildScrollView(
          child: InkWell(
            onLongPress: _imageDetails,
            child: Column(
              children: [
                _currentCard!.ecard!.qrCodeImage,
                const Text("Press to decode")
              ]
            ),
          )
        );
      }
    }

    return Container();
  }

  void _listECards (BuildContext context) async {
    _currentCard = null;

    ECard? ecard = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) {
        return ECardsListView(_ecards);
      })
    );

    setState(() {
      if(ecard != null) {
        _currentCard = CurrentCard();
        _currentCard!.ecard = ecard;
      }
    });
  }

  Future<void> _scan(BuildContext context) async {
    _currentCard = null;

    String? result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return const ScanView();
        })
    );

    if (!mounted) return;

    setState(() {
      if(result != null) {
        _process(result);
      }
    });
  }

  void _imageDetails() async {
    // As qr_code_dart_scan has no interface to scan an array, we write out a temporary
    // image as we can process that.

    QRCodeDartScanDecoder decoder = QRCodeDartScanDecoder(formats: QRCodeDartScanDecoder.acceptedFormats);
    Directory dir = await getTemporaryDirectory();
    File f = File('${dir.path}/tmp');
    f.writeAsBytesSync(base64Decode(_currentCard!.ecard!.qrCode));
    XFile file = XFile(f.path);
    Result? result = await decoder.decodeFile(file);

    setState(() {
      if(result != null) {
        _process(result.text);
      }
    });
  }

  void _process(String barcode) {
    String data = '';
    String? signatureValue;
    bool expired = false;

    _currentCard = CurrentCard();
    _currentCard!.cardLines = [];
    _currentCard!.result = Text('Unverified', style: Theme.of(context).textTheme.headlineSmall?.apply(color: Colors.red, fontWeightDelta: 10));

    LineSplitter.split(barcode).forEach((String line) {

      if (line.startsWith('SIG_')) {
        signatureValue = line;
      }
      else {
        String tag;
        String value = '';
        Color flag = Colors.white;

        int sep = line.indexOf(':');

        data += line.trim();

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

            if (DateTime.now().isAfter(dt.add(const Duration(days:1)))) {
              flag = Colors.red;
              if(tag == 'Expires') {
                expired = true;
              }
            }
          } on FormatException {
            // The tag isn't a valid date string.
          }
        }

        _currentCard!.cardLines!.add(CardLine(tag, flag, value));
      }
    });

    if(signatureValue != null) {
      for(String k in _ecards.cards.keys) {
        ECard ecard = _ecards.cards[k]!;

        EOSPublicKey publicKey = EOSPublicKey.fromString(ecard.publicKey);
        EOSSignature signature = EOSSignature.fromString(signatureValue!);

        if(signature.verify(data, publicKey)) {
          if(expired) {
            _currentCard?.result = Text('Expired', style: Theme.of(context).textTheme.headlineSmall?.apply(color: Colors.orange, fontWeightDelta: 10));
          } else {
            _currentCard?.result = Text('Verified', style: Theme.of(context).textTheme.headlineSmall?.apply(color: Colors.green, fontWeightDelta: 10));
          }
          _currentCard!.ecard = ecard;
          break;
        }
      }
    }
  }
 }
