import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_session/Home.dart';
import 'package:project_session/service.dart';
import 'package:project_session/sharedpref.dart';
import 'package:project_session/signup.dart';
import 'package:project_session/settings.dart';
import 'package:project_session/sql.dart';

import 'login.dart';
import 'movie_view.dart';

class profApp extends StatefulWidget {
  const profApp({super.key});

  @override
  State<profApp> createState() => prof();
}

class prof extends State<profApp> {
  final SqlData db = SqlData();
  final tmdb = TMDBService();
  String desc="";

  Future<void> _loadUserByUsername(String targetUsername) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: targetUsername)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var userDoc = querySnapshot.docs.first;
        desc=userDoc['bio']?.toString()??'';
      } else {
      }
    } catch (e) {
      print('Error loading user by username: $e');
      setState(() {
      });
    }
  }

  Future<List<dynamic>> gettrend() async {
    try {
      final movies = await tmdb.getTrendingMovies();
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Color(0xFF1A0D2E),
          title: Text(
            '${SharedPrefs.getUsername()}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(onPressed:(){ Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) =>
                 EditProfilePage()),
            );}, icon: Icon(Icons.settings))
          ],
          iconTheme: IconThemeData(color: Colors.white),
          bottom: TabBar(
            indicatorColor: Color(0xFF7209B7),
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[400],
            tabs: [
              Tab(
                text: 'Profile',
                icon: Icon(Icons.person, size: 20),
              ),
              Tab(
                text: 'Diary',
                icon: Icon(Icons.book, size: 20),
              ),
              Tab(
                text: 'Watch List',
                icon: Icon(Icons.playlist_play, size: 20),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Profile(),
            rev(),
            WatchList(),
          ],
        ),
      ),
    );
  }
}

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final tmdb = TMDBService();
  String desc = '';
  String pic = '';
  String m1='';
  String m2='';
  String m3='';
  String m4='';

  @override
  void initState() {
    super.initState();
    _loadUserByUsername(SharedPrefs.getUsername());
    fetchUserMovies();
  }

  Future<void> fetchUserMovies() async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isEqualTo: SharedPrefs.getUsername())
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();

      setState(() {
        m1 = data['movie1'] ?? '';
        m2 = data['movie2'] ?? '';
        m3 = data['movie3'] ?? '';
        m4 = data['movie4'] ?? '';
      });
    }
  }

  Future<void> _loadUserByUsername(String targetUsername) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: targetUsername)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var userDoc = querySnapshot.docs.first;
        setState(() {
          desc = userDoc.get('bio')?.toString() ?? '';
          pic=userDoc.get('picurl')?.toString()??'';
          print(pic);
        });
      } else {
        setState(() {
          desc = 'Bio not found';
        });
      }
    } catch (e) {
      print('Error loading user by username: $e');
      setState(() {
        desc = 'Error loading bio';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundImage: NetworkImage("https://i.pravatar.cc/300"),
                backgroundColor: Colors.deepPurple,
              ),
              SizedBox(height: 20),
              Text(
                desc.isNotEmpty ? desc : 'Loading bio...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Top 4 Favorites',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMovieBox(Color(0xFF7209B7), m1, 'movie1'),
                  _buildMovieBox(Color(0xFF9D4EDD), m2, 'movie2'),
                  _buildMovieBox(Color(0xFF6A4C93), m3, 'movie3'),
                  _buildMovieBox(Color(0xFF8B5CF6), m4, 'movie4'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMovieBox(Color color, String text, String Decider) {
    return GestureDetector(
      /*onTap: () async {
        final movies = await tmdb.getManyMovies();

        String? pickedMovie = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Color(0xFF1A0D2E),
              title: Text(
                "Pick a Movie",
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: movies.map<Widget>((movie) {
                    final posterPath = movie['poster_path'];
                    final title = movie['title'] ?? 'Unknown';
                    final posterUrl = (posterPath != null && posterPath.isNotEmpty)
                        ? "https://image.tmdb.org/t/p/w500$posterPath"
                        : '';

                    return ListTile(
                      leading: posterUrl.isNotEmpty
                          ? Image.network(posterUrl, width: 40)
                          : Icon(Icons.movie, size: 40, color: Color(0xFF7209B7)),
                      title: Text(
                        title,
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context, posterUrl);
                      },
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );

        if (pickedMovie != null && pickedMovie.isNotEmpty) {
          setState(() {
            if (Decider == 'movie1') m1 = pickedMovie;
            if (Decider == 'movie2') m2 = pickedMovie;
            if (Decider == 'movie3') m3 = pickedMovie;
            if (Decider == 'movie4') m4 = pickedMovie;
          });

          final query = await FirebaseFirestore.instance
              .collection('users')
              .where('name', isEqualTo: SharedPrefs.getUsername())
              .get();

          for (var doc in query.docs) {
            await doc.reference.set(
              {'${Decider}': pickedMovie},
              SetOptions(merge: true),
            );
          }
        }
      }*/
      child: Container(
        width: 170,
        height: 190,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: text == ''
            ? Text(
          'Vacant',
          style: TextStyle(color: Colors.white),
        )
            : Image.network(
          text,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.broken_image, size: 40, color: Colors.white),
        ),
      ),
    );
  }
}

class WatchList extends StatefulWidget {
  const WatchList({super.key});

  @override
  State<WatchList> createState() => Watch();
}

class Watch extends State<WatchList> {
  final tmdb = TMDBService();

  Future<List<dynamic>> getMovies() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: SharedPrefs.getUsername())
          .get();

      if (query.docs.isNotEmpty) {
        final userDoc = query.docs.first;
        final List<dynamic> movieIds = userDoc['watchlist'] ?? [];

        if (movieIds.isEmpty) return [];

        final movies = await Future.wait(
          movieIds.map((id) async {
            try {
              return await tmdb.getMovieDetails(id.toString());
            } catch (e) {
              print("Error loading movie $id: $e");
              return null;
            }
          }),
        );

        return movies.whereType<Map<String, dynamic>>().toList();
      } else {
        print("⚠️ No user found for ${SharedPrefs.getUsername()}");
        return [];
      }
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<dynamic>>(
        future: getMovies(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7209B7),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading movies: ${snapshot.error}",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final movies = snapshot.data ?? [];
          if (movies.isEmpty) {
            return Center(
              child: Text(
                "No movies found",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: (movies.length / 5).ceil(),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => movieApp(id: movie['id'].toString()),
                              ),
                            );
                          },
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            decoration: BoxDecoration(
                              color: Color(0xFF2D1B3D),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Color(0xFF7209B7).withOpacity(0.3),
                                width: 1,
                              ),
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
                                style: TextStyle(
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

class rev extends StatefulWidget {
  @override
  PastReviews createState() => PastReviews();
}

class PastReviews extends State<rev> {
  final tmdb = TMDBService();

  Future<Map<String, dynamic>> _loadMovieData(String id) async {
    try {
      final data = await tmdb.getMovieDetails(id);
      return {
        "posterUrl": "https://image.tmdb.org/t/p/w500${data['poster_path'] ?? ''}",
        "name": data['title'] ?? "No Title",
        "rating": (data['vote_average'] as num?)?.toDouble() ?? 0.0,
        "description": data['overview'] ?? "No description available."
      };
    } catch (e, stack) {
      print("Error loading movie $id: $e");
      return {
        "posterUrl": "",
        "name": "Error",
        "rating": 0.0,
        "description": "Could not load movie data."
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('user', isEqualTo: SharedPrefs.getUsername())
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7209B7),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No reviews yet",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final data = reviews[index].data() as Map<String, dynamic>;
              final movieId = data['movie'];

              return FutureBuilder<Map<String, dynamic>>(
                future: _loadMovieData(movieId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Card(
                      color: Color(0xFF2D1B3D),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(0xFF7209B7),
                          child: Icon(Icons.movie, color: Colors.white),
                        ),
                        title: Text(
                          "Loading...",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }

                  final movie = snapshot.data!;
                  return Card(
                    color: Color(0xFF2D1B3D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: Color(0xFF7209B7).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(0xFF7209B7),
                        backgroundImage: movie['posterUrl'].isNotEmpty
                            ? NetworkImage(movie['posterUrl'])
                            : null,
                        child: movie['posterUrl'].isEmpty
                            ? Icon(Icons.movie, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        data['log'] ?? 'No text',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        "${movie['name']} (${movie['rating']})",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}