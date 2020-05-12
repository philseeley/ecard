import 'dart:convert';

class ECard {
  String organisation;
  String publicKey;
  String stamp;
  String qrCode;

  dynamic stampImage;
  dynamic qrCodeImage;

  ECard(this.organisation, this.publicKey, this.stamp, this.qrCode);
  
  static ECard fromData(dynamic data) {
    return ECard(
      data['organisation'],
      data['publickey'],
      data['stamp'],
      data['qrcode']
    );
  }

  static ECard fromJson(String jsonData) {
    return fromData(json.decode(jsonData));
  }

  dynamic toData() {
    return {
      'organisation': organisation,
      'publickey': publicKey,
      "stamp": stamp,
      "qrcode": qrCode
    };
  }

  String toJson() {
    return json.encode(toData());
  }
}