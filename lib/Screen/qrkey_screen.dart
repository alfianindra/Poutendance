import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';

class QRPage extends StatefulWidget {
  final double size;

  const QRPage({Key? key, this.size = 200.0}) : super(key: key);

  @override
  _QRPageState createState() => _QRPageState();
}

class _QRPageState extends State<QRPage> {
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    // Generate random string
    String randomString = _generateRandomString(16);
    // Get current user's ID
    String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Combine user ID with random string
    String qrData = "$currentUserUid-$randomString";

    return Scaffold(
      backgroundColor: const Color(0xFF304146),
      body: Stack(
        children: [
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFFEBEEEC),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.8,
                  color: const Color(0xFF3A484C),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: MediaQuery.of(context).size.width * 0.6,
                        color: Colors.transparent,
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: widget.size,
                        ),
                      ),
                      const Positioned(
                        bottom: 20.0,
                        child: Text(
                          'Scan this QR code to swap roles',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
