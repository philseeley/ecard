import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'ECard.dart';

void createImages(ECard ecard) {
  try {
    ecard.stampImage = Image.memory(base64Decode(ecard.stamp));
  } on Exception {}
  try {
    ecard.qrCodeImage = Image.memory(base64Decode(ecard.qrCode));
  } on Exception {}
}

class ECardsStore {
  static File _store;

  static Future<List<ECard>> loadCards() async {
    Directory directory = await path_provider.getApplicationDocumentsDirectory();
    _store = File('${directory.path}/ecards.json');

    List<ECard> ecards = [];

    try {
      dynamic data = json.decode(_store.readAsStringSync());

      for(dynamic cardData in data) {
        ECard ecard = ECard.fromData(cardData);
        createImages(ecard);
        ecards.add(ecard);
      }
    } on Exception {}

    return ecards;
  }

  static saveCards (List<ECard> ecards) {
    List<dynamic> data = [];

    for(ECard ecard in ecards) {
      print('SAVING ================ ${ecard.name}');
      data.add(ecard.toData());
    }
    _store.writeAsStringSync(json.encode(data));
  }
}