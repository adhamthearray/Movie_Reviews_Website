import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_session/signup.dart';

import 'package:project_session/Home.dart';
import 'package:project_session/sql.dart';
import 'package:project_session/sharedpref.dart';

class SigninApp extends StatefulWidget {
  const SigninApp({super.key});

  @override
  State<SigninApp> createState() => _Signin();
}

class _Signin extends State<SigninApp>  {
  bool isOn = false;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final SqlData db = SqlData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14181C), // dark letterboxd vibe
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // App "cinematic" logo
              CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage("assets/wilson-castaway-ball.jpg"),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(height: 25),

              const Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue your movie journey',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 30),

              // Email field
              TextField(
                controller: usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E2429),
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E2429),
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Switch(
                    value: isOn,
                    onChanged: (value) {
                      setState(() => isOn = value);
                    },
                    activeColor: Colors.tealAccent,
                  ),
                  const Text('Remember me', style: TextStyle(color: Colors.grey)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => print("Forgot tapped"),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Sign in button
              ElevatedButton(
                onPressed: () async {
                  String email = usernameController.text;
                  String password = passwordController.text;
                  try {
                    UserCredential credential = await FirebaseAuth.instance
                        .signInWithEmailAndPassword(
                        email: email, password: password);
                    if (isOn) {
                     // await SharedPref.saveUser(email); // your sharedpref helper
                    }
                    User? u=credential.user;
                    String? id=u?.uid;
                    final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
                    if(doc.exists&&doc.data()!=null) {
                      print('ana hena');
                      String name=doc['name'];
                      SharedPrefs.setLoggedIn(true);
                      SharedPrefs.setUsername(name);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) =>
                         HomeApp(title: name)),
                      );
                    }
                    else{
                      print('Nope Not here');
                    }
                  }
                  on FirebaseAuthException catch (e){
                    print('NO account');

                  }




                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Sign In', style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 15),
              const Text('OR', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 15),

              // Social logins
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Continue with Facebook'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {

                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Continue with Google'),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'New here? ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => signupApp()),
                      );
                    } ,
                    child: const Text(
                      'Create an account',
                      style: TextStyle(
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
