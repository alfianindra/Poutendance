import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRKeyScanPage extends StatefulWidget {
  const QRKeyScanPage({Key? key}) : super(key: key);

  @override
  _QRKeyScanPageState createState() => _QRKeyScanPageState();
}

class _QRKeyScanPageState extends State<QRKeyScanPage> {
  late QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool isLoading = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        child: QRView(
                          key: qrKey,
                          onQRViewCreated: _onQRViewCreated,
                        ),
                      ),
                      const Positioned(
                        bottom: 20.0,
                        child: Text(
                          'Scan QR Key',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      if (isLoading)
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black54,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
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

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      String? scannedData = scanData.code;
      if (scannedData != null && scannedData.isNotEmpty) {
        controller.pauseCamera();
        bool? confirmed = await _showConfirmationDialog(scannedData);
        if (confirmed == true) {
          setState(() {
            isLoading = true;
          });
          await _updateUserRole(scannedData);
          setState(() {
            isLoading = false;
          });
          controller.resumeCamera();
        } else {
          controller.resumeCamera();
        }
      }
    });
  }

  Future<void> _updateUserRole(String scannedData) async {
    try {
      // Get current user's ID
      String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Extract holder's UID from scanned data
      String holderUid = scannedData.split('-')[0];

      // Update holder's role to 'user'
      await FirebaseFirestore.instance.collection('users').doc(holderUid).update({'role': 'user'});

      // Update current user's role to 'holder'
      await FirebaseFirestore.instance.collection('users').doc(currentUserUid).update({'role': 'holder'});

      print('Roles updated successfully');
    } catch (e) {
      print('Error updating roles: $e');
    }
  }

  Future<bool?> _showConfirmationDialog(String scannedData) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Role Change'),
          content: Text('Do you want to change roles with the user who created this QR code?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}
