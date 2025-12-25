import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_session/Home.dart';
import 'sql.dart';
import 'login.dart';

class signupApp extends StatefulWidget {
  signupApp({super.key});

  @override
  State<signupApp> createState() => Signup();
}

bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}

class Signup extends State<signupApp> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmationController = TextEditingController();
  final SqlData db = SqlData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              Container(
                height: 120,
                width: double.infinity,
                alignment: Alignment.center,
                child: const CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage("assets/castaway.jpeg"),
                  backgroundColor: Colors.transparent,
                ),
              ),

              const SizedBox(height: 25),
              const Text(
                'Sign Up',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: confirmationController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  bool go = true;

                  if (passwordController.text != confirmationController.text) {
                    go = false;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Passwords don't match")),
                    );
                  }
                  if (!isValidEmail(emailController.text)) {
                    go = false;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Wrong Email Format")),
                    );
                  }

                  if (go) {
                    String e = emailController.text.trim();
                    String p = passwordController.text.trim();
                    String u = usernameController.text.trim();

                    try {
                      UserCredential user = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(email: e, password: p);
                      User? u=user.user;
                      if(u!=null){
                        String?id=u.uid;
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(id)
                            .set({
                          'name': usernameController.text,
                          'bio':"",
                          'picurl':""
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Account created!")),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HomeApp(title:usernameController.text )),
                        );
                      }

                    } catch (err) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("DB Error: $err")),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Sign Up'),
              ),

              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SigninApp()),
                        );
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
