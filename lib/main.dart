import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';

import 'package:eosdart_ecc/eosdart_ecc.dart';
import 'package:qrscan/qrscan.dart' as scanner;

import 'ECard.dart';
import 'ECardsListView.dart';
import 'ECardsStore.dart';

void main() => runApp(ECardApp());

class ECardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    TextStyle ts = Theme.of(context).textTheme.subtitle1.apply(fontWeightDelta: 4);

    return MaterialApp(
      home: Main(),
      theme: ThemeData(textTheme: TextTheme(bodyText2: ts, subtitle1: ts))
    );
  }
}

class Main extends StatefulWidget {
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
  ECard ecard;
  List<CardLine> cardLines;
  Text result;

  CurrentCard();
}

class _MainState extends State<Main> with WidgetsBindingObserver {
  ECards _ecards;
  CurrentCard _currentCard;

  _MainState() {
    init();
  }

  void init() async {
    _ecards = await ECardsStore.loadCards();

    if(_ecards.defaultPublicKey != null) {
      setState(() {
        _currentCard = CurrentCard();
        _currentCard.ecard = _ecards.cards[_ecards.defaultPublicKey];
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
      if(_currentCard.ecard != null) {
        title = _currentCard.ecard.organisation;
        header.add(_currentCard.ecard.stampImage);
      }

      if(_currentCard.result != null)
        header.add(_currentCard.result);
    }

    body.add(Expanded(child: _body()));

    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.list), onPressed: () {_listECards(context);}),
            IconButton(icon: Icon(Icons.settings_overscan), onPressed: _scan),
          ],
        ),
        body: Container(padding: EdgeInsets.all(5), child: Column(children: body))
      );
  }

  Widget _body() {
    if(_currentCard != null) {
      if(_currentCard.cardLines != null) {
        List<Widget> list = [];

        for(CardLine l in _currentCard.cardLines) {
          list.add(Row(children: [
            Expanded(child: Text(l._tag)),
            Icon(Icons.close, color: l._flag),
            Expanded(child: Text(l._value))
          ]));
        }

        return ListView(children: list);
      }
      else if(_currentCard.ecard != null) {
        return SingleChildScrollView(
          child: InkWell(
            child: Column(
              children: [
                _currentCard.ecard.qrCodeImage,
                Text("Press to decode")
              ]
            ),
            onLongPress: _imageDetails,
          )
        );
      }
    }

    return Container();
  }

  void _listECards (BuildContext context) async {
    _currentCard = null;

    ECard ecard = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) {
        return ECardsListView(_ecards);
      })
    );

    setState(() {
      if(ecard != null) {
        _currentCard = CurrentCard();
        _currentCard.ecard = ecard;
      }
    });
  }

  void _scan() async {
    _currentCard = null;

    String result = await scanner.scan();

    setState(() {
      if(result != null)
        _process(result);
    });
  }

  void _imageDetails() async {
    String result = await scanner.scanBytes(base64Decode(_currentCard.ecard.qrCode));

    setState(() {
      if(result != null)
        _process(result);
    });
  }

  void _process(String barcode) {
    String data = '';
    String signatureValue;
    bool expired = false;

    _currentCard = CurrentCard();
    _currentCard.cardLines = [];
    _currentCard.result = Text('Unverified', style: Theme.of(context).textTheme.headline5.apply(color: Colors.red, fontWeightDelta: 10));

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

            if (DateTime.now().isAfter(dt.add(Duration(days:1)))) {
              flag = Colors.red;
              if(tag == 'Expires')
                expired = true;
            }
          } on FormatException {}
        }

        _currentCard.cardLines.add(CardLine(tag, flag, value));
      }
    });

    if(signatureValue != null) {
      for(String k in _ecards.cards.keys) {
        ECard ecard = _ecards.cards[k];

        EOSPublicKey publicKey = EOSPublicKey.fromString(ecard.publicKey);
        EOSSignature signature = EOSSignature.fromString(signatureValue);

        if(signature.verify(data, publicKey)) {
          if(expired)
            _currentCard.result = Text('Expired', style: Theme.of(context).textTheme.headline5.apply(color: Colors.orange, fontWeightDelta: 10));
          else
            _currentCard.result = Text('Verified', style: Theme.of(context).textTheme.headline5.apply(color: Colors.green, fontWeightDelta: 10));
          _currentCard.ecard = ecard;
          break;
        }
      }
    }
  }
 }
