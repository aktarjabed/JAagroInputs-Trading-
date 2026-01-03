import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // For debugPrint

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
      version: 4, // Incremented version for Phase 1 & 2
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE invoices ADD COLUMN customer_gstin TEXT');
      await db.execute('ALTER TABLE invoices ADD COLUMN pdf_path TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE company_settings ADD COLUMN account_holder TEXT');
    }
    if (oldVersion < 4) {
      // Phase 1: GST Compliance
      await db.execute('ALTER TABLE invoices ADD COLUMN place_of_supply TEXT');
      await db.execute('ALTER TABLE invoices ADD COLUMN reverse_charge TEXT'); // 'Yes'/'No'
      await db.execute('ALTER TABLE invoices ADD COLUMN supply_type TEXT'); // 'Taxable', etc.
      await db.execute('ALTER TABLE invoices ADD COLUMN round_off_amount REAL DEFAULT 0.0');

      // Phase 2: Agro Data (Normalization)
      await db.execute('''
        CREATE TABLE invoice_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          invoice_number TEXT NOT NULL,
          description TEXT NOT NULL,
          hsn_code TEXT NOT NULL,
          quantity REAL NOT NULL,
          unit TEXT NOT NULL,
          rate REAL NOT NULL,
          gst_rate REAL NOT NULL,
          amount REAL NOT NULL,
          gst_amount REAL NOT NULL,
          total REAL NOT NULL,

          -- Agro Specific Fields
          product_category TEXT,
          batch_number TEXT,
          expiry_date TEXT,
          quality_grade TEXT,

          FOREIGN KEY (invoice_number) REFERENCES invoices (invoice_number) ON DELETE CASCADE
        )
      ''');

      // Migration: JSON items -> invoice_items table
      await _migrateItemsTable(db);
    }
  }

  Future<void> _migrateItemsTable(Database db) async {
    try {
      final List<Map<String, dynamic>> invoices = await db.query('invoices');
      final batch = db.batch();

      for (var invoice in invoices) {
        final invoiceNumber = invoice['invoice_number'] as String;
        final itemsJson = invoice['items'] as String?;

        if (itemsJson != null && itemsJson.isNotEmpty) {
          try {
            final List<dynamic> decodedItems = jsonDecode(itemsJson);
            for (var item in decodedItems) {
              final quantity = (item['quantity'] as num).toDouble();
              final rate = (item['rate'] as num).toDouble();
              final gstRate = (item['gstRate'] as num).toDouble();

              // Calculate derived values if missing (backward compatibility)
              final amount = quantity * rate;
              final gstAmount = amount * (gstRate / 100);
              final total = amount + gstAmount;

              batch.insert('invoice_items', {
                'invoice_number': invoiceNumber,
                'description': item['description'] ?? '',
                'hsn_code': item['hsnCode'] ?? '',
                'quantity': quantity,
                'unit': item['unit'] ?? '',
                'rate': rate,
                'gst_rate': gstRate,
                'amount': amount,
                'gst_amount': gstAmount,
                'total': total,
                // New fields will be null for old data
                'product_category': null,
                'batch_number': null,
                'expiry_date': null,
                'quality_grade': null,
              });
            }
          } catch (e) {
            debugPrint('Error parsing items for invoice $invoiceNumber: $e');
          }
        }
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Error executing migration: $e');
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
        place_of_supply TEXT,
        reverse_charge TEXT,
        supply_type TEXT,
        items TEXT, -- Kept for backward safety/redundancy or removed? Ideally removed, but keeping null is safe.
        subtotal_vegetables REAL NOT NULL,
        subtotal_fertilizers REAL NOT NULL,
        cgst REAL NOT NULL,
        sgst REAL NOT NULL,
        igst REAL NOT NULL DEFAULT 0,
        round_off_amount REAL DEFAULT 0.0,
        grand_total REAL NOT NULL,
        pdf_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL,
        description TEXT NOT NULL,
        hsn_code TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        rate REAL NOT NULL,
        gst_rate REAL NOT NULL,
        amount REAL NOT NULL,
        gst_amount REAL NOT NULL,
        total REAL NOT NULL,
        product_category TEXT,
        batch_number TEXT,
        expiry_date TEXT,
        quality_grade TEXT,
        FOREIGN KEY (invoice_number) REFERENCES invoices (invoice_number) ON DELETE CASCADE
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
        unit TEXT NOT NULL,
        category TEXT -- Phase 2: Category
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
        ifsc_code TEXT,
        account_holder TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_invoice_date ON invoices(invoice_date)');
    await db.execute('CREATE INDEX idx_invoice_number ON invoices(invoice_number)');
    await db.execute('CREATE INDEX idx_customer_name ON invoices(customer_name)');
    await db.execute('CREATE INDEX idx_invoice_items_inv_num ON invoice_items(invoice_number)');

    // Insert REAL company settings from your invoice
    await db.insert('company_settings', {
      'id': 1,
      'company_name': 'JA Agro Inputs & Trading',
      'address': 'Dhanehari II, P.O - Saidpur(Mukam)',
      'city': 'Cachar',
      'state': 'Assam',
      'pincode': '788013',
      'gstin': '18CCFPB3144R1Z5',
      'pan': 'CCFPB3144R',
      'phone': '8133878179',
      'email': 'jaagro@example.com',
      'bank_name': 'State Bank of India',
      'account_number': '36893269388',
      'ifsc_code': 'SBIN0001803',
      'account_holder': 'JA Agro Inputs & Trading',
    });

    // Insert sample customer from your invoice
    await db.insert('customers', {
      'name': 'Ruksana Begum Laskar',
      'address': 'Neairgram Part II',
      'city': 'Cachar',
      'state': 'Assam',
      'pincode': '788013',
      'gstin': '',
    });

    await _insertDefaultHSN(db);
  }

  Future<void> _insertDefaultHSN(Database db) async {
    final batch = db.batch();
    // Re-using the updated list with Categories if possible, or mapping them.
    // Since this runs on clean install, we can put full data.
    // For now, using the original list structure but we should update it to include categories if we added that column.
    // Note: I added `category` column to `hsn_codes` in `_createDB`.

    final hsnData = [
      {'code': '0701', 'description': 'Potato (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Vegetables'},
      {'code': '0702', 'description': 'Tomato (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Vegetables'},
      {'code': '0703', 'description': 'Onion (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Vegetables'},
      {'code': '0704', 'description': 'Cauliflower (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Vegetables'},
      {'code': '0704', 'description': 'Cabbage (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Vegetables'},
      {'code': '0705', 'description': 'Lettuce (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Vegetables'},
      {'code': '0706', 'description': 'Carrot (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Vegetables'},
      {'code': '0707', 'description': 'Cucumber (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Vegetables'},
      {'code': '0708', 'description': 'Beans (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Vegetables'},
      {'code': '0709', 'description': 'Chilli - Green (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Vegetables'},
      {'code': '0709', 'description': 'Eggplant/Brinjal (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Vegetables'},
      {'code': '0709', 'description': 'Pumpkin (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Vegetables'},
      {'code': '0710', 'description': 'Frozen Vegetables', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Vegetables'},
      {'code': '0801', 'description': 'Coconut (Fresh)', 'gst_rate': 0.0, 'unit': 'Piece', 'category': 'Fruits'},
      {'code': '0803', 'description': 'Banana (Fresh)', 'gst_rate': 0.0, 'unit': 'Dozen', 'category': 'Fruits'},
      {'code': '0804', 'description': 'Mango (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Fruits'},
      {'code': '0805', 'description': 'Orange (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Fruits'},
      {'code': '0806', 'description': 'Grapes (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Fruits'},
      {'code': '0807', 'description': 'Watermelon (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Fruits'},
      {'code': '0808', 'description': 'Apple (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Fruits'},
      {'code': '0809', 'description': 'Apricot (Fresh)', 'gst_rate': 0.0, 'unit': 'Kg', 'category': 'Fruits'},
      {'code': '1001', 'description': 'Wheat', 'gst_rate': 0.0, 'unit': 'Quintal', 'category': 'Cereals'},
      {'code': '1006', 'description': 'Rice', 'gst_rate': 0.0, 'unit': 'Quintal', 'category': 'Cereals'},
      {'code': '3102', 'description': 'Urea Fertilizer (45 kg bag)', 'gst_rate': 5.0, 'unit': 'Bag', 'category': 'Fertilizers'},
      {'code': '3103', 'description': 'Superphosphate Fertilizer', 'gst_rate': 5.0, 'unit': 'Bag', 'category': 'Fertilizers'},
      {'code': '3104', 'description': 'Potash Fertilizer', 'gst_rate': 5.0, 'unit': 'Bag', 'category': 'Fertilizers'},
      {'code': '3105', 'description': 'DAP Fertilizer (50 kg bag)', 'gst_rate': 5.0, 'unit': 'Bag', 'category': 'Fertilizers'},
      {'code': '3105', 'description': 'NPK Fertilizer', 'gst_rate': 5.0, 'unit': 'Bag', 'category': 'Fertilizers'},
      {'code': '3808', 'description': 'Insecticides', 'gst_rate': 18.0, 'unit': 'Liter', 'category': 'Pesticides'},
      {'code': '3808', 'description': 'Pesticides', 'gst_rate': 18.0, 'unit': 'Liter', 'category': 'Pesticides'},
      {'code': '3808', 'description': 'Herbicides', 'gst_rate': 18.0, 'unit': 'Liter', 'category': 'Pesticides'},
      {'code': '8201', 'description': 'Hand Tools (Spade, Fork)', 'gst_rate': 18.0, 'unit': 'Piece', 'category': 'Tools'},
      {'code': '8424', 'description': 'Sprayers', 'gst_rate': 18.0, 'unit': 'Piece', 'category': 'Machinery'},
      {'code': '8432', 'description': 'Agriculture Machinery', 'gst_rate': 12.0, 'unit': 'Piece', 'category': 'Machinery'},
      {'code': '5607', 'description': 'Jute Bags', 'gst_rate': 5.0, 'unit': 'Piece', 'category': 'Packaging'},
      {'code': '3920', 'description': 'Plastic Sheets (Mulching)', 'gst_rate': 18.0, 'unit': 'Kg', 'category': 'Packaging'},
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

    if (result.isNotEmpty) {
      var invoice = Map<String, dynamic>.from(result.first);
      // Fetch items from the new table
      final items = await db.query(
        'invoice_items',
        where: 'invoice_number = ?',
        whereArgs: [invoiceNumber],
      );

      // We attach items list directly. The UI/Model handles parsing.
      // Note: 'items' column in invoices table is legacy/null now.
      // We overwrite/set 'items' key to be the List<Map> from invoice_items.
      invoice['items'] = items;
      return invoice;
    }
    return null;
  }

  // INSERT INVOICE - UPDATED
  Future<int> insertInvoice(Map<String, dynamic> invoice, Map<String, dynamic> customer, List<Map<String, dynamic>> items) async {
    final db = await database;

    return await db.transaction((txn) async {
      // 1. Insert/Update Customer
      await txn.insert(
        'customers',
        customer,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Insert Invoice
      // Remove 'items' from the invoice map if it exists as we store in separate table
      var invoiceData = Map<String, dynamic>.from(invoice);
      invoiceData.remove('items');
      // Ensure new fields are present

      final invoiceId = await txn.insert('invoices', invoiceData);
      final invoiceNumber = invoiceData['invoice_number'];

      // 3. Insert Items
      for (var item in items) {
        var itemData = Map<String, dynamic>.from(item);
        itemData['invoice_number'] = invoiceNumber;
        await txn.insert('invoice_items', itemData);
      }

      return invoiceId;
    });
  }

  Future<List<Map<String, dynamic>>> getAllInvoices() async {
    final db = await database;
    return await db.query('invoices', orderBy: 'created_at DESC');
  }

  Future<int> deleteInvoice(String invoiceNumber) async {
    final db = await database;
    // Cascade delete handles items
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
