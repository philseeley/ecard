import 'dart:convert';
import 'dart:io';
import 'package:eosdart_ecc/eosdart_ecc.dart';
import 'package:image/image.dart';
import 'package:qr/qr.dart';
import 'ECard.dart';

void main(List<String> args) {
  String privateKeyFilename = args[0];
  String stampFilename = args[1];
  String dataFilename = args[2];
  String pngFilename = args[3];
  String ecardFilename = args[4];

  Map<String, dynamic> privateKeyData = jsonDecode(File(privateKeyFilename).readAsStringSync());

  EOSPrivateKey privateKey = EOSPrivateKey.fromString(privateKeyData['privatekey']);
  EOSPublicKey publicKey = privateKey.toEOSPublicKey();

  String data = File(dataFilename).readAsStringSync().trim();
  data += '\n';

  EOSSignature signature = privateKey.signString(data);
  data += signature.toString();

  QrCode qrCode;
  int type = 1;

  while (true) {
    try {
      qrCode = QrCode(type, QrErrorCorrectLevel.M);
      qrCode.addData(data);
      qrCode.make();
      break;
    } catch (e) {
      ++type;
      if(type > 40)
        throw ArgumentError('"$dataFilename" to big to encode');
    }
  }

  int size = qrCode.moduleCount;

  int white = getColor(255, 255, 255);
  int black = getColor(0, 0, 0);

  int sq = 3;
  int br = 10;
  Image qrCodeImage = Image(size*sq+2*br, size*sq+2*br);
  qrCodeImage.fill(white);

  for (int x = 0; x < size; x++) {
    for (int y = 0; y < size; y++) {
      int color = qrCode.isDark(y, x) ? black : white;
      for (int sx = 0; sx < sq; ++sx) {
        for (int sy = 0; sy < sq; ++sy) {
          qrCodeImage.setPixelSafe(x*sq+sx+br, y*sq+sy+br, color);
        }
      }
    }
  }

  List<int> qrCodeImageData = encodePng(qrCodeImage);

  File(pngFilename).writeAsBytesSync(qrCodeImageData);

  ECard ecard = ECard(
    privateKeyData['organisation'],
    publicKey.toString(),
    base64Encode(File(stampFilename).readAsBytesSync()),
    base64Encode(qrCodeImageData)
  );

  File(ecardFilename).writeAsStringSync(ecard.toJson());
}
