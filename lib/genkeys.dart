import 'dart:io';
import 'dart:convert';
import 'package:eosdart_ecc/eosdart_ecc.dart';

void main(List<String> args) {
  String organisation = args[0];
  String privateKeyFilename = args[1];

  File(privateKeyFilename).writeAsStringSync(json.encode({
    "organisation": organisation,
    "privatekey": EOSPrivateKey.fromRandom().toString()
  }));
}
