import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().database; // Initialize the database
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FoldersScreen(),
    );
  }
}

// Database Helper
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

// Folders Screen
class FoldersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Folders')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper().getFolders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var folder = snapshot.data![index];
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseHelper().getCardsByFolder(folder['id']),
                builder: (context, cardSnapshot) {
                  if (!cardSnapshot.hasData) return ListTile(title: Text('Loading...'));
                  return ListTile(
                    leading: Image.asset('assets/images/${folder['name'].toLowerCase()}.png', width: 50, height: 50),
                    title: Text(folder['name']),
                    subtitle: Text('${cardSnapshot.data!.length} cards'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CardsScreen(folderId: folder['id']),
                        ),
                      );
                    },
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

// Cards Screen
class CardsScreen extends StatelessWidget {
  final int folderId;

  CardsScreen({required this.folderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cards')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper().getCardsByFolder(folderId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var card = snapshot.data![index];
              return Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(card['name']),
                    Image.asset(card['imageUrl']), // Use the same image for all cards in the suit
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}