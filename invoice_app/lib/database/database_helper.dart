import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('invoice.db');
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE invoices ADD COLUMN gstin TEXT');
      await db.execute('ALTER TABLE invoices ADD COLUMN pdf_path TEXT');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT UNIQUE NOT NULL,
        invoice_date TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        customer_address TEXT NOT NULL,
        customer_city TEXT NOT NULL,
        customer_state TEXT NOT NULL,
        customer_pincode TEXT NOT NULL,
        customer_gstin TEXT,
        items TEXT NOT NULL,
        subtotal_vegetables REAL NOT NULL,
        subtotal_fertilizers REAL NOT NULL,
        cgst REAL NOT NULL,
        sgst REAL NOT NULL,
        igst REAL NOT NULL DEFAULT 0,
        grand_total REAL NOT NULL,
        pdf_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        city TEXT NOT NULL,
        state TEXT NOT NULL,
        pincode TEXT NOT NULL,
        gstin TEXT,
        UNIQUE(name, pincode)
      )
    ''');

    await db.execute('''
      CREATE TABLE hsn_codes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        description TEXT NOT NULL,
        gst_rate REAL NOT NULL,
        unit TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE company_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        company_name TEXT NOT NULL,
        address TEXT NOT NULL,
        city TEXT NOT NULL,
        state TEXT NOT NULL,
        pincode TEXT NOT NULL,
        gstin TEXT NOT NULL,
        pan TEXT,
        phone TEXT,
        email TEXT,
        bank_name TEXT,
        account_number TEXT,
        ifsc_code TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_invoice_date ON invoices(invoice_date)');
    await db.execute('CREATE INDEX idx_invoice_number ON invoices(invoice_number)');
    await db.execute('CREATE INDEX idx_customer_name ON invoices(customer_name)');

    await db.insert('company_settings', {
      'id': 1,
      'company_name': 'JA Agro Inputs & Trading',
      'address': 'Main Market Road',
      'city': 'Nagaon',
      'state': 'Assam',
      'pincode': '782001',
      'gstin': '18XXXXX0000X1ZX',
      'phone': '+91-XXXXXXXXXX',
      'email': 'info@jaagro.com',
    });

    await _insertDefaultHSN(db);
  }

  Future<void> _insertDefaultHSN(Database db) async {
    final batch = db.batch();
    final hsnData = [
      {'code': '0701', 'description': 'Potato (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '0702', 'description': 'Tomato (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '0703', 'description': 'Onion (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '0704', 'description': 'Cauliflower (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '0704', 'description': 'Cabbage (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '0705', 'description': 'Lettuce (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '0706', 'description': 'Carrot (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '0707', 'description': 'Cucumber (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '0708', 'description': 'Beans (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '0709', 'description': 'Chilli - Green (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '0709', 'description': 'Eggplant/Brinjal (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '0709', 'description': 'Pumpkin (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '0710', 'description': 'Frozen Vegetables', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '0801', 'description': 'Coconut (Fresh)', 'gst_rate': 0.0, 'unit': 'Piece'},
      {'code': '0803', 'description': 'Banana (Fresh)', 'gst_rate': 0.0, 'unit': 'Dozen'},
      {'code': '0804', 'description': 'Mango (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '0805', 'description': 'Orange (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '0806', 'description': 'Grapes (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '0807', 'description': 'Watermelon (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '0808', 'description': 'Apple (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '0809', 'description': 'Apricot (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg'},
      {'code': '1001', 'description': 'Wheat', 'gst_rate': 0.0, 'unit': 'Quintal'},
      {'code': '1006', 'description': 'Rice', 'gst_rate': 0.0, 'unit': 'Quintal'},
      {'code': '3102', 'description': 'Urea Fertilizer (45 kg bag)', 'gst_rate': 5.0, 'unit': 'Bag'},
      {'code': '3103', 'description': 'Superphosphate Fertilizer', 'gst_rate': 5.0, 'unit': 'Bag'},
      {'code': '3104', 'description': 'Potash Fertilizer', 'gst_rate': 5.0, 'unit': 'Bag'},
      {'code': '3105', 'description': 'DAP Fertilizer (50 kg bag)', 'gst_rate': 5.0, 'unit': 'Bag'},
      {'code': '3105', 'description': 'NPK Fertilizer', 'gst_rate': 5.0, 'unit': 'Bag'},
      {'code': '3808', 'description': 'Insecticides', 'gst_rate': 18.0, 'unit': 'Liter'},
      {'code': '3808', 'description': 'Pesticides', 'gst_rate': 18.0, 'unit': 'Liter'},
      {'code': '3808', 'description': 'Herbicides', 'gst_rate': 18.0, 'unit': 'Liter'},
      {'code': '8201', 'description': 'Hand Tools (Spade, Fork)', 'gst_rate': 18.0, 'unit': 'Piece'},
      {'code': '8424', 'description': 'Sprayers', 'gst_rate': 18.0, 'unit': 'Piece'},
      {'code': '8432', 'description': 'Agriculture Machinery', 'gst_rate': 12.0, 'unit': 'Piece'},
      {'code': '5607', 'description': 'Jute Bags', 'gst_rate': 5.0, 'unit': 'Piece'},
      {'code': '3920', 'description': 'Plastic Sheets (Mulching)', 'gst_rate': 18.0, 'unit': 'Kg'},
    ];

    for (var hsn in hsnData) {
      batch.insert('hsn_codes', hsn);
    }
    await batch.commit(noResult: true);
  }

  Future<bool> checkInvoiceExists(String invoiceNumber) async {
    final db = await database;
    final result = await db.query(
      'invoices',
      where: 'invoice_number = ?',
      whereArgs: [invoiceNumber],
    );
    return result.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getInvoiceByNumber(String invoiceNumber) async {
    final db = await database;
    final result = await db.query(
      'invoices',
      where: 'invoice_number = ?',
      whereArgs: [invoiceNumber],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> insertInvoice(Map<String, dynamic> invoice, Map<String, dynamic> customer) async {
    final db = await database;

    return await db.transaction((txn) async {
      final invoiceId = await txn.insert('invoices', invoice);
      await txn.insert(
        'customers',
        customer,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return invoiceId;
    });
  }

  Future<List<Map<String, dynamic>>> getAllInvoices() async {
    final db = await database;
    return await db.query('invoices', orderBy: 'created_at DESC');
  }

  Future<int> deleteInvoice(String invoiceNumber) async {
    final db = await database;
    return await db.delete(
      'invoices',
      where: 'invoice_number = ?',
      whereArgs: [invoiceNumber],
    );
  }

  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    final db = await database;
    return await db.query(
      'customers',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      limit: 10,
    );
  }

  Future<List<Map<String, dynamic>>> searchHSN(String query) async {
    final db = await database;
    return await db.query(
      'hsn_codes',
      where: 'description LIKE ? OR code LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      limit: 20,
    );
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;

    final totalInvoices = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM invoices'),
    ) ?? 0;

    final revenueResult = await db.rawQuery('SELECT SUM(grand_total) as total FROM invoices');
    final totalRevenue = (revenueResult.first['total'] as num?)?.toDouble() ?? 0.0;

    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final todayInvoices = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM invoices WHERE invoice_date = ?',
        [today],
      ),
    ) ?? 0;

    final recentInvoices = await db.query(
      'invoices',
      orderBy: 'created_at DESC',
      limit: 5,
    );

    return {
      'totalInvoices': totalInvoices,
      'totalRevenue': totalRevenue,
      'todayInvoices': todayInvoices,
      'recentInvoices': recentInvoices,
    };
  }

  Future<Map<String, dynamic>> getCompanySettings() async {
    final db = await database;
    final result = await db.query('company_settings', where: 'id = 1');
    return result.first;
  }

  Future<File> exportDatabase() async {
    final dbPath = await getDatabasesPath();
    final source = File(join(dbPath, 'invoice.db'));
    final appDocDir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backup = File(join(appDocDir.path, 'invoice_backup_$timestamp.db'));
    await source.copy(backup.path);
    return backup;
  }
}
