import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poutendance/Screen/Login.dart';
import 'package:poutendance/Screen/qrkey_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? username;
  String? faculty;
  String? role;
  User? user;
  bool isLoading = true;

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
          faculty = userDoc['faculty'];
          role = userDoc['role'];
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
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).delete();
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
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : user != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: user!.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : AssetImage('assets/perahu.jpg') as ImageProvider,
                        ),
                        SizedBox(height: 20),
                        Text(
                          username ?? 'No username',
                          style: TextStyle(fontSize: 32),
                        ),
                        SizedBox(height: 10),
                        Text(
                          user!.email ?? 'No email',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        Text(
                          faculty ?? 'No faculty',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        Text(
                          role ?? 'No role',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => QRPage()), 
                            );
                          },
                          child: Text('Pass The Key'),
                        ),
                        ElevatedButton(
                          onPressed: _deleteAccount,
                          child: Text('Delete Account'),
                        ),
                        ElevatedButton(
                          onPressed: _logout,
                          child: Text('Log Out'),
                        ),
                      ],
                    ),
                  ),
                )
              : Center(child: Text('No user logged in')),
    );
  }
}
