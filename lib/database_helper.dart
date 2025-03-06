import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'card_organizer.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create folders table
    await db.execute('''
      CREATE TABLE folders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        timestamp TEXT
      )
    ''');

    // Create cards table
    await db.execute('''
      CREATE TABLE cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        suit TEXT,
        imageUrl TEXT,
        folderId INTEGER,
        FOREIGN KEY(folderId) REFERENCES folders(id)
      )
    ''');

    // Prepopulate folders
    await db.insert('folders', {'name': 'Hearts', 'timestamp': DateTime.now().toString()});
    await db.insert('folders', {'name': 'Spades', 'timestamp': DateTime.now().toString()});
    await db.insert('folders', {'name': 'Diamonds', 'timestamp': DateTime.now().toString()});
    await db.insert('folders', {'name': 'Clubs', 'timestamp': DateTime.now().toString()});

    // Prepopulate cards for each suit
    final suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    for (var suit in suits) {
      for (int i = 1; i <= 13; i++) {
        await db.insert('cards', {
          'name': '$i of $suit',
          'suit': suit,
          'imageUrl': 'assets/images/${suit.toLowerCase()}.png', // Use the same image for all cards in the suit
          'folderId': suits.indexOf(suit) + 1, // Assign folderId based on suit order
        });
      }
    }
  }

  // Fetch all folders
  Future<List<Map<String, dynamic>>> getFolders() async {
    Database db = await database;
    return await db.query('folders');
  }

  // Fetch cards by folderId
  Future<List<Map<String, dynamic>>> getCardsByFolder(int folderId) async {
    Database db = await database;
    return await db.query('cards', where: 'folderId = ?', whereArgs: [folderId]);
  }

  // Insert a new card
  Future<int> insertCard(Map<String, dynamic> card) async {
    Database db = await database;
    return await db.insert('cards', card);
  }

  // Delete a card
  Future<int> deleteCard(int id) async {
    Database db = await database;
    return await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }
}