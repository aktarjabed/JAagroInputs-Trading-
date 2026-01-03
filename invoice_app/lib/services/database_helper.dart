// lib/services/database_helper.dart
// COMPLETE - PRODUCTION READY
// SQLite Database Management with Migrations & Normalization

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/invoice_model.dart';

class InvoiceDatabase {
  static final InvoiceDatabase instance = InvoiceDatabase._init();
  static Database? _database;

  InvoiceDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('invoices.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL UNIQUE,
        date TEXT NOT NULL,
        buyer_name TEXT NOT NULL,
        buyer_gstin TEXT NOT NULL,
        buyer_pan TEXT NOT NULL,
        buyer_state TEXT NOT NULL,
        buyer_type TEXT NOT NULL,
        buyer_contact_person TEXT NOT NULL,
        place_of_supply TEXT NOT NULL,
        supply_type TEXT NOT NULL,
        reverse_charge_mechanism TEXT NOT NULL,
        subtotal REAL NOT NULL,
        cgst_amount REAL NOT NULL,
        sgst_amount REAL NOT NULL,
        igst_amount REAL NOT NULL,
        total_tax_amount REAL NOT NULL,
        discount_amount REAL NOT NULL,
        grand_total REAL NOT NULL,
        amount_in_words TEXT NOT NULL,
        payment_terms TEXT NOT NULL,
        payment_due_date TEXT NOT NULL,
        status TEXT NOT NULL,
        delivery_address TEXT,
        delivery_date TEXT,
        po_reference_number TEXT,
        e_way_bill_number TEXT,
        transporter_name TEXT,
        vehicle_number TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_items (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        hsn_code TEXT NOT NULL,
        product_name TEXT NOT NULL,
        product_category TEXT,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        rate REAL NOT NULL,
        line_total REAL NOT NULL,
        batch_number TEXT,
        expiry_date TEXT,
        quality_grade TEXT,
        storage_location TEXT,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE hsn_codes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hsn_code TEXT NOT NULL UNIQUE,
        product_name TEXT NOT NULL,
        product_category TEXT NOT NULL,
        gst_rate REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE company_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_name TEXT NOT NULL,
        gstin TEXT NOT NULL,
        pan TEXT NOT NULL,
        address TEXT NOT NULL,
        city TEXT NOT NULL,
        state TEXT NOT NULL,
        pincode TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        bank_name TEXT NOT NULL,
        bank_account_number TEXT NOT NULL,
        bank_ifsc TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE buyer_profiles (
        id TEXT PRIMARY KEY,
        buyer_name TEXT NOT NULL,
        gstin TEXT NOT NULL UNIQUE,
        pan TEXT NOT NULL,
        state TEXT NOT NULL,
        buyer_type TEXT NOT NULL,
        contact_person TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        address TEXT NOT NULL,
        credit_limit REAL NOT NULL DEFAULT 0,
        outstanding_balance REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_invoice_number ON invoices(invoice_number)');
    await db.execute('CREATE INDEX idx_buyer_gstin ON invoices(buyer_gstin)');
    await db.execute('CREATE INDEX idx_invoice_date ON invoices(date)');
    await db.execute('CREATE INDEX idx_invoice_status ON invoices(status)');
    await db.execute('CREATE INDEX idx_invoice_items_invoice_id ON invoice_items(invoice_id)');
    await db.execute('CREATE INDEX idx_hsn_code ON hsn_codes(hsn_code)');

    await _seedHSNCodes(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE invoice_items ADD COLUMN batch_number TEXT');
      await db.execute('ALTER TABLE invoice_items ADD COLUMN expiry_date TEXT');
      await db.execute('ALTER TABLE invoice_items ADD COLUMN quality_grade TEXT');
      await db.execute('ALTER TABLE invoice_items ADD COLUMN storage_location TEXT');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS buyer_profiles (
          id TEXT PRIMARY KEY,
          buyer_name TEXT NOT NULL,
          gstin TEXT NOT NULL UNIQUE,
          pan TEXT NOT NULL,
          state TEXT NOT NULL,
          buyer_type TEXT NOT NULL,
          contact_person TEXT NOT NULL,
          phone TEXT NOT NULL,
          email TEXT NOT NULL,
          address TEXT NOT NULL,
          credit_limit REAL NOT NULL DEFAULT 0,
          outstanding_balance REAL NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> _seedHSNCodes(Database db) async {
    final hsnCodes = [
      {'hsn': '0701', 'product': 'Potato (Fresh)', 'category': 'Vegetables', 'gst': 0.0},
      {'hsn': '0702', 'product': 'Tomato (Fresh)', 'category': 'Vegetables', 'gst': 0.0},
      {'hsn': '0703', 'product': 'Onion (Fresh)', 'category': 'Vegetables', 'gst': 0.0},
      {'hsn': '0704', 'product': 'Cabbage/Cauliflower (Fresh)', 'category': 'Vegetables', 'gst': 0.0},
      {'hsn': '0705', 'product': 'Lettuce/Chicory (Fresh)', 'category': 'Vegetables', 'gst': 0.0},
      {'hsn': '0706', 'product': 'Carrot/Turnip (Fresh)', 'category': 'Vegetables', 'gst': 0.0},
      {'hsn': '0707', 'product': 'Cucumber/Gherkin (Fresh)', 'category': 'Vegetables', 'gst': 0.0},
      {'hsn': '0708', 'product': 'Leguminous Vegetables (Fresh)', 'category': 'Vegetables', 'gst': 0.0},
      {'hsn': '0709', 'product': 'Other Vegetables (Fresh)', 'category': 'Vegetables', 'gst': 0.0},
      {'hsn': '1001', 'product': 'Wheat', 'category': 'Cereals', 'gst': 5.0},
      {'hsn': '1002', 'product': 'Rye', 'category': 'Cereals', 'gst': 5.0},
      {'hsn': '1003', 'product': 'Barley', 'category': 'Cereals', 'gst': 5.0},
      {'hsn': '1004', 'product': 'Oats', 'category': 'Cereals', 'gst': 5.0},
      {'hsn': '1005', 'product': 'Maize (Corn)', 'category': 'Cereals', 'gst': 5.0},
      {'hsn': '1006', 'product': 'Rice', 'category': 'Cereals', 'gst': 5.0},
      {'hsn': '1007', 'product': 'Grain Sorghum', 'category': 'Cereals', 'gst': 5.0},
      {'hsn': '1008', 'product': 'Buckwheat/Millet', 'category': 'Cereals', 'gst': 5.0},
      {'hsn': '0713', 'product': 'Dried Leguminous Vegetables', 'category': 'Pulses', 'gst': 0.0},
      {'hsn': '1201', 'product': 'Soya Beans', 'category': 'Oil Seeds', 'gst': 5.0},
      {'hsn': '1204', 'product': 'Linseed', 'category': 'Oil Seeds', 'gst': 5.0},
      {'hsn': '1205', 'product': 'Rape/Mustard Seeds', 'category': 'Oil Seeds', 'gst': 5.0},
      {'hsn': '1206', 'product': 'Sunflower Seeds', 'category': 'Oil Seeds', 'gst': 5.0},
      {'hsn': '1207', 'product': 'Other Oil Seeds', 'category': 'Oil Seeds', 'gst': 5.0},
      {'hsn': '0904', 'product': 'Pepper', 'category': 'Spices', 'gst': 5.0},
      {'hsn': '0906', 'product': 'Cinnamon', 'category': 'Spices', 'gst': 5.0},
      {'hsn': '0907', 'product': 'Cloves', 'category': 'Spices', 'gst': 5.0},
      {'hsn': '0908', 'product': 'Nutmeg/Cardamom', 'category': 'Spices', 'gst': 5.0},
      {'hsn': '0909', 'product': 'Seeds of Anise/Coriander/Cumin', 'category': 'Spices', 'gst': 5.0},
      {'hsn': '0910', 'product': 'Ginger/Turmeric', 'category': 'Spices', 'gst': 5.0},
      {'hsn': '3102', 'product': 'Urea Fertilizer', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '3103', 'product': 'Phosphatic Fertilizer', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '3104', 'product': 'Potassic Fertilizer', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '3105', 'product': 'NPK Fertilizer', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '3808', 'product': 'Insecticides/Pesticides', 'category': 'Pesticides', 'gst': 18.0},
      {'hsn': '1209', 'product': 'Seeds for Sowing', 'category': 'Seeds', 'gst': 5.0},
    ];

    for (final code in hsnCodes) {
      await db.insert('hsn_codes', {
        'hsn_code': code['hsn'],
        'product_name': code['product'],
        'product_category': code['category'],
        'gst_rate': code['gst'],
      });
    }
  }

  Future<String> insertInvoice(InvoiceModel invoice) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.insert('invoices', invoice.toMap());

      for (final item in invoice.items) {
        await txn.insert('invoice_items', {
          'id': item.id,
          'invoice_id': invoice.id,
          'hsn_code': item.hsnCode,
          'product_name': item.productName,
          'product_category': item.productCategory,
          'quantity': item.quantity,
          'unit': item.unit,
          'rate': item.rate,
          'line_total': item.lineTotal,
          'batch_number': item.batchNumber,
          'expiry_date': item.expiryDate,
          'quality_grade': item.qualityGrade,
          'storage_location': item.storageLocation,
        });
      }
    });

    return invoice.id;
  }

  Future<InvoiceModel?> getInvoice(String id) async {
    final db = await database;

    final invoiceMaps = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (invoiceMaps.isEmpty) return null;

    final itemMaps = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [id],
    );

    return InvoiceModel.fromMap(invoiceMaps.first, itemMaps);
  }

  Future<List<InvoiceModel>> getAllInvoices() async {
    final db = await database;

    final invoiceMaps = await db.query('invoices', orderBy: 'date DESC');

    final invoices = <InvoiceModel>[];
    for (final invoiceMap in invoiceMaps) {
      final itemMaps = await db.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceMap['id']],
      );
      invoices.add(InvoiceModel.fromMap(invoiceMap, itemMaps));
    }

    return invoices;
  }

  Future<int> updateInvoice(InvoiceModel invoice) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.update(
        'invoices',
        invoice.toMap(),
        where: 'id = ?',
        whereArgs: [invoice.id],
      );

      await txn.delete(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoice.id],
      );

      for (final item in invoice.items) {
        await txn.insert('invoice_items', {
          'id': item.id,
          'invoice_id': invoice.id,
          'hsn_code': item.hsnCode,
          'product_name': item.productName,
          'product_category': item.productCategory,
          'quantity': item.quantity,
          'unit': item.unit,
          'rate': item.rate,
          'line_total': item.lineTotal,
          'batch_number': item.batchNumber,
          'expiry_date': item.expiryDate,
          'quality_grade': item.qualityGrade,
          'storage_location': item.storageLocation,
        });
      }
    });

    return 1;
  }

  Future<int> deleteInvoice(String id) async {
    final db = await database;
    return await db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getHSNCodes() async {
    final db = await database;
    return await db.query('hsn_codes', orderBy: 'hsn_code ASC');
  }

  Future<Map<String, dynamic>?> getHSNCodeDetails(String hsnCode) async {
    final db = await database;
    final results = await db.query(
      'hsn_codes',
      where: 'hsn_code = ?',
      whereArgs: [hsnCode],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>> getInvoiceStatistics() async {
    final db = await database;

    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM invoices');
    final sumResult = await db.rawQuery('SELECT SUM(grand_total) as total FROM invoices');

    return {
      'totalInvoices': Sqflite.firstIntValue(countResult) ?? 0,
      'totalAmount': (sumResult.first['total'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
