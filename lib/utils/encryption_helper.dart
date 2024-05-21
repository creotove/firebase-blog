import 'package:encrypt/encrypt.dart';

class EncryptionHelper {
  static String decryptMessage(String encrypted) {
    final key =
        Key.fromUtf8("1245714587458888"); //hardcode combination of 16 character
    final iv =
        IV.fromUtf8("e16ce888a20dadb8"); //hardcode combination of 16 character

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    Encrypted enBase64 = Encrypted.from64(encrypted);
    final decrypted = encrypter.decrypt(enBase64, iv: iv);
    return decrypted;
  }

  static String encryptMessage(String value) {
    final key = Key.fromUtf8("1245714587458888"); //hardcode
    final iv = IV.fromUtf8("e16ce888a20dadb8"); //hardcode

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(value, iv: iv);

    return encrypted.base64;
  }
}
