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

  static Future<Map<String,ECard>> loadCards() async {
    Directory directory = await path_provider.getApplicationDocumentsDirectory();
    _store = File('${directory.path}/ecards.json');

    Map<String, ECard> ecards = {};

    try {
      dynamic data = json.decode(_store.readAsStringSync());

      for(dynamic cardData in data) {
        ECard ecard = ECard.fromData(cardData);
        createImages(ecard);
        ecards[ecard.publicKey] = ecard;
      }
    } on Exception {}

    return ecards;
  }

  static saveCards (Map<String, ECard> ecards) {
    List<dynamic> data = [];

    ecards.forEach((publickey, ecard) {
      print('SAVING ================ ${ecard.organisation}');
      data.add(ecard.toData());
    });
    _store.writeAsStringSync(json.encode(data));
  }
}