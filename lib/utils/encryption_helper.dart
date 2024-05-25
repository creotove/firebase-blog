import 'package:encrypt/encrypt.dart';

// Helper class to encrypt and decrypt messages
class EncryptionHelper {
  // Method to decrypt the message
  // Currently, the key and iv are hardcoded
  static String decryptMessage(String encrypted) {
    final key =
        Key.fromUtf8("1245714587458888"); //hardcode combination of 16 character
    final iv =
        IV.fromUtf8("e16ce888a20dadb8"); //hardcode combination of 16 character

    // Create an instance of the encrypter
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    // Decrypt the message
    Encrypted enBase64 = Encrypted.from64(encrypted);
    // Convert the decrypted message to string and return
    final decrypted = encrypter.decrypt(enBase64, iv: iv);
    return decrypted;
  }

  // Method to encrypt the message
  static String encryptMessage(String value) {
    final key = Key.fromUtf8("1245714587458888"); //hardcode
    final iv = IV.fromUtf8("e16ce888a20dadb8"); //hardcode

    // Create an instance of the encrypter
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    // Encrypt the message and return
    final encrypted = encrypter.encrypt(value, iv: iv);

    return encrypted.base64;
  }
}
