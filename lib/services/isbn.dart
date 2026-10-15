import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// 全角を半角にそろえ、ハイフン類・空白を除き、末尾の x を大文字にした ISBN を返す。
String normalizeIsbn(String input) =>
    unorm.nfkc(input).replaceAll(RegExp(r'[\s\-‐‑–—―−ー]'), '').toUpperCase();

/// ISBN-10 / ISBN-13 としてチェックディジットまで正しいか。
bool isValidIsbn(String input) {
  final s = normalizeIsbn(input);
  if (RegExp(r'^\d{9}[\dX]$').hasMatch(s)) {
    var sum = 0;
    for (var i = 0; i < 10; i++) {
      final v = s[i] == 'X' ? 10 : int.parse(s[i]);
      sum += v * (10 - i);
    }
    return sum % 11 == 0;
  }
  if (RegExp(r'^\d{13}$').hasMatch(s)) {
    var sum = 0;
    for (var i = 0; i < 13; i++) {
      sum += int.parse(s[i]) * (i.isEven ? 1 : 3);
    }
    return sum % 10 == 0;
  }
  return false;
}

/// 同一書籍の判定用キー。ISBN-10 は ISBN-13 に変換してそろえる。
/// 正しい ISBN でなければ null（「不明」などの自由入力どうしを同一書籍とみなさないため）。
String? isbnMatchKey(String? input) {
  if (input == null || !isValidIsbn(input)) return null;
  final s = normalizeIsbn(input);
  return s.length == 10 ? _isbn10To13(s) : s;
}

String _isbn10To13(String isbn10) {
  final body = '978${isbn10.substring(0, 9)}';
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    sum += int.parse(body[i]) * (i.isEven ? 1 : 3);
  }
  return '$body${(10 - sum % 10) % 10}';
}
