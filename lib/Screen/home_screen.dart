import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:poutendance/Screen/login.dart';
import 'package:poutendance/Screen/profilekey.dart';
import 'package:intl/intl.dart';

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

  String formattedDate =
      DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());

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
      backgroundColor: Color(0xff304146),
      appBar: AppBar(
        backgroundColor: Color(0xff304146),
        toolbarHeight: 179, // Tinggi AppBar
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
              padding:
                  const EdgeInsets.only(top: 30.0, left: 20.0, right: 20.0),
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
                        username ?? 'load username',
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
                  Image.asset(
                    'assets/actions.png', // Ganti dengan path gambar yang ingin Anda gunakan
                    height: 60,
                    width: 60,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: username == null
          ? CircularProgressIndicator()
          : Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color(0xff56727B)),
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 10),
                children: [
                  Row(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
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
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text('Close'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 25,
                            )),
                      ),
                      SizedBox(
                        width: 100,
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Attendance',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                  Text(
                    textAlign: TextAlign.center,
                    formattedDate,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  StreamBuilder<String>(
                    stream: Stream.periodic(Duration(seconds: 1), (_) {
                      return DateFormat('HH:mm:ss').format(DateTime.now());
                    }),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          textAlign: TextAlign.center,
                          snapshot.data!,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        );
                      } else {
                        return Text(
                          textAlign: TextAlign.center,
                          'Loading...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        );
                      }
                    },
                  ),
                  Image.asset(
                    'assets/map.png',
                    height: 200,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person,
                        color: Color(0xff304146),
                      ),
                      Text(
                        'Who is in the secre?',
                      )
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  if (role == 'holder') ...[
                    ElevatedButton(
                      onPressed: isHolderCheckedIn
                          ? () {
                              _checkOut();
                            }
                          : () {
                              _checkIn();
                            },
                      child: Text(isHolderCheckedIn ? 'Check Out' : 'Check In'),
                    ),
                  ] else if (role == 'user') ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff7B9BA4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      onPressed: isHolderCheckedIn && !isUserCheckedIn
                          ? _checkIn
                          : (isUserCheckedIn ? _checkOut : () {}),
                      child: Text(
                        isHolderCheckedIn && isUserCheckedIn
                            ? 'Check Out'
                            : !isHolderCheckedIn && !isUserCheckedIn
                                ? "The Secretariat is currently closed"
                                : "Checkin",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person,
                        color: Color(0xff304146),
                      ),
                      Text(
                        'Attendance History',
                      )
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('checkin')
                        .where('username', isEqualTo: username)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      var documents = snapshot.data!.docs;
                      return ListView.separated(
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.white,
                          height: 2,
                        ),
                        shrinkWrap: true,
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          var document = documents[index];
                          var data = document.data() as Map<String, dynamic>;
                          Timestamp timestamp = data['check_in'];

                          DateTime dateTime = timestamp.toDate();
                          String jamCheckout = '';
                          String jam = DateFormat('HH:mm').format(dateTime);
                          if (data['check_out'] != null) {
                            Timestamp timestampCheckou = data['check_out'];
                            DateTime dateTimeCheckout =
                                timestampCheckou.toDate();

                            jamCheckout =
                                DateFormat('-HH:mm').format(dateTimeCheckout) ??
                                    '';
                          }
                          String tanggal =
                              DateFormat('EEEE, dd MMMM yyyy').format(dateTime);

                          return ListTile(
                            title: Text(
                              '${data['username']}',
                              style: TextStyle(color: Colors.white),
                            ),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${tanggal}',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${jam}${jamCheckout}',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
