import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sharedpref.dart';
import 'service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  String m1 = '';
  String m2 = '';
  String m3 = '';
  String m4 = '';

  final tmdb = TMDBService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isEqualTo: SharedPrefs.getUsername())
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      setState(() {
        nameController.text = data['name'] ?? '';
        bioController.text = data['bio'] ?? '';
        m1 = data['movie1'] ?? '';
        m2 = data['movie2'] ?? '';
        m3 = data['movie3'] ?? '';
        m4 = data['movie4'] ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isEqualTo: SharedPrefs.getUsername())
        .get();

    for (var doc in query.docs) {
      await doc.reference.update({
        'name': nameController.text,
        'bio': bioController.text,
        'movie1': m1,
        'movie2': m2,
        'movie3': m3,
        'movie4': m4,
      });
    }

    SharedPrefs.setUsername(nameController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated!')),
    );
  }

  Future<void> _pickMovie(String decider) async {
    final movies = await tmdb.getManyMovies();

    String? pickedMovie = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A0D2E),
          title: const Text("Pick a Movie", style: TextStyle(color: Colors.white)),
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
                      : const Icon(Icons.movie, size: 40, color: Color(0xFF7209B7)),
                  title: Text(title, style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context, posterUrl),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (pickedMovie != null && pickedMovie.isNotEmpty) {
      setState(() {
        if (decider == 'movie1') m1 = pickedMovie;
        if (decider == 'movie2') m2 = pickedMovie;
        if (decider == 'movie3') m3 = pickedMovie;
        if (decider == 'movie4') m4 = pickedMovie;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF7209B7),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Name",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: bioController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Bio",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Top 4 Favorites",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMovieBox(const Color(0xFF7209B7), m1, 'movie1'),
                  _buildMovieBox(const Color(0xFF9D4EDD), m2, 'movie2'),
                  _buildMovieBox(const Color(0xFF6A4C93), m3, 'movie3'),
                  _buildMovieBox(const Color(0xFF8B5CF6), m4, 'movie4'),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7209B7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saveChanges,
                child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMovieBox(Color color, String url, String decider) {
    return GestureDetector(
      onTap: () => _pickMovie(decider),
      child: Container(
        width: 70,
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: url.isEmpty
            ? const Text('Vacant', style: TextStyle(color: Colors.white, fontSize: 10))
            : Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image, size: 40, color: Colors.white),
        ),
      ),
    );
  }
}
