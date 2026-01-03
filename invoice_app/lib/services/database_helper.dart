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
      // ========================================
      // VEGETABLES (0% GST) - Fresh
      // ========================================
      {'hsn': '0701', 'product': 'Potato (Fresh)', 'category': 'Vegetables', 'gst': 0.0},
      {'hsn': '0702', 'product': 'Tomato (Fresh)', 'category': 'Vegetables', 'gst': 0.0},
      {'hsn': '0703', 'product': 'Onion (Fresh)', 'category': 'Vegetables', 'gst': 0.0},
      {'hsn': '0704', 'product': 'Cabbage/Cauliflower (Fresh)', 'category': 'Vegetables', 'gst': 0.0},
      {'hsn': '0705', 'product': 'Lettuce/Chicory (Fresh)', 'category': 'Vegetables', 'gst': 0.0},
      {'hsn': '0706', 'product': 'Carrot/Turnip (Fresh)', 'category': 'Vegetables', 'gst': 0.0},
      {'hsn': '0707', 'product': 'Cucumber/Gherkin (Fresh)', 'category': 'Vegetables', 'gst': 0.0},
      {'hsn': '0708', 'product': 'Leguminous Vegetables (Fresh)', 'category': 'Vegetables', 'gst': 0.0},
      {'hsn': '0709', 'product': 'Other Vegetables (Fresh)', 'category': 'Vegetables', 'gst': 0.0},
      {'hsn': '0713', 'product': 'Dried Leguminous Vegetables', 'category': 'Pulses', 'gst': 0.0},

      // ========================================
      // CEREALS (5% GST)
      // ========================================
      {'hsn': '1001', 'product': 'Wheat', 'category': 'Cereals', 'gst': 5.0},
      {'hsn': '1002', 'product': 'Rye', 'category': 'Cereals', 'gst': 5.0},
      {'hsn': '1003', 'product': 'Barley', 'category': 'Cereals', 'gst': 5.0},
      {'hsn': '1004', 'product': 'Oats', 'category': 'Cereals', 'gst': 5.0},
      {'hsn': '1005', 'product': 'Maize (Corn)', 'category': 'Cereals', 'gst': 5.0},
      {'hsn': '1006', 'product': 'Rice', 'category': 'Cereals', 'gst': 5.0},
      {'hsn': '1007', 'product': 'Grain Sorghum', 'category': 'Cereals', 'gst': 5.0},
      {'hsn': '1008', 'product': 'Buckwheat/Millet', 'category': 'Cereals', 'gst': 5.0},

      // ========================================
      // OIL SEEDS (5% GST)
      // ========================================
      {'hsn': '1201', 'product': 'Soya Beans', 'category': 'Oil Seeds', 'gst': 5.0},
      {'hsn': '1202', 'product': 'Ground Nuts (Peanuts)', 'category': 'Oil Seeds', 'gst': 5.0},
      {'hsn': '1204', 'product': 'Linseed', 'category': 'Oil Seeds', 'gst': 5.0},
      {'hsn': '1205', 'product': 'Rape/Mustard Seeds', 'category': 'Oil Seeds', 'gst': 5.0},
      {'hsn': '1206', 'product': 'Sunflower Seeds', 'category': 'Oil Seeds', 'gst': 5.0},
      {'hsn': '1207', 'product': 'Other Oil Seeds', 'category': 'Oil Seeds', 'gst': 5.0},

      // ========================================
      // SEEDS FOR SOWING (0% Seed Quality, 5% Commercial)
      // ========================================
      {'hsn': '1209', 'product': 'Seeds for Sowing (General)', 'category': 'Seeds', 'gst': 5.0},
      {'hsn': '120910', 'product': 'Paddy Seeds (Seed Quality)', 'category': 'Seeds', 'gst': 0.0},
      {'hsn': '120920', 'product': 'Wheat Seeds (Seed Quality)', 'category': 'Seeds', 'gst': 0.0},
      {'hsn': '120930', 'product': 'Cotton Seeds (Seed Quality)', 'category': 'Seeds', 'gst': 0.0},
      {'hsn': '120940', 'product': 'Maize Seeds (Seed Quality)', 'category': 'Seeds', 'gst': 0.0},
      {'hsn': '120950', 'product': 'Mustard Seeds (Seed Quality)', 'category': 'Seeds', 'gst': 0.0},
      {'hsn': '120960', 'product': 'Vegetable Seeds (Seed Quality)', 'category': 'Seeds', 'gst': 0.0},
      {'hsn': '120991', 'product': 'Hybrid Seeds (Commercial)', 'category': 'Seeds', 'gst': 5.0},

      // ========================================
      // SPICES (5% GST)
      // ========================================
      {'hsn': '0904', 'product': 'Pepper', 'category': 'Spices', 'gst': 5.0},
      {'hsn': '0906', 'product': 'Cinnamon', 'category': 'Spices', 'gst': 5.0},
      {'hsn': '0907', 'product': 'Cloves', 'category': 'Spices', 'gst': 5.0},
      {'hsn': '0908', 'product': 'Nutmeg/Cardamom', 'category': 'Spices', 'gst': 5.0},
      {'hsn': '0909', 'product': 'Coriander/Cumin/Anise Seeds', 'category': 'Spices', 'gst': 5.0},
      {'hsn': '0910', 'product': 'Ginger/Turmeric', 'category': 'Spices', 'gst': 5.0},

      // ========================================
      // HONEY (0% Unbranded, 5% Branded)
      // ========================================
      {'hsn': '0409', 'product': 'Natural Honey (Unbranded)', 'category': 'Honey', 'gst': 0.0},
      {'hsn': '040900', 'product': 'Natural Honey (Branded)', 'category': 'Honey', 'gst': 5.0},

      // ========================================
      // ORGANIC FERTILIZERS (0% Organic, 5% Others) - HSN 3101
      // ========================================
      {'hsn': '3101', 'product': 'Animal/Vegetable Fertilizers', 'category': 'Organic Fertilizers', 'gst': 5.0},
      {'hsn': '310100', 'product': 'Vermicompost (Organic)', 'category': 'Organic Fertilizers', 'gst': 0.0},
      {'hsn': '310110', 'product': 'FYM (Farmyard Manure)', 'category': 'Organic Fertilizers', 'gst': 0.0},
      {'hsn': '310120', 'product': 'Poultry Manure', 'category': 'Organic Fertilizers', 'gst': 5.0},
      {'hsn': '310130', 'product': 'Neem Cake', 'category': 'Organic Fertilizers', 'gst': 5.0},
      {'hsn': '310140', 'product': 'Bone Meal', 'category': 'Organic Fertilizers', 'gst': 5.0},

      // ========================================
      // CHEMICAL FERTILIZERS - NITROGENOUS (5% GST) - HSN 3102
      // ========================================
      {'hsn': '3102', 'product': 'Nitrogenous Fertilizers', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310210', 'product': 'Urea (Granular)', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310220', 'product': 'Ammonium Sulphate', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310230', 'product': 'Ammonium Nitrate', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310240', 'product': 'CAN (Calcium Ammonium Nitrate)', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310250', 'product': 'Sodium Nitrate', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310260', 'product': 'Calcium Nitrate', 'category': 'Fertilizers', 'gst': 5.0},

      // ========================================
      // CHEMICAL FERTILIZERS - PHOSPHATIC (5% GST) - HSN 3103
      // ========================================
      {'hsn': '3103', 'product': 'Phosphatic Fertilizers', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310310', 'product': 'SSP (Single Super Phosphate)', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310320', 'product': 'TSP (Triple Super Phosphate)', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310330', 'product': 'Rock Phosphate', 'category': 'Fertilizers', 'gst': 5.0},

      // ========================================
      // CHEMICAL FERTILIZERS - POTASSIC (5% GST) - HSN 3104
      // ========================================
      {'hsn': '3104', 'product': 'Potassic Fertilizers', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310410', 'product': 'MOP (Muriate of Potash)', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310420', 'product': 'SOP (Sulphate of Potash)', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310430', 'product': 'Potassium Sulphate', 'category': 'Fertilizers', 'gst': 5.0},

      // ========================================
      // NPK FERTILIZERS (5% GST) - HSN 3105
      // ========================================
      {'hsn': '3105', 'product': 'NPK Fertilizers (Mixed)', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310510', 'product': 'NPK 10-26-26', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310520', 'product': 'NPK 12-32-16', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310530', 'product': 'NPK 19-19-19', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310540', 'product': 'DAP (Diammonium Phosphate)', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310550', 'product': 'MAP (Monoammonium Phosphate)', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310560', 'product': 'Sulphur Coated Urea', 'category': 'Fertilizers', 'gst': 5.0},
      {'hsn': '310570', 'product': 'Ammonium Phosphate', 'category': 'Fertilizers', 'gst': 5.0},

      // ========================================
      // MICRONUTRIENTS (5-12% GST) - HSN 2833, 3105
      // ========================================
      {'hsn': '2833', 'product': 'Zinc Sulphate (Micronutrient)', 'category': 'Micronutrients', 'gst': 12.0},
      {'hsn': '283329', 'product': 'Zinc Sulphate Monohydrate', 'category': 'Micronutrients', 'gst': 12.0},
      {'hsn': '283330', 'product': 'Ferrous Sulphate', 'category': 'Micronutrients', 'gst': 12.0},
      {'hsn': '283340', 'product': 'Magnesium Sulphate', 'category': 'Micronutrients', 'gst': 12.0},
      {'hsn': '310580', 'product': 'Boron Fertilizer', 'category': 'Micronutrients', 'gst': 5.0},
      {'hsn': '310590', 'product': 'Chelated Micronutrients', 'category': 'Micronutrients', 'gst': 5.0},

      // ========================================
      // PESTICIDES/INSECTICIDES (18% GST) - HSN 3808
      // ========================================
      {'hsn': '3808', 'product': 'Insecticides/Pesticides', 'category': 'Pesticides', 'gst': 18.0},
      {'hsn': '380810', 'product': 'Insecticides (Retail Pack)', 'category': 'Pesticides', 'gst': 18.0},
      {'hsn': '380820', 'product': 'Fungicides', 'category': 'Pesticides', 'gst': 18.0},
      {'hsn': '380830', 'product': 'Herbicides/Weedicides', 'category': 'Pesticides', 'gst': 18.0},
      {'hsn': '380840', 'product': 'Rodenticides', 'category': 'Pesticides', 'gst': 18.0},
      {'hsn': '380891', 'product': 'Plant Growth Regulators', 'category': 'Pesticides', 'gst': 18.0},
      {'hsn': '380892', 'product': 'Bio-Pesticides', 'category': 'Pesticides', 'gst': 5.0},
      {'hsn': '380893', 'product': 'Neem-based Pesticides', 'category': 'Pesticides', 'gst': 5.0},

      // ========================================
      // ADDITIONAL AGRO PRODUCTS
      // ========================================
      {'hsn': '2309', 'product': 'Animal Feed/Cattle Feed', 'category': 'Animal Feed', 'gst': 5.0},
      {'hsn': '3824', 'product': 'Bio-Fertilizers/Biostimulants', 'category': 'Bio Products', 'gst': 5.0},
      {'hsn': '3926', 'product': 'Plastic Mulch Film', 'category': 'Agro Accessories', 'gst': 18.0},
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
