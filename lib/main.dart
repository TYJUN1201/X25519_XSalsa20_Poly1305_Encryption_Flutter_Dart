import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:pinenacl/x25519.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _messageController = TextEditingController();
  String _encryptedMessage = '';
  String _decryptedMessage = '';

  // Message Receiver's private key and public key
  final aliceKeyPair = PrivateKey.generate();
  late final alicePublicKey = aliceKeyPair.publicKey;

  late PublicKey _bobEphemeralPublicKey;
  late EncryptedMessage encryptedMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('X25519_XSalsa20_Poly1305'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _messageController,
              decoration: InputDecoration(labelText: 'Enter your message'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                encryptedMessage = await encryptMessage(_messageController.text, alicePublicKey);
              },
              child: Text('Encrypt'),
            ),
            SizedBox(height: 20),
            SelectableText(
              'Encrypted Message: $_encryptedMessage',
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await decryptMessage(encryptedMessage, aliceKeyPair, _bobEphemeralPublicKey);
              },
              child: Text('Decrypt'),
            ),
            SizedBox(height: 20),
            SelectableText(
              'Decrypted Message: $_decryptedMessage',
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<EncryptedMessage> encryptMessage(String message, PublicKey alicePublicKey) async {
    // Bob generate temporarily key pair
    final ephemeralPrivateKey = PrivateKey.generate();
    // Generate public key using private key
    final ephemeralPublicKey = ephemeralPrivateKey.publicKey;
    //final metamaskPublicKey = PublicKey(base64.decode('I6ImWAYwdzP2dUN4/juCPKZ4qLRA5bETOvFGa3yU8Rc='));

    // Bob using his temporarily private key and Alice's public key to encrypt message
    final box = Box(myPrivateKey: ephemeralPrivateKey, theirPublicKey: alicePublicKey);
    final encrypted = box.encrypt((Uint8List.fromList(message.codeUnits)));

    final result = {
      "version": "x25519-xsalsa20-poly1305",
      "nonce": base64.encode(encrypted.nonce),
      "ephemPublicKey": base64.encode(ephemeralPublicKey.asTypedList),
      "ciphertext": base64.encode(encrypted.cipherText),
    };

    String utf8String = jsonEncode(result);
    print(utf8String);
    String hexString = hex.encode(utf8.encode(utf8String));
    print('Encrypted Message: 0x$hexString');

    setState(() {
      _encryptedMessage = '0x$hexString';
      _bobEphemeralPublicKey = ephemeralPublicKey;
    });

    return encrypted;
  }


  Future<void> decryptMessage(EncryptedMessage encryptedMessage, PrivateKey alicePrivateKey, PublicKey bobEphemeralPublicKey) async {
    final box = Box(myPrivateKey: alicePrivateKey, theirPublicKey: bobEphemeralPublicKey);
    final decrypted = box.decrypt(encryptedMessage.cipherText, nonce: Uint8List.fromList(encryptedMessage.nonce));

    String decryptedMessage = utf8.decode(decrypted);
    print('Decrypted Message: $decryptedMessage');

    setState(() {
      _decryptedMessage = decryptedMessage;
    });
  }
}