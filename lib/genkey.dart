import 'package:eosdart_ecc/eosdart_ecc.dart';

void main() {
  EOSPrivateKey privateKey = EOSPrivateKey.fromRandom();
  print('Private: $privateKey');
  print('Public: ${privateKey.toEOSPublicKey()}');
}
