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
  final List<ECard> _ecards;

  ECardsListView (this._ecards);

  @override
  createState() => ECardsListViewState(_ecards);
}

class ECardsListViewState extends State<ECardsListView> {
  final List<ECard> _ecards;

  ECardsListViewState(this._ecards);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('My ECards'),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.add), onPressed: _addECard)
        ],
      ),
      body: ListView.builder(itemBuilder: (BuildContext context, int i) {
        if (i < _ecards.length)
          return _buildReceiptRow(_ecards[i]);

        return null;
      }));
    }

  void _onDismissed (DismissDirection direction, ECard ecard) {
    _ecards.remove(ecard);
  }

  void _addECard() async {
    File f = await FilePicker.getFile();
    if(f != null) {
      ECard ecard = ECard.fromJson(f.readAsStringSync());
      _ecards.add(ecard);
      createImages(ecard);
      ECardsStore.saveCards(_ecards);

      setState(() {});
    }
  }

  Widget _buildReceiptRow(ECard ecard) {
    //List<Widget> w = [];
    Text text = Text(ecard.name, style: Theme.of(context).textTheme.headline.apply(fontWeightDelta: 10));
    ListTile tile;

    if(ecard.stampImage != null)
      tile = ListTile(leading: ecard.stampImage, title: text, onTap: () {_select(ecard);});
    else
      tile = ListTile(title: text, onTap: () {_select(ecard);});
    
    //w.add(Text(ecard.name, style: Theme.of(context).textTheme.headline.apply(fontWeightDelta: 10)));

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