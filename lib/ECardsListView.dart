import 'dart:io';
import 'dart:convert';
import 'package:ecardapp/ECardsStore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'ECard.dart';

void createImages(ECard ecard) {
  try {
    ecard.stampImage = Image.memory(base64Decode(ecard.stamp));
  } on Exception {}
  try {
    ecard.qrCodeImage = Image.memory(base64Decode(ecard.qrCode));
  } on Exception {}
}

class ECardsListView extends StatefulWidget {
  final ECards _ecards;

  ECardsListView (this._ecards);

  @override
  createState() => ECardsListViewState(_ecards);
}

class ECardsListViewState extends State<ECardsListView> {
  final ECards _ecards;

  ECardsListViewState(this._ecards);

  @override
  Widget build(BuildContext context) {
    List<ECard> ecardList = _ecards.cards.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('My ECards'),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.add), onPressed: _addECard)
        ],
      ),
      body: ListView.builder(itemBuilder: (BuildContext context, int i) {
        if (i < ecardList.length) {
          return _buildECardRow(ecardList[i]);
        }

        return null;
      }));
    }

  void _onDismissed (DismissDirection direction, ECard ecard) {
    _ecards.cards.remove(ecard.publicKey);
    if(_ecards.cards.length > 0 && _ecards.defaultPublicKey == ecard.publicKey)
      setState(() {
        _ecards.defaultPublicKey = _ecards.cards.keys.first;
      });
    ECardsStore.saveCards(_ecards);
  }

  void _addECard() async {
    FilePickerResult? fpResult = await FilePicker.platform.pickFiles();

    if(fpResult != null) {
      setState(() {
        File f = File(fpResult.files.single.path!);
        ECard ecard = ECard.fromJson(f.readAsStringSync());
        _ecards.cards[ecard.publicKey] = ecard;
        createImages(ecard);
        if(_ecards.cards.length == 1)
          _ecards.defaultPublicKey = ecard.publicKey;
        ECardsStore.saveCards(_ecards);
      });
    }
  }

  Widget _buildECardRow(ECard ecard) {
    Text text = Text(ecard.organisation, style: Theme.of(context).textTheme.headlineSmall?.apply(fontWeightDelta: 10));
    ListTile tile;

    tile = ListTile(
      leading: ecard?.stampImage,
      title: text,
      onTap: () {_select(ecard);},
      trailing: Radio<String>(value: ecard.publicKey, groupValue: _ecards.defaultPublicKey, onChanged: (value) {
        setState(() {
          _ecards.defaultPublicKey = value!;
        });
      }),
    );
    
    return Dismissible(
      key: GlobalKey(),
      secondaryBackground: ListTile(trailing: Icon(Icons.delete)),
      background: ListTile(leading: Icon(Icons.delete)),
      onDismissed: (direction){
        _onDismissed(direction, ecard);
      },
      direction: DismissDirection.horizontal,
      child: tile
    );
  }

  void _select(ECard ecard) {
    Navigator.pop(context, ecard);
  }
}