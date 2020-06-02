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
    print('''$usage

Where arguments are:
  <organisation name> the name of the organisation the keys are for.
  <key file>          the file to store the generated keys in.
''');
  }

  GenKeysCommand() {
    argParser.addOption('stamp', help: 'the stamp image to use', valueHelp: 'image file');
  }

  void run() {
    if(argResults.rest.length != 2) {
      showUsage();
      return;
    }

    String organisation = argResults.rest[0];
    String privateKeyFilename = argResults.rest[1];
    String stampFilename = argResults['stamp'];

    dynamic data = {
      "organisation": organisation,
      "privatekey": EOSPrivateKey.fromRandom().toString()
    };

    if(stampFilename != null)
      data['stamp'] = base64Encode(File(stampFilename).readAsBytesSync());

    File(privateKeyFilename).writeAsStringSync(json.encode(data));

    exitCode = 0;
  }
}

class SignQRCommand extends Command {
  final name = 'signqr';
  final description = 'Generates a signed QR code';

  void showUsage() {
    print('''$usage

Where arguments are:
  <key file>    the name of the key file.
  <data file>   the name of the file containg the data to sign.
''');
  }

  SignQRCommand() {
    argParser.addOption('stamp', help: 'the stamp image to use', valueHelp: 'image file');
    argParser.addOption('png', help: 'the output PNG filename - defauls to <data file>.png', valueHelp: 'filename');
    argParser.addOption('ecard', help: 'the output ECard filename - defauls to <data file>.ecard', valueHelp: 'filename');
  }

  void run() {
    if(argResults.rest.length != 2) {
      showUsage();
      return;
    }

    String privateKeyFilename = argResults.rest[0];
    String dataFilename = argResults.rest[1];

    int sep = dataFilename.lastIndexOf('.');
    String baseFilename = sep == -1 ? dataFilename : dataFilename.substring(0, sep);

    String stampFilename = argResults['stamp'];
    String pngFilename = argResults['png'];
    String ecardFilename = argResults['ecard'];

    if(pngFilename   == null) pngFilename = '$baseFilename.png';
    if(ecardFilename == null) ecardFilename = '$baseFilename.ecard';

    Map<String, dynamic> privateKeyData = jsonDecode(File(privateKeyFilename).readAsStringSync());

    String stamp;

    if(stampFilename == null)
      stamp = privateKeyData['stamp'];
    else
      stamp = base64Encode(File(stampFilename).readAsBytesSync());

    if(stamp == null) {
      print('No stamp image specified and no stamp image found in "$privateKeyFilename".\n');
      showUsage();
    }

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
      stamp,
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
