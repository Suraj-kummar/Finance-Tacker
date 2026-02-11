import '../db/statement_db_helper.dart';

class NormalizationService {
  final StatementDBHelper _dbHelper = StatementDBHelper.instance;

  // Cache
  Map<String, String> _cache = {};

  Future<void> loadMap() async {
    final db = await _dbHelper.database;
    final results = await db.query('person_map');
    
    _cache.clear();
    for (var row in results) {
      final finalName = row['finalName'] as String;
      final identifiers = (row['identifiers'] as String).split(',');
      for (var id in identifiers) {
        _cache[id.trim().toLowerCase()] = finalName;
      }
    }
  }

  Future<String> normalizePersonName(String rawName) async {
    if (_cache.isEmpty) {
      await loadMap();
    }
    
    String cleanRaw = rawName.trim();
    // Check exact match
    if (_cache.containsKey(cleanRaw.toLowerCase())) {
        return _cache[cleanRaw.toLowerCase()]!;
    }
    
    // Check URI/UPI pattern
    // rahulkumar@okicici -> Rahul Kumar (Maybe?)
    if (cleanRaw.contains('@')) {
       // Extract part before @
       // cleanRaw = cleanRaw.split('@')[0];
    }
    
    return cleanRaw; // Return original if no map
  }
  
  Future<void> addRule(String rawIdentifier, String finalName) async {
      // Add to DB and update cache
      // Logic to append to existing row or create new
      _cache[rawIdentifier.toLowerCase()] = finalName;
  }
}
