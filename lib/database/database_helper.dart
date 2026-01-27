import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pigeon_enx.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id TEXT UNIQUE,
        id_pigeon TEXT,          -- Seu ID
        peer_id TEXT,            -- ID do Contato (Obrigatório para o Triunfo)
        sender_id TEXT,          -- Quem enviou
        content TEXT,
        timestamp TEXT,
        is_me INTEGER
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Ponderação ética: Garantimos que a coluna existe para novos dados
      try {
        await db.execute("ALTER TABLE messages ADD COLUMN peer_id TEXT;");
      } catch (e) {
        print("Coluna já existe ou erro no upgrade: $e");
      }
    }
  }

  Future<int> insertMessage(Map<String, dynamic> row) async {
    final db = await instance.database;
    
    // MEMÓRIA-SEGMENTADA: Se o peer_id não vier no Map, tentamos deduzir do sender_id
    // Isso evita que a mensagem fique "órfã" no banco. [cite: 2025-10-27]
    final Map<String, dynamic> mutableRow = Map.from(row);
    if (mutableRow['peer_id'] == null || mutableRow['peer_id'] == "") {
      mutableRow['peer_id'] = mutableRow['sender_id'];
    }

    return await db.insert('messages', mutableRow, 
        conflictAlgorithm: ConflictAlgorithm.replace); // Usamos replace para atualizar status
  }

  // --- NOVA FUNÇÃO PARA A HOME (RESOLVE A TELA LIMPA) ---
  Future<List<Map<String, dynamic>>> getRecentChats(String myId) async {
    final db = await instance.database;
    // Pega a última mensagem de cada contato diferente para listar na Home
    return await db.rawQuery('''
      SELECT * FROM messages 
      WHERE id_pigeon = ? 
      GROUP BY peer_id 
      ORDER BY id DESC
    ''', [myId]);
  }

  // Busca o histórico de uma conversa específica
  Future<List<Map<String, dynamic>>> getChatMessages(String myId, String peerId) async {
    final db = await instance.database;
    return await db.query(
      'messages',
      where: 'id_pigeon = ? AND peer_id = ?',
      whereArgs: [myId, peerId],
      orderBy: 'id ASC',
    );
  }
}
