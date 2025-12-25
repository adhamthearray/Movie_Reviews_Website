import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_session/service.dart';
import 'package:project_session/signup.dart';
import 'package:project_session/Home.dart';
import 'package:project_session/sql.dart';
import 'package:project_session/sharedpref.dart';

class testApp extends StatefulWidget {
  const testApp({super.key});

  @override
  State<testApp> createState() => tst();
}

class tst extends State<testApp> {
  final tmdb = TMDBService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              // Call TMDB
              final movies = await tmdb.getTrendingMovies();

              // Print the first movie title
            } catch (e) {
              print("Error: $e");
            }
          },
          child: const Text('Press'),
        ),
      ),
    );
  }
}
