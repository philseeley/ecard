import 'dart:io';
import 'package:eosdart_ecc/eosdart_ecc.dart';

void main(List<String> args) {
  String privateKeyFilename = args[0];
  File(privateKeyFilename).writeAsStringSync(EOSPrivateKey.fromRandom().toString());
}
