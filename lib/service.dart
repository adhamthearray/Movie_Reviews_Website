import 'dart:convert';
import 'package:http/http.dart' as http;

class TMDBService {
  final String apiKey = "92fd29e03d8fe201061933b3b2b33b7b"; // replace with your TMDB key
  final String baseUrl = "https://api.themoviedb.org/3";

  Future<List<dynamic>> getTrendingMovies() async {
    final url = Uri.parse('$baseUrl/trending/movie/week?api_key=$apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["results"];
    } else {
      throw Exception("Failed to fetch movies: ${response.statusCode}");
    }
  }
  Future<List<dynamic>> getCast(String movieId) async {
    final url = Uri.parse('$baseUrl/movie/$movieId/credits?api_key=$apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['cast']; // this is a List<dynamic>
    } else {
      throw Exception('Failed to load cast');
    }
  }
  Future<String?> getTrailerKey(String movieId) async {
    final url = Uri.parse(
        'https://api.themoviedb.org/3/movie/$movieId/videos?api_key=$apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      if (results.isNotEmpty) {
        // Find the first YouTube trailer
        final trailer = results.firstWhere(
              (vid) => vid['type'] == 'Trailer' && vid['site'] == 'YouTube',
          orElse: () => null,
        );
        if (trailer != null) {
          return "https://www.youtube.com/watch?v=${trailer['key']}";
        }
      }
    }
    return null;
  }


  Future<List<dynamic>> getManyMovies({int pages = 10}) async {
    List<dynamic> allMovies = [];

    for (int i = 1; i <= pages; i++) {
      final url = Uri.parse('$baseUrl/trending/movie/day?api_key=$apiKey&page=$i');
      print("Fetching page $i: $url"); // 👀 see what URL is being hit
      final response = await http.get(url);

      print("Status: ${response.statusCode}");
      print("Body: ${response.body}"); // 👀 check raw response

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        allMovies.addAll(data['results']);
      } else {
        throw Exception("Failed at page $i: ${response.statusCode}");
      }
    }

    print("Total movies fetched: ${allMovies.length}");
    return allMovies;
  }


  String getImageUrl(String path) {
    return "https://image.tmdb.org/t/p/w500$path";
  }

  Future<Map<String, dynamic>> getMovieDetails(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/movie/$id?api_key=$apiKey'));
    return jsonDecode(response.body);
  }

}
