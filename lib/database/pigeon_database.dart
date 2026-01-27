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
        dweller_id TEXT,         -- Seu ID (Dono da conta no dispositivo)
        peer_id TEXT,            -- ID do contato (Com quem você conversa)
        sender_id TEXT,          -- Quem de fato enviou
        content TEXT,            
        timestamp TEXT,
        is_me INTEGER            -- 1 para enviadas, 0 para recebidas
      )
    ''');
  }

  // TRIUNFO: Salva organizando a paridade de quem é o contato
  Future<int> saveMessage(Map<String, dynamic> row, String currentDwellerId) async {
    final db = await instance.database;
    final Map<String, dynamic> mutableRow = Map.from(row);

    // Garante que a mensagem pertença ao usuário logado
    mutableRow['dweller_id'] = currentDwellerId;

    // Lógica de Peer: Se eu enviei (is_me=1), o peer é quem recebe. 
    // Se eu recebi, o peer é quem enviou.
    if (mutableRow['peer_id'] == null || mutableRow['peer_id'] == "") {
      mutableRow['peer_id'] = (mutableRow['is_me'] == 1) 
          ? mutableRow['receiver_id'] 
          : mutableRow['sender_id'];
    }

    return await db.insert(
      'messages', 
      mutableRow, 
      conflictAlgorithm: ConflictAlgorithm.replace 
    );
  }

  // --- PARA O CHATVIEW: Histórico COMPLETO (Bombardeio) ---
  Future<List<Map<String, dynamic>>> getChatHistory(String myId, String peerId) async {
    final db = await instance.database;
    // Sem GROUP BY para trazer todas as mensagens da conversa
    return await db.query(
      'messages',
      where: 'dweller_id = ? AND peer_id = ?',
      whereArgs: [myId, peerId],
      orderBy: 'id ASC' // Ordem cronológica
    );
  }

  // --- PARA A HOME: Resumo das conversas ---
  Future<List<Map<String, dynamic>>> getRecentChats(String myId) async {
    final db = await instance.database;
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
