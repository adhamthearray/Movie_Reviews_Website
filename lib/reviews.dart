import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_session/sharedpref.dart';
import 'package:project_session/signup.dart';
import 'package:project_session/login.dart';
import 'package:project_session/sql.dart';

class reviewsApp extends StatefulWidget {
  const reviewsApp({super.key, required this.mid});
  final String mid;

  @override
  State<reviewsApp> createState() => _review();
}

class _review extends State<reviewsApp> {
  final TextEditingController reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text("Reviews", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('movie', isEqualTo: widget.mid)
        //.orderBy('timestamp', descending: true) // optional
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                CircularProgressIndicator(color: Colors.deepPurple));
          }

          if (snapshot.hasError) {
            return Center(
                child: Text("Error: ${snapshot.error}",
                    style: const TextStyle(color: Colors.white)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("No reviews yet",
                    style: TextStyle(color: Colors.white70)));
          }

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final data = reviews[index].data() as Map<String, dynamic>;

              return Card(
                color: Colors.grey.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 6,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .where('name', isEqualTo: data['user'])
                        .limit(1)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        );
                      }

                      if (userSnapshot.hasError) {
                        return const CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Icon(Icons.error, color: Colors.white),
                        );
                      }

                      if (!userSnapshot.hasData ||
                          userSnapshot.data!.docs.isEmpty) {
                        return const CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Icon(Icons.person, color: Colors.white),
                        );
                      }

                      final userData = userSnapshot.data!.docs.first.data()
                      as Map<String, dynamic>;
                      final picUrl = userData['picurl'];
                      print(picUrl);

                      return CircleAvatar(
                        child: ClipOval(
                          child: Image.network(
                            picUrl,
                            fit: BoxFit.contain,
                            width: 200,
                            height: 200,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: Colors.white54,
                                size: 30,
                              );
                            },
                          ),
                        ),
                        

                        
                      );
                    },
                  ),
                  title: Text(
                    data['log'] ?? 'No text',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                  subtitle: Text(
                    "${data['user'] ?? ''}",
                    style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
