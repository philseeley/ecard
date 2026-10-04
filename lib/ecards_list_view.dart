import 'dart:io';
import 'package:ecardapp/ecards_store.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'ecard.dart';

class ECardsListView extends StatefulWidget {
  final ECards _ecards;

  const ECardsListView (this._ecards, {super.key});

  @override
  createState() => ECardsListViewState();
}

class ECardsListViewState extends State<ECardsListView> {
  ECardsListViewState();

  @override
  Widget build(BuildContext context) {
    List<ECard> ecardList = widget._ecards.cards.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('My ECards'),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.add), onPressed: _addECard)
        ],
      ),
      body: RadioGroup<String>(
        groupValue: widget._ecards.defaultPublicKey,
        onChanged:  (value) {
          setState(() {
            widget._ecards.defaultPublicKey = value!;
          });
        },
        child: ListView.builder(itemCount: ecardList.length, itemBuilder: (BuildContext context, int i) {
          return _buildECardRow(ecardList[i]);
        })
      )
    );
  }

  void _onDismissed (DismissDirection direction, ECard ecard) {
    widget._ecards.cards.remove(ecard.publicKey);
    if(widget._ecards.cards.isNotEmpty && widget._ecards.defaultPublicKey == ecard.publicKey) {
      setState(() {
        widget._ecards.defaultPublicKey = widget._ecards.cards.keys.first;
      });
    }
    ECardsStore.saveCards(widget._ecards);
  }

  void _addECard() async {
    var fpResult = await FilePicker.pickFile();

    if(fpResult != null) {
      setState(() {
        File f = File(fpResult.path!);
        ECard ecard = ECard.fromJson(f.readAsStringSync());
        widget._ecards.cards[ecard.publicKey] = ecard;
        createImages(ecard);
        if(widget._ecards.cards.length == 1) widget._ecards.defaultPublicKey = ecard.publicKey;
        ECardsStore.saveCards(widget._ecards);
      });
    }
  }

  Widget _buildECardRow(ECard ecard) {
    Text text = Text(ecard.organisation, style: Theme.of(context).textTheme.headlineSmall?.apply(fontWeightDelta: 10));
    ListTile tile;

    tile = ListTile(
      leading: ecard.stampImage,
      title: text,
      onTap: () {_select(ecard);},
      trailing: Radio<String>(value: ecard.publicKey),
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