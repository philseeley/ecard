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
  final Map<String, ECard> _ecards;

  ECardsListView (this._ecards);

  @override
  createState() => ECardsListViewState(_ecards);
}

class ECardsListViewState extends State<ECardsListView> {
  final Map<String, ECard> _ecards;

  ECardsListViewState(this._ecards);

  @override
  Widget build(BuildContext context) {
    List<ECard> ecardList = _ecards.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('My ECards'),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.add), onPressed: _addECard)
        ],
      ),
      body: ListView.builder(itemBuilder: (BuildContext context, int i) {
        if (i < ecardList.length)
          return _buildReceiptRow(ecardList[i]);

        return null;
      }));
    }

  void _onDismissed (DismissDirection direction, ECard ecard) {
    _ecards.remove(ecard.publicKey);
    ECardsStore.saveCards(_ecards);
  }

  void _addECard() async {
    File f = await FilePicker.getFile();
    if(f != null) {
      ECard ecard = ECard.fromJson(f.readAsStringSync());
      _ecards[ecard.publicKey] = ecard;
      createImages(ecard);
      ECardsStore.saveCards(_ecards);

      setState(() {});
    }
  }

  Widget _buildReceiptRow(ECard ecard) {
    Text text = Text(ecard.organisation, style: Theme.of(context).textTheme.headline.apply(fontWeightDelta: 10));
    ListTile tile;

    if(ecard.stampImage != null)
      tile = ListTile(leading: ecard.stampImage, title: text, onTap: () {_select(ecard);});
    else
      tile = ListTile(title: text, onTap: () {_select(ecard);});
    
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