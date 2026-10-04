import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'ecard.dart';

void createImages(ECard ecard) {
  try {
    ecard.stampImage = Image.memory(base64Decode(ecard.stamp));
  } on Exception {
    debugPrint('Failed to decode stamp');
  }
  try {
    ecard.qrCodeImage = Image.memory(base64Decode(ecard.qrCode));
  } on Exception {
    debugPrint('Failed to decode image');
  }
}

class ECards {
  Map<String,ECard> cards = {};
  String? defaultPublicKey;
}

class ECardsStore {
  static late File _store;

  static Future<ECards> loadCards() async {
    ECards ecards = ECards();

    try {
      Directory directory = await path_provider.getApplicationDocumentsDirectory();
      _store = File('${directory.path}/ecards.json');

      dynamic data = json.decode(_store.readAsStringSync());

      ecards.defaultPublicKey = data['defaultPublicKey'];

      for(dynamic cardData in data['cards']) {
        ECard ecard = ECard.fromData(cardData);
        createImages(ecard);
        ecards.cards[ecard.publicKey] = ecard;
      }
    } catch (e) {
      debugPrint('Failed to store cards $e');
    }

    return ecards;
  }

  static void saveCards (ECards ecards) {
    List<dynamic> cardsData = [];

    dynamic data = {
      'defaultPublicKey': ecards.defaultPublicKey,
      'cards': cardsData
    };

    ecards.cards.forEach((publickey, ecard) {
      cardsData.add(ecard.toData());
    });

    _store.writeAsStringSync(json.encode(data));
  }
}
