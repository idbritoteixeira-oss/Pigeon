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
      version: 1, 
      onCreate: _createDB
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id TEXT UNIQUE,   
        dweller_id TEXT,         -- Seu ID (Dono da conta)
        peer_id TEXT,            -- ID do contato
        sender_id TEXT,          -- Quem enviou
        content TEXT,            
        timestamp TEXT,
        is_me INTEGER            -- 1 para enviadas, 0 para recebidas
      )
    ''');
  }

  // TRIUNFO: Salva organizando a paridade e tratando campos nulos [cite: 2025-10-27]
  Future<int> saveMessage(Map<String, dynamic> row, String currentDwellerId) async {
    final db = await instance.database;
    final Map<String, dynamic> mutableRow = Map.from(row);

    // Garante a Memória-consolidada do dono da conta [cite: 2025-10-27]
    mutableRow['dweller_id'] = currentDwellerId;

    // REAVALIAÇÃO COGNITIVA: O peer_id é essencial para agrupar conversas [cite: 2025-10-27]
    if (mutableRow['peer_id'] == null || mutableRow['peer_id'] == "") {
      // Se eu enviei (is_me=1), o peer é para quem eu mandei (receiver_id)
      // Se eu recebi, o peer é quem me mandou (sender_id)
      if (mutableRow['is_me'] == 1) {
        mutableRow['peer_id'] = mutableRow['receiver_id'] ?? "Desconhecido";
      } else {
        mutableRow['peer_id'] = mutableRow['sender_id'] ?? "Desconhecido";
      }
    }

    // REMOÇÃO DE RESÍDUO: Removemos campos que não existem na tabela antes de inserir
    // Isso evita o erro de "table has no column named receiver_id"
    mutableRow.remove('receiver_id');

    return await db.insert(
      'messages', 
      mutableRow, 
      conflictAlgorithm: ConflictAlgorithm.replace 
    );
  }

  Future<List<Map<String, dynamic>>> getChatHistory(String myId, String peerId) async {
    final db = await instance.database;
    return await db.query(
      'messages',
      where: 'dweller_id = ? AND peer_id = ?',
      whereArgs: [myId, peerId],
      orderBy: 'id ASC'
    );
  }

  Future<List<Map<String, dynamic>>> getRecentChats(String myId) async {
    final db = await instance.database;
    // PARIDADE: Retorna o último registro de cada peer para a Home [cite: 2025-10-27]
    return await db.rawQuery('''
      SELECT * FROM messages 
      WHERE dweller_id = ? 
      GROUP BY peer_id 
      ORDER BY id DESC
    ''', [myId]);
  }

  Future<void> deleteMessage(int id) async {
    final db = await instance.database;
    await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }
}
