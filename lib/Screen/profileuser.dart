import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String npm = 'no-npm found';

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
          npm = userDoc['npm'] ?? 'no-npm found';

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

  Future<void> _changeName(String newName) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'username': newName});
      setState(() {
        username = newName;
      });
      print('Username updated successfully');
    } catch (e) {
      print('Error updating username: $e');
    }
  }

  Future<void> _changeEmail(String newEmail) async {
    try {
      await user!.verifyBeforeUpdateEmail(newEmail);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification link sent to new email. Please verify to complete the change.',
          ),
        ),
      );
    } catch (e) {
      print('Error sending verification email: $e');
    }
  }

  Future<void> _changeFaculty(String newFaculty) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'faculty': newFaculty});
      setState(() {
        faculty = newFaculty;
      });
      print('Faculty updated successfully');
    } catch (e) {
      print('Error updating faculty: $e');
    }
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
                        username ?? 'Loading...',
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
                  Spacer(),
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
                      padding: EdgeInsets.symmetric(vertical: 10),
                      children: [
                        SizedBox(height: 20),
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage('assets/perahu.jpg'),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              username ?? 'No username',
                              textAlign: TextAlign.center,
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
                          faculty ?? 'No Fakultas',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                        SizedBox(height: 10),
                        Text(
                          user?.email ?? 'No email',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                        SizedBox(height: 20),
                        Divider(
                          color: Colors.white,
                        ),
                        buildItemInformation(
                          username: username,
                          label: "Name",
                          onPressed: () => _showChangeNameDialog(context),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        buildItemInformation(
                          username: faculty,
                          label: "Fakultas",
                          onPressed: () => _showChangeFacultyDialog(context),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        buildItemInformation(
                          username: user!.email!,
                          label: "Email",
                          onPressed: () => _showChangeEmailDialog(context),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        buildItemInformation(
                          username: "*****",
                          label: "Password",
                          onPressed: _changePassword,
                        ),
                        SizedBox(
                          height: 10,
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
                          onPressed: _logout,
                          child: Text('Change Account'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white),
                          onPressed: _deleteAccount,
                          child: Text('Delete Account'),
                        ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: Text('No user logged in'),
                ),
    );
  }

  // Method to show dialog for changing name
  Future<void> _showChangeNameDialog(BuildContext context) async {
    TextEditingController _nameController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Name'),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(hintText: "Enter new name"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                String newName = _nameController.text.trim();
                if (newName.isNotEmpty) {
                  _changeName(newName);
                  Navigator.of(context).pop();
                } else {
                  // Handle case where input is empty
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Method to show dialog for changing faculty
  Future<void> _showChangeFacultyDialog(BuildContext context) async {
    TextEditingController _facultyController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Faculty'),
          content: TextField(
            controller: _facultyController,
            decoration: InputDecoration(hintText: "Enter new faculty"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                String newFaculty = _facultyController.text.trim();
                if (newFaculty.isNotEmpty) {
                  _changeFaculty(newFaculty);
                  Navigator.of(context).pop();
                } else {
                  // Handle case where input is empty
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Method to show dialog for changing email
  Future<void> _showChangeEmailDialog(BuildContext context) async {
    TextEditingController _emailController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Email'),
          content: TextField(
            controller: _emailController,
            decoration: InputDecoration(hintText: "Enter new email"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                String newEmail = _emailController.text.trim();
                if (newEmail.isNotEmpty) {
                  _changeEmail(newEmail);
                  Navigator.of(context).pop();
                } else {
                  // Handle case where input is empty
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class buildItemInformation extends StatelessWidget {
  final String? username;
  final String? label;
  final Function()? onPressed;

  buildItemInformation({Key? key, this.username, this.label, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label!,
              style: TextStyle(color: Colors.white),
            ),
            Text(
              username!,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xff56727B),
            foregroundColor: Colors.white,
          ),
          onPressed: onPressed,
          child: Text(
            'Change',
          ),
        ),
      ],
    );
  }
}
