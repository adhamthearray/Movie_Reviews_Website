import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_session/service.dart';
import 'package:project_session/sharedpref.dart';
import 'package:project_session/signup.dart';
import 'package:project_session/login.dart';
import 'package:project_session/sql.dart';
import 'package:project_session/reviews.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class movieApp extends StatefulWidget {
  const movieApp({super.key, required this.id});
  final String id;

  @override
  State<movieApp> createState() => _movie();
}

class _movie extends State<movieApp> {
  final tmdb = TMDBService();
  String posterUrl = "";
  String description = "";
  String name = "";
  double rating = 0.0;
  late var Castdata = [];
  final TextEditingController reviewController = TextEditingController();

  // YouTube player controller
  YoutubePlayerController? _youtubeController;
  String? trailerKey;

  @override
  void initState() {
    super.initState();
    _loadMovieData();
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadMovieData() async {
    try {
      final data = await tmdb.getMovieDetails(widget.id);
      Castdata = await tmdb.getCast(widget.id);

      setState(() {
        posterUrl = "https://image.tmdb.org/t/p/w500${data['poster_path'] ?? ''}";
        name = data['title'] ?? "No Title";
        rating = (data['vote_average'] as num?)?.toDouble() ?? 0.0;
        description = data['overview'] ?? "No description available.";
      });
    } catch (e, stack) {
      print('Error in movie data: $e');
      print(stack);
    }
  }

  Future<void> _loadTrailer() async {
    try {
      // First try TMDB trailer
      trailerKey = await tmdb.getTrailerKey(widget.id);

      if (trailerKey != null && trailerKey!.isNotEmpty) {
        print('Trying TMDB trailer with key: $trailerKey');

        // Check if running on desktop/web
        if (kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS))) {
          // For desktop, always give user the choice since we can't test the video
          _showTrailerOptionsDialog();
        } else {
          // Mobile: Try embedded player first
          if (await _tryEmbeddedPlayer()) {
            return; // Success
          } else {
            // If embedded player fails, show options
            _showTrailerOptionsDialog();
          }
        }
      } else {
        print('No TMDB trailer found for movie ID: ${widget.id}');
        // No TMDB trailer, go straight to search option
        _showSearchOnlyDialog();
      }
    } catch (e) {
      print('Error loading trailer: $e');
      _showSearchOnlyDialog();
    }
  }

  void _showTrailerOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            "Watch $name Trailer",
            style: const TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Choose how you'd like to watch the trailer:",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            if (trailerKey != null && trailerKey!.isNotEmpty)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Try direct link
                  final url = 'https://www.youtube.com/watch?v=$trailerKey';
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    _showErrorDialog('Could not open YouTube');
                  }
                },
                child: const Text(
                  "Try Direct Link",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Search for trailer
                final searchUrl = 'https://www.youtube.com/results?search_query=${Uri.encodeComponent("$name official trailer 2024 2023")}';
                final uri = Uri.parse(searchUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text(
                "Search YouTube",
                style: TextStyle(color: Colors.deepPurpleAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSearchOnlyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            "$name Trailer",
            style: const TextStyle(color: Colors.white),
          ),
          content: const Text(
            "No direct trailer link available. Would you like to search for it on YouTube?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final searchUrl = 'https://www.youtube.com/results?search_query=${Uri.encodeComponent("$name official trailer")}';
                final uri = Uri.parse(searchUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text(
                "Search YouTube",
                style: TextStyle(color: Colors.deepPurpleAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTrailerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "$name - Trailer",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                if (_youtubeController != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: YoutubePlayer(
                      controller: _youtubeController!,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: Colors.deepPurpleAccent,
                      progressColors: const ProgressBarColors(
                        playedColor: Colors.deepPurpleAccent,
                        handleColor: Colors.deepPurpleAccent,
                        backgroundColor: Colors.white24,
                      ),
                      topActions: [
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            "$name - Trailer",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // Dispose controller when dialog is closed
      _youtubeController?.dispose();
      _youtubeController = null;
    });
  }

  void _showNoTrailerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            "No Trailer Available",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Sorry, no trailer is available for this movie.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.deepPurpleAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _tryEmbeddedPlayer() async {
    try {
      _youtubeController = YoutubePlayerController(
        initialVideoId: trailerKey!,
        flags: const YoutubePlayerFlags(
          autoPlay: false, // Don't auto-play to test availability first
          mute: false,
          enableCaption: true,
          captionLanguage: 'en',
          isLive: false,
          forceHD: false,
          startAt: 0,
        ),
      );

      // Test if video loads successfully
      bool hasError = false;
      _youtubeController!.addListener(() {
        if (_youtubeController!.value.hasError) {
          print('YouTube player error: ${_youtubeController!.value.errorCode}');
          hasError = true;
        }
      });

      // Wait a moment to see if there's an immediate error
      await Future.delayed(const Duration(milliseconds: 500));

      if (!hasError) {
        _showTrailerDialog();
        return true;
      } else {
        _youtubeController?.dispose();
        _youtubeController = null;
        return false;
      }
    } catch (e) {
      print('Error with embedded player: $e');
      _youtubeController?.dispose();
      _youtubeController = null;
      return false;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Error", style: TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK", style: TextStyle(color: Colors.deepPurpleAccent)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster on the left
            Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white10,
              ),
              clipBehavior: Clip.hardEdge,
              child: posterUrl.isNotEmpty
                  ? Image.network(
                posterUrl,
                fit: BoxFit.cover,
              )
                  : const Icon(Icons.movie, color: Colors.white54, size: 40),
            ),

            const SizedBox(width: 16),

            // Name + Description on the right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description in a smaller container
                  Container(
                    constraints: const BoxConstraints(
                      maxWidth: 300,
                    ),
                    child: Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.justify,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    height: 120,
                    width: double.infinity,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 80,
                      width: 80,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: rating / 10,
                            strokeWidth: 6,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.deepPurpleAccent,
                            ),
                            backgroundColor: Colors.white24,
                          ),
                          Center(
                            child: Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => reviewsApp(mid: widget.id),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reviews'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.black87,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (context) {
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Add Your Review",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: reviewController,
                                      maxLines: 3,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: "Write your review here...",
                                        hintStyle: const TextStyle(
                                          color: Colors.white54,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[900],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          await FirebaseFirestore.instance
                                              .collection('reviews')
                                              .add({
                                            'movie': widget.id,
                                            'user': SharedPrefs.getUsername(),
                                            'log': reviewController.text,
                                            'timestamp': FieldValue.serverTimestamp(),
                                          });

                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepPurpleAccent,
                                        ),
                                        child: const Text("Submit"),
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add Your Review'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: _loadTrailer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow),
                          SizedBox(width: 8),
                          Text("Watch Trailer"),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10,),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () async {
                        final usersRef = FirebaseFirestore.instance.collection('users');

                        final query = await usersRef.where('name', isEqualTo: SharedPrefs.getUsername()).get();

                        if (query.docs.isNotEmpty) {
                          final userDoc = query.docs.first.reference;

                          await userDoc.update({
                            'watchlist': FieldValue.arrayUnion([widget.id]),
                          });

                          print("✅ Added to watchlist!");
                        } else {
                          print("⚠️ No user found with name =");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_circle),
                          SizedBox(width: 8),
                          Text("Add To WatchList"),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),

            // Cast list
            Expanded(
              child: SizedBox(
                height: 900,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: Castdata.length,
                  itemBuilder: (context, index) {
                    final actor = Castdata[index];
                    print("Cast length: ${Castdata.length}");

                    return Card(
                      color: Colors.white10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 6,
                      margin: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white10,
                          child: ClipOval(
                            child: Image.network(
                              "https://image.tmdb.org/t/p/w500${actor['profile_path']}",
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
                        ),
                        title: Text(
                          actor['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          actor['character'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[300],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}