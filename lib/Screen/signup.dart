import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:poutendance/widget/button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poutendance/Screen/Login.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _confirmPasswordTextController =
      TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _userTextController = TextEditingController();
  TextEditingController _facultyTextController = TextEditingController();

  String _errorMessage = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/perahu.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(8.0),
                        color: Colors.red,
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        border: Border.all(
                          color: Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Username',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "",
                              hintText: "Username",
                            ),
                            controller: _userTextController,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "",
                              hintText: "email@example.com",
                            ),
                            controller: _emailTextController,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Faculty',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "",
                              hintText: "Faculty",
                            ),
                            controller: _facultyTextController,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            controller: _passwordTextController,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Confirm Password',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            controller: _confirmPasswordTextController,
                          ),
                          SizedBox(height: 16),
                          firebaseUIButton(context, 'Sign Up', () async {
                            if (_passwordTextController.text !=
                                _confirmPasswordTextController.text) {
                              setState(() {
                                _errorMessage = "Passwords do not match";
                              });
                              return;
                            }

                            try {
                              UserCredential userCredential = await FirebaseAuth
                                  .instance
                                  .createUserWithEmailAndPassword(
                                email: _emailTextController.text,
                                password: _passwordTextController.text,
                              );

                              var usernameQuery = await FirebaseFirestore
                                  .instance
                                  .collection('users')
                                  .where('username',
                                      isEqualTo: _userTextController.text)
                                  .get();

                              if (usernameQuery.docs.isNotEmpty) {
                                setState(() {
                                  _errorMessage = "Username already in use";
                                });
                                return;
                              }

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userCredential.user?.uid)
                                  .set({
                                'username': _userTextController.text,
                                'email': _emailTextController.text,
                                'faculty': _facultyTextController.text,
                                'role': 'user',
                              });

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SignInScreen()),
                              );
                            } on FirebaseAuthException catch (error) {
                              setState(() {
                                if (error.code == 'email-already-in-use') {
                                  _errorMessage = "Email already in use";
                                } else {
                                  _errorMessage = "Error: ${error.message}";
                                }
                              });
                            } catch (error) {
                              setState(() {
                                _errorMessage = "Error: ${error.toString()}";
                              });
                            }
                          }),
                          signUpOption()
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Row signUpOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already Have Account?",
            style: TextStyle(color: Colors.white)),
        GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => SignInScreen()));
          },
          child: const Text(
            " Sign In",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }
}