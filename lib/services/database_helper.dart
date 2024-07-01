import 'package:path_provider/path_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';


// This class holds all information about a single block.
class Block implements Comparable {
  int _id;
  int _version;
  Database _versionsDatabase;
  Future<Database> _db;
  String _tableName;
  String label;
  String instructions;
  static int _highestID = 0;


  // Constructor.
  Block({@required String label, @required String instructions, int id = -1, int version = 1}) {
    this.label = label;
    this.instructions = instructions;
    this._version = version;
    Block.incrementHighestID();
    if (id == -1) {
      this._id = Block.getHighestID();
    } else {
      this._id = id;
    }
    this._tableName = 'id_${this._id}_versions';
    this._db = DatabaseHelper.initDatabase(
      table: this._tableName,
      primaryKey: 'version',
    );
  }


  // Converts a block to its hash-map equivalent for storage.
  Map<String, dynamic> blockMap() {
    return {
      'id': _id,
      'label': label,
      'instructions': instructions,
      'version': _version,
    };
  }


  // Converts a block to its hash-map equivalent for version control.
  Map<String, dynamic> versionMap() {
    return {
      'version': _version,
      'label': label,
      'instructions': instructions,
    };
  }


  // Returns the id of the block.
  int getID()
  { return this._id; }


  // Returns the current version of the block.
  int getVersion()
  { return this._version; }


  // Updates the current version to the next one.
  void updateVersion()
  { this._version++; }


  // Returns the table name of the block.
  String getTableName()
  { return this._tableName; }


  // Returns the history database of the block.
  Database getVersionsDatabase()
  { return this._versionsDatabase; }


  // Overriding operators.
  ////////////////////////////////////////////////////////////
  @override
  int compareTo(other)
  { return this.label.compareTo(other.label); }

  @override
  bool operator ==(Object other)
  { return other is Block && this.label == other.label; }

  @override
  int get hashCode
  { return this.label.hashCode; }

  @override
  String toString() {
    return 'Block('
        '\n  id: ${this._id},'
        '\n  label: "${this.label}",'
        '\n  instructions: "${this.instructions}",'
        '\n  version: ${this._version},'
        '\n)';
  }
  ////////////////////////////////////////////////////////////


  // Static functions managing the highest id variable.
  ////////////////////////////////////////////////////////////
  static void setHighestID(int id)
  { _highestID = id; }

  static void incrementHighestID() {
    if (_highestID == null) {
      resetHighestID();
    }
    _highestID++;
  }

  static int getHighestID()
  { return _highestID; }

  static void resetHighestID()
  { _highestID = 0; }
  ////////////////////////////////////////////////////////////


}



// This class manages the database for all of the blocks in the list.
class DatabaseHelper {
  Future<Database> futureDB;
  Database db;
  Future<List<Block>> futureBlocks;
  List<Block> allBlocks;


  // Constructor
  DatabaseHelper() {
    this.futureDB = initDatabase(
      table: 'blocks',
      primaryKey: 'id'
    );
    this.futureBlocks = initBlocks();
  }


  // Returns the string representation of the database helper.
  @override
  String toString() {
    String text = 'DatabaseHelper('
        '\n  futureDB: ${this.futureDB}'
        '\n  db: ${this.db}'
        '\n  futureBlocks: ${this.futureBlocks}'
        '\n  allBlocks: ';
    if (this.allBlocks == null) {
      text += '${this.allBlocks}';
    } else {
      text += 'Block[${this.allBlocks.length}]';
    }
    text += '\n)';
    return text;
  }


  // Returns the maximum block id in the database once available.
  Future<int> getMaxID() async {
    return Sqflite.firstIntValue(await db.rawQuery('SELECT MAX(id) FROM blocks'));
  }


  // Initialises and, once available, returns the database manager.
  static Future<Database> initDatabase({String table, String primaryKey}) async {
    String sql = 'CREATE TABLE $table';
    sql += '($primaryKey INTEGER PRIMARY KEY AUTOINCREMENT, label TEXT, instructions TEXT';
    if (primaryKey == 'id') {
      sql += ', version INTEGER)';
    } else {
      sql += ')';
    }
    Future<Database> temp = openDatabase(
      join(await getDatabasesPath(), 'blocks.db'),
      onCreate: (db, version) {
        return db.execute(sql);
      },
      version: 1,
    );
    return temp;
  }


  // Initialises and, once available, returns the data from the database.
  Future<List<Block>> initBlocks() async {
    this.db = await futureDB;
    Block.setHighestID( Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(id) FROM blocks')) );

    // debugging
    print('(database_helper.dart) highestID = ${Block.getHighestID()}');

    if (Block.getHighestID() == 0) {
      print('(database_helper.dart) Populating database...');
      return populateDatabase();
    } else {
      print('(database_helper.dart) Loading database...');
      return loadDatabase();
    }
  }


  // Populates the database with default values,
  // and returns the list of values.
  Future<List<Block>> populateDatabase() async {
    dynamic list = generateBlocks();
    for (int i = 0; i < list.length; i++) {
      await insertBlock(list[i]);
    }
    return list;
  }


  // Loads the values stored in the database,
  // and returns the list of values.
  Future<List<Block>> loadDatabase() async {
    final dynamic data = await db.query('blocks', orderBy: 'label');
    return List.generate(data.length, (index) {
      return Block(
        id: data[index]['id'],
        label: data[index]['label'],
        instructions: data[index]['instructions'],
        version: data[index]['version'],
      );
    });
  }


  // Ensures that the list of blocks are correctly
  // assigned to the variable allBlocks.
  Future<void> loadAllBlocks() async {
    allBlocks = await futureBlocks;
    Block.setHighestID( await getMaxID() );
    for (int i = 0; i < allBlocks.length; i++) {
      await loadBlock(allBlocks[i]);
    }
  }


  // Ensures that the database has been properly
  // loaded for the given block.
  Future<void> loadBlock(Block block) async {
    block._versionsDatabase = await block._db;
  }


  // Recreates the versions databases after restoring to default.
  Future<void> recreateAllVersionsTables() async {
    for (int i = 0; i < allBlocks.length; i++) {
      await recreateVersionsTable(allBlocks[i]);
    }
  }


  // Recreates the versions database for the given block.
  Future<void> recreateVersionsTable(Block block) async {
    await block.getVersionsDatabase().execute(
        'DROP TABLE IF EXISTS ${block.getTableName()}'
    );
    await block.getVersionsDatabase().execute(
        'CREATE TABLE ${block.getTableName()}'
            '(version INTEGER PRIMARY KEY AUTOINCREMENT, label TEXT, instructions TEXT)'
    );

    // debugging
    print('(database_helper.dart) >> Repopulating ${block.getTableName()}');
  }


  // Creates all of the versions databases if it doesn't already exist.
  Future<void> createAllVersionsTables() async {
    for (int i = 0; i < allBlocks.length; i++) {
      await createVersionsTable( allBlocks[i] );
    }
  }


  // Creates the versions database if it doesn't already exist.
  Future<void> createVersionsTable(Block block) async {
    try {
      await block.getVersionsDatabase().rawQuery(
          'SELECT COUNT(*) FROM ${block.getTableName()}'
      );
    } catch (error) {
      await block.getVersionsDatabase().execute(
          'CREATE TABLE ${block.getTableName()}'
              '(version INTEGER PRIMARY KEY AUTOINCREMENT, label TEXT, instructions TEXT)'
      );
    }
  }


  // Restores the values in the database to the default ones,
  // and reloads them into the appropriate variables.
  Future<void> resetDatabase() async {
    for (int i = 0; i < allBlocks.length; i++) {
      allBlocks[i].getVersionsDatabase().execute(
          'DROP TABLE IF EXISTS ${allBlocks[i].getTableName()}'
      );
    }
    await db.execute('DROP TABLE IF EXISTS blocks');
    await db.execute('CREATE TABLE blocks(id INTEGER PRIMARY KEY, label TEXT, instructions TEXT, version INTEGER)');
    this.futureDB = initDatabase(
      table: 'blocks',
      primaryKey: 'id',
    );
    this.futureBlocks = initBlocks();
    Block.resetHighestID();
    await loadAllBlocks();
    await recreateAllVersionsTables();

    // debugging
    print('(database_helper.dart) Database has been reset');
  }


  // Inserts a new block into the database.
  Future<void> insertBlock(Block block) async {
    await db.insert(
      'blocks',
      block.blockMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    Block.setHighestID( await getMaxID() );
  }


  // Inserts a new block into the database.
  Future<void> insertVersion(Block block) async {
    await block.getVersionsDatabase().insert(
      '${block.getTableName()}',
      block.versionMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  // Reads the version of the block into the database.
  static Future<List<Map>> getVersionsList(Block block) async {
    return block.getVersionsDatabase().query(block.getTableName());
  }


  // Sets the version of the block to the specified version.
  static void setVersion(Block block, Map data) {
    block._version = data['version'];
    block.label = data['label'];
    block.instructions = data['instructions'];
  }


  // Updates the data of a particular block in
  // the database to that of the given block.
  Future<void> updateBlock(Block block) async {
    await db.update(
      'blocks',
      block.blockMap(),
      where: 'id = ?',
      whereArgs: [block.getID()],
    );
    allBlocks.sort((a, b) => a.label.compareTo(b.label));
  }


  // Deletes the given block from the database.
  Future<void> deleteBlock(Block block) async {
    await db.delete(
      'blocks',
      where: 'id = ?',
      whereArgs: [block.getID()],
    );
    Block.setHighestID( await getMaxID() );
  }


  // Deletes all versions from the database below the given one.
  static Future<void> deleteVersions(Block block, int selectedVersion) async {
    await block.getVersionsDatabase().execute(
        'DELETE FROM ${block.getTableName()} '
            'WHERE version >= $selectedVersion');
  }


  // Deleted the versions database for the given block.
  Future<void> deleteVersionsDatabase(Block block) async {
    await block.getVersionsDatabase().execute(
        'DROP TABLE IF EXISTS ${block.getTableName()}'
    );
    Block.setHighestID( await getMaxID() );

    // debugging
    try {
      await block.getVersionsDatabase().execute(
          'SELECT * FROM ${block.getTableName()}'
      );
    } catch (error) {}
  }


  // Returns the newly generated default values.
  List<Block> generateBlocks() {
    List<Block> blocks = [
      Block(
        label: '10% lie',
        instructions: 'Every player who masturbates must drink 1.'),
      Block(
        label: '9-11 secret terrorist cell member',
        instructions: 'Pick a code word. If you hear this code word, you must destroy the tower or drink 1.'),
      Block(
        label: 'Anti-Santa',
        instructions: 'Sit in the lap of the person across from you.'),
      Block(
        label: 'Baby',
        instructions: 'The youngest person in the group must drink 3.'),
      Block(
        label: 'Battle of the sexes',
        instructions: 'Everyone of the opposite sex to yours must drink 1.'),
      Block(
        label: 'Beer wench',
        instructions: 'You are the beer wench (fetch drinks for the rest of the game) or drink 2.'),
      Block(
        label: 'Bipolar',
        instructions: 'You must insult the person to your right, then complement the person to your left, or drink 1.'),
      Block(
        label: 'Bob Dole',
        instructions: 'You must refer to yourself in the third person for the rest of the game. Drink 1 for every time you forget.'),
      Block(
        label: 'Broken toe',
        instructions: 'For the rest of the game, you must pull pieces whilst standing on your toes, or down your drink.'),
      Block(
        label: 'Castaway',
        instructions: 'You can only talk to inanimate objects for the rest of the game, or drink 5.'),
      Block(
        label: 'Cat lady',
        instructions: 'All cat owners give 1 drink for each cat they have.'),
      Block(
        label: 'Celtic heritage',
        instructions: 'Dance your best jig, or drink 3.'),
      Block(
        label: 'Chuck Barber',
        instructions: 'If you don’t have a moustache, play the rest of the game with your left index finger on your upper lip or drink 2.'),
      Block(
        label: 'Come and get it!',
        instructions: 'Everyone wearing a ring must drink 2.'),
      Block(
        label: 'Condiment delivery system',
        instructions: 'Do a shot of an available condiment (tomato sauce, mustard, etc.) or finish your drink.'),
      Block(
        label: 'Did you grow up in a barn?',
        instructions: 'Choose someone to make an animal sound every time another person drinks for the rest of the game. Drink 1 every time you forget.'),
      Block(
        label: 'Do over',
        instructions: 'Put this piece back where you found it and take a different one.'),
      Block(
        label: 'Drill instructor',
        instructions: 'You must "motivate" everyone else as they place their pieces on the tower, or drink 3.'),
      Block(
        label: 'Foot massage',
        instructions: 'Give the person to your right a foot massage, or drink 5.'),
      Block(
        label: 'Hand switch',
        instructions: 'Pick someone that must play with their opposite hand for the rest of the game. Each time they fail they must drink 1.'),
      Block(
        label: 'Hands across Africa',
        instructions: 'You must keep physical contact with the person to your right for the remainder of the game. Drink 1 every time you fail.'),
      Block(
        label: 'Hanging with ladies',
        instructions: 'Drink one for every female player.'),
      Block(
        label: 'Hey, red shirt!',
        instructions: 'Finish your drink!'),
      Block(
        label: 'Hillbilly',
        instructions: 'You must play the rest of the game without wearing any socks or shoes, or drink 3.'),
      Block(
        label: 'Impression',
        instructions: 'Do your best impression of one of the other players. Drink 5 if the group thinks it’s bad and 1 if they think it’s good.'),
      Block(
        label: 'Inventory',
        instructions: 'Describe everyone’s shirts, then drink 5.'),
      Block(
        label: 'Jester',
        instructions: 'You’re at the mercy of the person to your right. Do as they say or drink 2 for the remainder of the game.'),
      Block(
        label: 'Kevin Wise',
        instructions: 'Remove your shoes and have a member of the opposite sex put them back on your feet, or drink 2.'),
      Block(
        label: 'Kiss right',
        instructions: 'Kiss the person to your right, or drink 5.'),
      Block(
        label: 'Name genie',
        instructions: 'Give all players a new name. All players must use their new names, or drink 1 every time they mess up.'),
      Block(
        label: 'Oh no! Someone stole my Kayak!',
        instructions: 'Steal another player’s drink, and drink on their behalf for the remainder of the game.'),
      Block(
        label: 'Peer pressure',
        instructions: 'Drink 1 for each person playing the game.'),
      Block(
        label: 'Puller\'s choice',
        instructions: 'Select one person to exchange an article of clothing with someone else, or order someone to finish their drink.'),
      Block(
        label: 'Rainbow warrior',
        instructions: 'Pick a colour. Everyone wearing an article of clothing that contains this colour must drink 1.'),
      Block(
        label: 'Santa',
        instructions: 'The next person must take their turn sitting on your lap or drink 1.'),
      Block(
        label: 'Scar stories',
        instructions: 'Tell a story that led to a scar on your body, or drink 3.'),
      Block(
        label: 'Screw the NFL kicker',
        instructions: 'Drink 1 for every letter in your last name.'),
      Block(
        label: 'Skip',
        instructions: 'Skip the next player’s turn or both finish their drinks.'),
      Block(
        label: 'Social',
        instructions: 'Everyone playing must drink 1.'),
      Block(
        label: 'Straight jacket',
        instructions: 'Give the tower a name, and talk ONLY to it for the rest of the game, or drink 1 for each player.'),
      Block(
        label: 'Truth or dare',
        instructions: 'Answer a truth from the player to your right, or perform a dare from the player to your left.'),
      Block(
        label: 'Voyeur',
        instructions: 'Every player that you’ve seen naked must drink 2.'),
      Block(
        label: 'What a gem!',
        instructions: 'Have a drink for every piece of jewellery on your body. This includes watches, charms, navel rings, etc.'),
      Block(
        label: 'Wonder twin power activate',
        instructions: 'Choose someone to drink with you for the rest of the game.'),
    ];
    return blocks;
  }


  // Copies the database in the assets folder to the device.
  Future<void> copyAssetsDatabase() async {

    // Construct a file path to copy database to.
    Directory directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, 'blocks.db');

    // Only copy if the database doesn't exist.
    // if (FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound) {

    // Load database from asset and copy.
    ByteData data = await rootBundle.load(join('assets', 'jenga.db'));
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    // Save copied asset to documents.
    await File(path).writeAsBytes(bytes);
    // }
  }


} // End of class definition.