import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class PigeonDatabase {
  static final PigeonDatabase instance = PigeonDatabase._init();
  static Database? _database;

  PigeonDatabase._init();

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
      version: 3, // TRIUNFO: Versão 3 com suporte a índices e tipos de mídia
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // REAVALIAÇÃO COGNITIVA: Estrutura completa para garantir paridade total [cite: 2025-10-27]
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id TEXT UNIQUE,   
        dweller_id TEXT,         
        peer_id TEXT,            
        sender_id TEXT,          
        content TEXT,            
        timestamp TEXT,
        is_me INTEGER,            
        is_read INTEGER DEFAULT 0,
        type TEXT DEFAULT 'text'
      )
    ''');

    // Performance: Índice para buscas rápidas em conversas grandes
    await db.execute('CREATE INDEX idx_dweller_peer ON messages (dweller_id, peer_id)');
  }

  // TRATATIVA: Evolução do banco sem perda de dados (Alívio)
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE messages ADD COLUMN is_read INTEGER DEFAULT 0');
    }
    if (oldVersion < 3) {
      // Injeção de paridade para novas funcionalidades
      try {
        await db.execute("ALTER TABLE messages ADD COLUMN type TEXT DEFAULT 'text'");
        await db.execute('CREATE INDEX idx_dweller_peer ON messages (dweller_id, peer_id)');
      } catch (e) {
        print("Aviso: Campos v3 já existiam.");
      }
    }
  }

  Future<int> saveMessage(Map<String, dynamic> row, String currentDwellerId) async {
    final db = await instance.database;
    final Map<String, dynamic> mutableRow = Map.from(row);

    mutableRow['dweller_id'] = currentDwellerId;

    if (mutableRow['peer_id'] == null || mutableRow['peer_id'] == "") {
      if (mutableRow['is_me'] == 1) {
        mutableRow['peer_id'] = mutableRow['receiver_id'] ?? "Desconhecido";
        mutableRow['is_read'] = 1; 
      } else {
        mutableRow['peer_id'] = mutableRow['sender_id'] ?? "Desconhecido";
      }
    }

    mutableRow.remove('receiver_id');

    return await db.insert(
      'messages', 
      mutableRow, 
      conflictAlgorithm: ConflictAlgorithm.replace 
    );
  }

  Future<void> markAsRead(String myId, String peerId) async {
    final db = await instance.database;
    await db.update(
      'messages',
      {'is_read': 1},
      where: 'dweller_id = ? AND peer_id = ? AND is_me = 0',
      whereArgs: [myId, peerId],
    );
  }

  // TRIUNFO: Método essencial para o ProfileDweller (Livre-arbítrio) [cite: 2025-10-27]
  Future<void> clearChat(String myId, String peerId) async {
    final db = await instance.database;
    await db.delete(
      'messages', 
      where: 'dweller_id = ? AND peer_id = ?', 
      whereArgs: [myId, peerId]
    );
  }

  Future<List<Map<String, dynamic>>> getChatHistory(String myId, String peerId) async {
    final db = await instance.database;
    await markAsRead(myId, peerId);
    
    return await db.query(
      'messages',
      where: 'dweller_id = ? AND peer_id = ?',
      whereArgs: [myId, peerId],
      orderBy: 'id ASC'
    );
  }

  Future<List<Map<String, dynamic>>> getRecentChats(String myId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT m1.*, 
      (SELECT COUNT(*) FROM messages m2 WHERE m2.peer_id = m1.peer_id AND m2.is_read = 0 AND m2.dweller_id = ?) as unread_count
      FROM messages m1
      WHERE m1.id IN (
          SELECT MAX(id) FROM messages 
          WHERE dweller_id = ? 
          GROUP BY peer_id
      )
      ORDER BY m1.id DESC
    ''', [myId, myId]);
  }

  Future<void> deleteMessage(int id) async {
    final db = await instance.database;
    await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }
}
