import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqlData {
  static Database? _db;
  static const int _databaseVersion = 1;
  static const String _databaseName = 'accounts.db';

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: _onDowngrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _insertInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    // Example migration pattern:
    /*
    if (oldVersion < 2) {
      // Add new column or table for version 2
      await db.execute('ALTER TABLE Movie ADD COLUMN genre TEXT');
    }
    if (oldVersion < 3) {
      // Additional changes for version 3
      await db.execute('CREATE TABLE IF NOT EXISTS Genre (...)');
    }
    */

    // For now, we'll recreate everything (destructive upgrade)
    // In production, you should implement proper migrations
    await _dropTables(db);
    await _createTables(db);
    await _insertInitialData(db);
  }

  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    // Handle database downgrades (usually rare)
    await _dropTables(db);
    await _createTables(db);
    await _insertInitialData(db);
  }

  Future<void> _onOpen(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createTables(Database db) async {
    // Create Account table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Account (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create Movie table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Movie (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        rating REAL NOT NULL CHECK(rating >= 0 AND rating <= 10),
        description TEXT,
        duration INTEGER CHECK(duration > 0),
        director TEXT,
        posterUrl TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create FavoriteMovies junction table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS FavoriteMovies (
        accountId INTEGER NOT NULL,
        movieId INTEGER NOT NULL,
        added_at TEXT DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (accountId, movieId),
        FOREIGN KEY (accountId) REFERENCES Account(id) ON DELETE CASCADE,
        FOREIGN KEY (movieId) REFERENCES Movie(id) ON DELETE CASCADE
      )
    ''');

    // Create Review table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Review (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        log TEXT,
        date TEXT DEFAULT CURRENT_TIMESTAMP,
        rating REAL CHECK(rating >= 0 AND rating <= 10),
        accountId INTEGER NOT NULL,
        movieId INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (accountId) REFERENCES Account(id) ON DELETE CASCADE,
        FOREIGN KEY (movieId) REFERENCES Movie(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX IF NOT EXISTS idx_account_email ON Account(email)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_movie_title ON Movie(title)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_movie_rating ON Movie(rating)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_review_movie ON Review(movieId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_review_account ON Review(accountId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_favorites_account ON FavoriteMovies(accountId)');
  }

  Future<void> _dropTables(Database db) async {
    await db.execute('DROP TABLE IF EXISTS Review');
    await db.execute('DROP TABLE IF EXISTS FavoriteMovies');
    await db.execute('DROP TABLE IF EXISTS Movie');
    await db.execute('DROP TABLE IF EXISTS Account');
  }

  Future<void> _insertInitialData(Database db) async {
    // Check if movies already exist to avoid duplicates
    var result = await db.query('Movie', limit: 1);
    if (result.isNotEmpty) {
      return; // Movies already inserted
    }

    // Insert movies in batches to handle large datasets better
    const List<Map<String, dynamic>> movies = [
      {
        "title": "The Shawshank Redemption",
        "rating": 9.3,
        "description": "Hope can set you free.",
        "duration": 142,
        "director": "Frank Darabont",
        "posterUrl": "https://image.tmdb.org/t/p/w500/q6y0Go1tsGEsmtFryDOJo3dEmqu.jpg"
      },
      {
        "title": "The Godfather",
        "rating": 9.2,
        "description": "An offer you can't refuse.",
        "duration": 175,
        "director": "Francis Ford Coppola",
        "posterUrl": "https://image.tmdb.org/t/p/w500/3bhkrj58Vtu7enYsRolD1fZdja1.jpg"
      },
      {
        "title": "The Dark Knight",
        "rating": 9.0,
        "description": "The night is darkest just before the dawn.",
        "duration": 152,
        "director": "Christopher Nolan",
        "posterUrl": "https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg"
      },
      {
        "title": "Pulp Fiction",
        "rating": 8.9,
        "description": "You never know what you're gonna get.",
        "duration": 154,
        "director": "Quentin Tarantino",
        "posterUrl": "https://image.tmdb.org/t/p/w500/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg"
      },
      {
        "title": "Fight Club",
        "rating": 8.8,
        "description": "The first rule of Fight Club is…",
        "duration": 139,
        "director": "David Fincher",
        "posterUrl": "https://image.tmdb.org/t/p/w500/bptfVGEQuv6vDTIMVCHjJ9Dz8PX.jpg"
      },
      {
        "title": "Forrest Gump",
        "rating": 8.8,
        "description": "Life is like a box of chocolates.",
        "duration": 142,
        "director": "Robert Zemeckis",
        "posterUrl": "https://image.tmdb.org/t/p/w500/saHP97rTPS5eLmrLQEcANmKrsFl.jpg"
      },
      {
        "title": "Inception",
        "rating": 8.8,
        "description": "Your mind is the scene of the crime.",
        "duration": 148,
        "director": "Christopher Nolan",
        "posterUrl": "https://image.tmdb.org/t/p/w500/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg"
      },
      {
        "title": "The Matrix",
        "rating": 8.7,
        "description": "What is real?",
        "duration": 136,
        "director": "The Wachowskis",
        "posterUrl": "https://image.tmdb.org/t/p/w500/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg"
      },
      {
        "title": "Goodfellas",
        "rating": 8.7,
        "description": "As far back as I can remember, I always wanted to be a gangster.",
        "duration": 146,
        "director": "Martin Scorsese",
        "posterUrl": "https://image.tmdb.org/t/p/w500/aKuFiU82s5ISJpGZp7YkIr3kCUd.jpg"
      },
      {
        "title": "Se7en",
        "rating": 8.6,
        "description": "Seven deadly sins. Seven ways to die.",
        "duration": 127,
        "director": "David Fincher",
        "posterUrl": "https://image.tmdb.org/t/p/w500/6yoghtyTpznpBik8EngEmJskVUO.jpg"
      },
      {
        "title": "The Silence of the Lambs",
        "rating": 8.6,
        "description": "Hello, Clarice.",
        "duration": 118,
        "director": "Jonathan Demme",
        "posterUrl": "https://image.tmdb.org/t/p/w500/rplLJ2hPcOQmkFhTqUte0MkEaO2.jpg"
      },
      {
        "title": "The Usual Suspects",
        "rating": 8.5,
        "description": "The greatest trick the Devil ever pulled...",
        "duration": 106,
        "director": "Bryan Singer",
        "posterUrl": "https://image.tmdb.org/t/p/w500/bUPmtQzrRhzqYySeiMpv7GurAfm.jpg"
      },
      {
        "title": "Saving Private Ryan",
        "rating": 8.6,
        "description": "The mission is a man.",
        "duration": 169,
        "director": "Steven Spielberg",
        "posterUrl": "https://image.tmdb.org/t/p/w500/miDoEMlYDJhOCvxlzI0wZqBs9Yt.jpg"
      },
      {
        "title": "Interstellar",
        "rating": 8.6,
        "description": "Mankind was born on Earth. It was never meant to die here.",
        "duration": 169,
        "director": "Christopher Nolan",
        "posterUrl": "https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg"
      },
      {
        "title": "Gladiator",
        "rating": 8.5,
        "description": "Are you not entertained?",
        "duration": 155,
        "director": "Ridley Scott",
        "posterUrl": "https://image.tmdb.org/t/p/w500/ty8TGRuvJLPUmAR1H1nRIsgwvim.jpg"
      },
      {
        "title": "The Green Mile",
        "rating": 8.6,
        "description": "Miracles do happen.",
        "duration": 189,
        "director": "Frank Darabont",
        "posterUrl": "https://image.tmdb.org/t/p/w500/o0lO84GI7qrG6XFvtsPOSV7CTNa.jpg"
      },
      {
        "title": "The Departed",
        "rating": 8.5,
        "description": "Cops or criminals. When you're facing a loaded gun, what's the difference?",
        "duration": 151,
        "director": "Martin Scorsese",
        "posterUrl": "https://image.tmdb.org/t/p/w500/ia3rT3cEwk2lTiMU0ZQgHeKOsG.jpg"
      },
      {
        "title": "Whiplash",
        "rating": 8.5,
        "description": "There are no two words in the English language more harmful than 'good job'.",
        "duration": 106,
        "director": "Damien Chazelle",
        "posterUrl": "https://image.tmdb.org/t/p/w500/lIv1QinFqz4dlp5U4lQ6HaiskOZ.jpg"
      },
      {
        "title": "Parasite",
        "rating": 8.6,
        "description": "Act like you own the place.",
        "duration": 132,
        "director": "Bong Joon-ho",
        "posterUrl": "https://image.tmdb.org/t/p/w500/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg"
      },
      {
        "title": "Joker",
        "rating": 8.4,
        "description": "Put on a happy face.",
        "duration": 122,
        "director": "Todd Phillips",
        "posterUrl": "https://image.tmdb.org/t/p/w500/udDclJoHjfjb8Ekgsd4FDteOkCU.jpg"
      }
    ];

    // Insert movies using batch operations for better performance
    Batch batch = db.batch();
    for (var movie in movies) {
      batch.insert('Movie', movie);
    }
    await batch.commit(noResult: true);
  }

  // Enhanced CRUD operations with error handling
  Future<int> insertData(String sql) async {
    try {
      final dbClient = await db;
      return await dbClient.rawInsert(sql);
    } catch (e) {
      print('Error inserting data: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> readData(String sql) async {
    try {
      final dbClient = await db;
      return await dbClient.rawQuery(sql);
    } catch (e) {
      print('Error reading data: $e');
      rethrow;
    }
  }

  Future<int> updateData(String sql) async {
    try {
      final dbClient = await db;
      return await dbClient.rawUpdate(sql);
    } catch (e) {
      print('Error updating data: $e');
      rethrow;
    }
  }

  Future<int> deleteData(String sql) async {
    try {
      final dbClient = await db;
      return await dbClient.rawDelete(sql);
    } catch (e) {
      print('Error deleting data: $e');
      rethrow;
    }
  }

  // Type-safe methods for common operations
  Future<int> insertAccount(Map<String, dynamic> account) async {
    try {
      final dbClient = await db;
      return await dbClient.insert('Account', account);
    } catch (e) {
      print('Error inserting account: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMovies({int? limit, int? offset}) async {
    try {
      final dbClient = await db;
      return await dbClient.query(
        'Movie',
        orderBy: 'rating DESC',
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      print('Error getting movies: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchMovies(String searchTerm) async {
    try {
      final dbClient = await db;
      return await dbClient.query(
        'Movie',
        where: 'title LIKE ? OR director LIKE ?',
        whereArgs: ['%$searchTerm%', '%$searchTerm%'],
        orderBy: 'rating DESC',
      );
    } catch (e) {
      print('Error searching movies: $e');
      rethrow;
    }
  }

  // Close database connection
  Future<void> close() async {
    final dbClient = _db;
    if (dbClient != null) {
      await dbClient.close();
      _db = null;
    }
  }

  // Database utilities
  Future<void> resetDatabase() async {
    try {
      await close();
      String path = join(await getDatabasesPath(), _databaseName);
      await deleteDatabase(path);
      _db = await initDb();
    } catch (e) {
      print('Error resetting database: $e');
      rethrow;
    }
  }

  Future<bool> isDatabaseOpen() async {
    return _db?.isOpen ?? false;
  }
}