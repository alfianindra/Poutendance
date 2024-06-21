import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:poutendance/Screen/Login.dart';
import 'package:poutendance/Screen/qrkey_scan.dart';

class ProfileScan extends StatefulWidget {
  const ProfileScan({Key? key}) : super(key: key);

  @override
  _ProfileScanState createState() => _ProfileScanState();
}

class _ProfileScanState extends State<ProfileScan> {
  String? username;
  User? user;
  String? role;
  bool isLoading = true;
  String? faculty;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        setState(() {
          username = userDoc['username'];
          role = userDoc['role'];
          faculty = userDoc['faculty'];
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        print('Error fetching user details: $e');
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .delete();
      await user!.delete();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    } catch (e) {
      print('Error deleting account: $e');
    }
  }

  Future<void> _changePassword() async {
    String newPassword = 'newPassword123';
    try {
      await user!.updatePassword(newPassword);
      print('Password updated successfully');
    } catch (e) {
      print('Error updating password: $e');
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff304146),
      appBar: AppBar(
        toolbarHeight: 170,
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xff304146),
        flexibleSpace: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/header.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30, left: 20.0, right: 20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30, // Radius untuk leading
                    backgroundImage: AssetImage('assets/perahu.jpg'),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username ??
                            'Loading...', // Menghindari null dengan memberikan nilai default
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Fakultas Teknik!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Spacer(), // Membuat jarak antara username dan actions
                  IconButton(
                    onPressed: () {
                      _logout();
                    },
                    icon: Icon(
                      Icons.logout,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : user != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Color(0xff3A484C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView(
                      children: [
                        SizedBox(height: 20),
                        CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              AssetImage('assets/perahu.jpg') as ImageProvider,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              textAlign: TextAlign.center,
                              username ?? 'No username',
                              style: TextStyle(
                                fontSize: 32,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            role == "holder"
                                ? Image.asset('assets/Key.png')
                                : SizedBox(),
                          ],
                        ),
                        Text(
                          textAlign: TextAlign.center,
                          faculty ?? 'No Fakultas',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                        SizedBox(height: 10),
                        Text(
                          textAlign: TextAlign.center,
                          user?.email ?? 'No email',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                        SizedBox(height: 20),
                        Divider(
                          color: Colors.white,
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => QRKeyScanPage()),
                            );
                          },
                          child: Text('Scan The QR'),
                        ),
                        ElevatedButton(
                          onPressed: _deleteAccount,
                          child: Text('Delete Account'),
                        ),
                      ],
                    ),
                  ),
                )
              : Center(child: Text('No user logged in')),
    );
  }
}
