import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; // Import geocoding
import 'package:poutendance/Screen/profilekey.dart';
import 'login.dart'; // Adjust this import as per your project structure
import 'profileuser.dart'; // Adjust this import as per your project structure

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
  LatLng? currentLocation;
  String? address;
  double? distance;
  GoogleMapController? mapController;

  String formattedDate =
      DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _getUsername();
    _checkHolderStatus();
    _getCurrentLocation();
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

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await _determinePosition();
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });
      _getAddressFromLatLng(position.latitude, position.longitude);
      _calculateDistance(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied, we cannot request permissions.';
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw 'Location permissions are denied (actual value: $permission).';
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      Placemark place = placemarks[0];
      setState(() {
        address =
            '${place.name}, ${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
      });
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        address = 'Could not fetch address';
      });
    }
  }

  void _calculateDistance(double lat1, double lon1) {
    if (currentLocation != null) {
      distance = Geolocator.distanceBetween(
          lat1, lon1, -6.168725659586274, 106.78986055591318);
    }
  }

  Future<void> _checkIn() async {
    if (currentLocation != null) {
      double distance = Geolocator.distanceBetween(currentLocation!.latitude,
          currentLocation!.longitude, -6.168725659586274, 106.78986055591318);

      if (distance <= 200) {
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are not within the check-in area.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not determine current location.')),
      );
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
            MaterialPageRoute(builder: (context) => ProfileScreen()),
          );
        } else if (role == 'holder') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Role not recognized')),
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
        toolbarHeight: 179,
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
                    radius: 30,
                    backgroundImage: AssetImage('assets/perahu.jpg'),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username ?? 'Loading username',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Role: ${role ?? 'Loading role'}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Image.asset(
                    'assets/actions.png',
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
          ? Center(child: CircularProgressIndicator())
          : Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Color(0xff56727B),
              ),
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
                          ),
                        ),
                      ),
                      SizedBox(width: 100),
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
                    formattedDate,
                    textAlign: TextAlign.center,
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
                          snapshot.data!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        );
                      } else {
                        return Text(
                          'Loading...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  // Informasi Posisi Pengguna
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[300],
                    ),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Position:',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 10),
                        if (currentLocation != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Latitude: ${currentLocation!.latitude}',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Longitude: ${currentLocation!.longitude}',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Address: ${address ?? 'Loading...'}',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Distance to check-in location: ${distance?.toStringAsFixed(2) ?? 'Calculating...'} meters',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  // Google Maps Widget
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[300],
                    ),
                    child: GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        mapController = controller;
                      },
                      initialCameraPosition: CameraPosition(
                        target: currentLocation ?? LatLng(-6.1689, 106.7898),
                        zoom: 15,
                      ),
                      markers: Set.from([
                        Marker(
                          markerId: MarkerId('currentLocation'),
                          position:
                              currentLocation ?? LatLng(-6.1689, 106.7898),
                          infoWindow: InfoWindow(title: 'Your Location'),
                        ),
                      ]),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Check-in / Check-out buttons based on user role
                  if (role == 'holder')
                    ElevatedButton(
                      onPressed: isHolderCheckedIn ? _checkOut : _checkIn,
                      child: Text(isHolderCheckedIn ? 'Check-Out' : 'Check-In'),
                    ),
                  if (role == 'user')
                    ElevatedButton(
                      onPressed: isHolderCheckedIn
                          ? (isUserCheckedIn ? _checkOut : _checkIn)
                          : null,
                      child: Text(isUserCheckedIn ? 'Check-Out' : 'Check-In'),
                    ),
                ],
              ),
            ),
    );
  }
}
