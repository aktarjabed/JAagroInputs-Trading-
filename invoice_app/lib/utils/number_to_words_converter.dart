// lib/utils/number_to_words_converter.dart

class NumberToWordsConverter {
  static const List<String> _ones = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen'
  ];

  static const List<String> _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

  static String convertToIndianWords(double amount) {
    int rupees = amount.floor();
    int paise = ((amount - rupees) * 100).round();

    String rupeesInWords = _convertNumberToWords(rupees);
    String result = rupeesInWords.isEmpty ? 'Zero Rupees' : 'Rupees $rupeesInWords';

    if (paise > 0) {
      result += ' And ${_convertNumberToWords(paise)} Paisa';
    }

    return '$result Only';
  }

  static String _convertNumberToWords(int number) {
    if (number == 0) return '';
    if (number >= 10000000) {
      return '${_convertNumberToWords(number ~/ 10000000)} Crore ${_convertNumberToWords(number % 10000000)}'.trim();
    }
    if (number >= 100000) {
      return '${_convertNumberToWords(number ~/ 100000)} Lakh ${_convertNumberToWords(number % 100000)}'.trim();
    }
    if (number >= 1000) {
      return '${_convertNumberToWords(number ~/ 1000)} Thousand ${_convertNumberToWords(number % 1000)}'.trim();
    }
    if (number >= 100) {
      return '${_ones[number ~/ 100]} Hundred ${_convertNumberToWords(number % 100)}'.trim();
    }
    if (number >= 20) {
      return '${_tens[number ~/ 10]} ${_ones[number % 10]}'.trim();
    }
    return _ones[number];
  }
}
