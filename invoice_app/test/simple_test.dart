// invoice_app/test/simple_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_agro_invoice/utils/number_to_words_converter.dart';

void main() {
  test('NumberToWordsConverter converts correctly', () {
    expect(
        NumberToWordsConverter.convertToIndianWords(150005.00),
        'Rupees One Lakh Fifty Thousand Five Only');
    expect(
        NumberToWordsConverter.convertToIndianWords(75650.00),
        'Rupees Seventy Five Thousand Six Hundred Fifty Only');
    expect(
        NumberToWordsConverter.convertToIndianWords(65100.50),
        'Rupees Sixty Five Thousand One Hundred And Fifty Paisa Only');
  });
}
