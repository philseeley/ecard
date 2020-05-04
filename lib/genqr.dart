import 'dart:io';
import 'package:eosdart_ecc/eosdart_ecc.dart';

void main() {
  EOSPrivateKey privateKey = EOSPrivateKey.fromString('5KEQgeL4EwjuEAyPQBoaJYVrbt5kSUsrwXPkjzAQTPiNoUxxeS8');

  File f = File('test.txt');
  String data = f.readAsStringSync();

  EOSSignature sig = privateKey.signString(data);
  data += sig.toString();
  print(data);
}
