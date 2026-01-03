import '../models/company_settings_model.dart';
import '../utils/constants.dart';
import 'database_helper.dart';

class SettingsService {
  final _db = InvoiceDatabase.instance;

  Future<CompanySettingsModel> getSettings() async {
    final db = await _db.database;
    final result = await db.query('company_settings');

    if (result.isNotEmpty) {
      return CompanySettingsModel.fromMap(result.first);
    } else {
      // Return default settings from Constants if not found in DB
      return CompanySettingsModel(
        companyName: Constants.companyName,
        gstin: Constants.companyGSTIN,
        pan: Constants.companyPAN,
        address: Constants.companyAddress,
        city: Constants.companyCity,
        state: Constants.companyState,
        pincode: Constants.companyPincode,
        phone: Constants.companyPhone,
        email: Constants.companyEmail,
        bankName: Constants.bankName,
        bankAccountNumber: Constants.bankAccountNumber,
        bankIFSC: Constants.bankIFSC,
      );
    }
  }

  Future<int> saveSettings(CompanySettingsModel settings) async {
    final db = await _db.database;
    final result = await db.query('company_settings');

    if (result.isEmpty) {
      return await db.insert('company_settings', settings.toMap()..remove('id'));
    } else {
      return await db.update(
        'company_settings',
        settings.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [result.first['id']],
      );
    }
  }
}
