import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class PigeonDatabase {
  // Singleton para garantir que só exista uma instância do banco aberta
  static final PigeonDatabase instance = PigeonDatabase._init();
  static Database? _database;

  PigeonDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pigeon_enx.db'); // Nome do arquivo físico
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

  // Lógica de criação da tabela - Foco no id_pigeon
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id TEXT UNIQUE,   -- ID vindo do C++ para evitar duplicados
        dweller_id TEXT,         -- Seu id_pigeon (0123456789)
        sender_id TEXT,          -- Quem enviou
        content TEXT,            -- O texto da mensagem
        timestamp TEXT           -- Horário do recebimento
      )
    ''');
  }

  // Função para salvar a mensagem vinda do server
  Future<int> saveMessage(Map<String, dynamic> row) async {
    final db = await instance.database;
    // INSERT OR IGNORE evita erro se tentar salvar a mesma mensagem duas vezes
    return await db.insert('messages', row, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Função para ler as mensagens do banco e exibir na sua lista
  Future<List<Map<String, dynamic>>> getMessages(String idPigeon) async {
    final db = await instance.database;
    return await db.query(
      'messages',
      where: 'dweller_id = ?',
      whereArgs: [idPigeon],
      orderBy: 'id DESC' // Mais recentes primeiro
    );
  }
}
