import 'dart:convert';

class ECard {
  String name;
  String publicKey;
  String stamp;
  String qrCode;

  dynamic stampImage;
  dynamic qrCodeImage;

  ECard(this.name, this.publicKey, this.stamp, this.qrCode);
  
  static ECard fromData(dynamic data) {
    print('LOADING ======================== ${data['name']}');
    return ECard(
      data['name'],
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
      'name': name,
      'publickey': publicKey,
      "stamp": stamp,
      "qrcode": qrCode
    };
  }

  String toJson() {
    return json.encode(toData());
  }
}
