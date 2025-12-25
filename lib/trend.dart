import 'package:flutter/material.dart';
import 'package:project_session/Home.dart';
import 'package:project_session/service.dart';
import 'package:project_session/sharedpref.dart';
import 'package:project_session/signup.dart';
import 'package:project_session/sql.dart';

import 'login.dart';
import 'movie_view.dart';

class trendApp extends StatefulWidget {
  const trendApp({super.key, required this.title});
  final String title;

  @override
  State<trendApp> createState() => trend();
}

class trend extends State<trendApp> {
  final SqlData db = SqlData();
  final tmdb = TMDBService();


  Future<List<dynamic>> gettrend() async {
    try {
      final movies = await tmdb.getTrendingMovies(); // pulls directly from TMDB
      return movies;
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.red,
        leading: IconButton(
          onPressed: () {

            Navigator.pop(context);

          },
          icon: const Icon(Icons.keyboard_arrow_left_sharp),
          color: Colors.white,
        ),
        centerTitle: true,
        title: Text(
          'TRENDING',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body:


      FutureBuilder<List<dynamic>>(
        future: gettrend(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading movies: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final movies = snapshot.data ?? [];
          if (movies.isEmpty) {
            return const Center(
              child: Text("No movies found", style: TextStyle(color: Colors.white70)),
            );
          }

          // Build grid-like scrolling rows
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: (movies.length / 5).ceil(), // 5 posters per row
            itemBuilder: (context, rowIndex) {
              final rowMovies = movies.skip(rowIndex * 8).take(8).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: rowMovies.length,
                      itemBuilder: (context, index) {
                        final movie = rowMovies[index];
                        final posterPath = movie['poster_path'];
                        final title = movie['title'] ?? "Unknown";

                        return GestureDetector(
                          onTap: () {
                            print("Selected movie: $title (id: ${movie['id']})");
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) => movieApp(id:movie['id'].toString())))
                            ;
                          },
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(12),
                              image: (posterPath != null)
                                  ? DecorationImage(
                                image: NetworkImage(
                                  "https://image.tmdb.org/t/p/w500$posterPath",
                                ),
                                fit: BoxFit.cover,
                              )
                                  : null,
                            ),
                            child: (posterPath == null)
                                ? Center(
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),

    );
  }
}