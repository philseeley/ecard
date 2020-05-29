import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:eosdart_ecc/eosdart_ecc.dart';
import 'package:image/image.dart';
import 'package:qr/qr.dart';
import '../lib/ECard.dart';

class GenKeysCommand extends Command {
  final name = 'genkeys';
  final description = 'Generates public/private key pairs';

  void showUsage() {
    print('''$invocation

Where arguments are:
  <organisation name> the name of the organisation the keys are for.
  <key file>          the file to store the generated keys in.
''');
  }

  void run() {
    if(argResults.rest.length != 2) {
      showUsage();
      return;
    }

    String organisation = argResults.rest[0];
    String privateKeyFilename = argResults.rest[1];

    File(privateKeyFilename).writeAsStringSync(json.encode({
      "organisation": organisation,
      "privatekey": EOSPrivateKey.fromRandom().toString()
    }));

    exitCode = 0;
  }
}

class SignQRCommand extends Command {
  final name = 'signqr';
  final description = 'Generates a signed QR code';

  void showUsage() {
    print('''$invocation

Where arguments are:
  <key file>    the name of the key file.
  <stamp file>  the name of the PNG stamp file.
  <data file>   the name of the file containg the data to sign.
  <png file>    the name of the PNG file to output.
  <ecard file>  the name of the ECARD file to output.
''');
  }

  void run() {
    if(argResults.rest.length != 5) {
      showUsage();
      return;
    }

    String privateKeyFilename = argResults.rest[0];
    String stampFilename = argResults.rest[1];
    String dataFilename = argResults.rest[2];
    String pngFilename = argResults.rest[3];
    String ecardFilename = argResults.rest[4];

    Map<String, dynamic> privateKeyData = jsonDecode(File(privateKeyFilename).readAsStringSync());

    EOSPrivateKey privateKey = EOSPrivateKey.fromString(privateKeyData['privatekey']);
    EOSPublicKey publicKey = privateKey.toEOSPublicKey();

    String data = '';
    String lines = File(dataFilename).readAsStringSync().trim();

    LineSplitter.split(lines).forEach((String line) {
      data += line.trim();
    });

    EOSSignature signature = privateKey.signString(data);
    lines += '\n';
    lines += signature.toString();

    QrCode qrCode = QrCode.fromData(data: lines, errorCorrectLevel: QrErrorCorrectLevel.M);
    qrCode.make();

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

    exitCode = 0;
  }
}

void main(args) {
  exitCode = 1;

  CommandRunner('ecard', 'ECard utility')
    ..addCommand(GenKeysCommand())
    ..addCommand(SignQRCommand())
    ..run(args);
}
