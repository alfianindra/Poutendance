import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poutendance/Screen/login.dart';
import 'package:poutendance/Screen/profilekey.dart';
import 'package:poutendance/Screen/profileuser.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? username;
  String? initials;
  String? role;
  bool isHolderCheckedIn = false;
  bool isUserCheckedIn = false;

  @override
  void initState() {
    super.initState();
    _getUsername();
    _checkHolderStatus();
  }

  Future<void> _getUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        username = userDoc['username'];
        role = userDoc['role'];
        initials = _getInitials(userDoc['username']);
      });
    }
  }

  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    String initials = '';
    for (String part in nameParts) {
      if (part.isNotEmpty) {
        initials += part[0];
      }
    }
    return initials.toUpperCase();
  }

  Future<void> _checkHolderStatus() async {
    QuerySnapshot holderDocs = await FirebaseFirestore.instance
        .collection('checkin')
        .where('role', isEqualTo: 'holder')
        .where('checked_in', isEqualTo: true)
        .get();
    if (holderDocs.docs.isNotEmpty) {
      setState(() {
        isHolderCheckedIn = true;
      });
    }
  }

  Future<void> _checkIn() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String docPath = 'checkin/${user.uid}';
      await FirebaseFirestore.instance.doc(docPath).set({
        'username': username,
        'initials': initials,
        'check_in': DateTime.now(),
        'checked_in': true,
        'role': role,
      });
      setState(() {
        if (role == 'holder') {
          isHolderCheckedIn = true;
        }
        isUserCheckedIn = true;
      });
    }
  }

  Future<void> _checkOut() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String docPath = 'checkin/${user.uid}';
      await FirebaseFirestore.instance.doc(docPath).update({
        'check_out': DateTime.now(),
        'checked_in': false,
      });
      setState(() {
        if (role == 'holder') {
          isHolderCheckedIn = false;
        }
        isUserCheckedIn = false;
      });
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _navigateToProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        String role = userDoc['role'];
        if (role == 'user') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScan()),
          );
        } else if (role == 'holder') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Role tidak terdata')),
          );
        }
      } catch (e) {
        print('Error fetching user role: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: username == null
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome, $username!',
                    style: TextStyle(fontSize: 24),
                  ),
                  Text(
                    'Role: $role',
                    style: TextStyle(fontSize: 24),
                  ),
                  SizedBox(height: 20),
                  if (role == 'holder') ...[
                    ElevatedButton(
                      onPressed: isHolderCheckedIn ? _checkOut : _checkIn,
                      child: Text(isHolderCheckedIn ? 'Check Out' : 'Check In'),
                    ),
                  ] else if (role == 'user') ...[
                    ElevatedButton(
                      onPressed: isHolderCheckedIn && !isUserCheckedIn
                          ? _checkIn
                          : (isUserCheckedIn ? _checkOut : null),
                      child: Text(isUserCheckedIn ? 'Check Out' : 'Check In'),
                    ),
                  ],
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _signOut,
                    child: Text('Sign Out'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _navigateToProfile,
                    child: Text('Go to Profile'),
                  ),
                ],
              ),
      ),
    );
  }
}
