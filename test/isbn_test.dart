import 'package:colophon/services/isbn.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isValidIsbn', () {
    test('チェックディジットが正しいISBN-13を受け付ける', () {
      expect(isValidIsbn('9784309226712'), isTrue);
      expect(isValidIsbn('978-4-309-22671-2'), isTrue);
    });

    test('全角数字やハイフン・空白が混ざっていても判定できる', () {
      expect(isValidIsbn('９７８−４−３０９−２２６７１−２'), isTrue);
      expect(isValidIsbn(' 978 4309 226712 '), isTrue);
    });

    test('末尾がXのISBN-10を受け付ける', () {
      expect(isValidIsbn('4-309-22671-X'), isTrue);
      expect(isValidIsbn('430922671x'), isTrue);
    });

    test('チェックディジット違い・桁数違い・空文字は不正', () {
      expect(isValidIsbn('9784309226713'), isFalse);
      expect(isValidIsbn('4062072871'), isFalse);
      expect(isValidIsbn('97843092267'), isFalse);
      expect(isValidIsbn(''), isFalse);
    });
  });

  group('isbnMatchKey', () {
    test('ISBN-10とISBN-13の同じ本は同じキーになる', () {
      expect(isbnMatchKey('4-309-22671-X'), isbnMatchKey('978-4-309-22671-2'));
    });

    test('空・未入力・正しくないISBNはnull（同一書籍の判定に使わない）', () {
      expect(isbnMatchKey(null), isNull);
      expect(isbnMatchKey(' - '), isNull);
      expect(isbnMatchKey('不明'), isNull);
      expect(isbnMatchKey('9784309226713'), isNull);
    });
  });
}
