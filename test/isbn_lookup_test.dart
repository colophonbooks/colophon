import 'dart:convert';

import 'package:colophon/services/isbn_lookup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// 以下のテスト用データは、各サービスの実際の応答（2026-10 取得）から必要部分を抜粋したもの。

/// 国立国会図書館サーチ OpenSearch
const _ndlSapiens = '''
<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcndl="http://ndl.go.jp/dcndl/terms/" xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/" version="2.0">
  <channel>
    <title>9784309226712 - 国立国会図書館サーチ OpenSearch</title>
    <openSearch:totalResults>1</openSearch:totalResults>
    <item>
      <title>サピエンス全史 : 文明の構造と人類の幸福</title>
      <description><![CDATA[<p>上,河出書房新社,2016,978-4-309-22671-2<p><ul><li>タイトル：サピエンス全史 : 文明の構造と人類の幸福</li><li>責任表示：ユヴァル・ノア・ハラリ 著,柴田裕之 訳</li><li>NDC(9)：209</li></ul>]]></description>
      <dc:title>サピエンス全史 : 文明の構造と人類の幸福</dc:title>
      <dc:creator>Harari, Yuval N., 1976-</dc:creator>
      <dc:creator>柴田, 裕之, 1959-</dc:creator>
      <dcndl:volume>上</dcndl:volume>
      <dc:publisher>河出書房新社</dc:publisher>
    </item>
  </channel>
</rss>
''';

const _ndlEmpty = '''
<rss xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/" version="2.0">
  <channel><openSearch:totalResults>0</openSearch:totalResults></channel>
</rss>
''';

/// Open Library（ISBN 9780131455276）
const _openLibrary = '''
{"ISBN:9780131455276": {"title": "Art history", "authors": [{"name": "Marilyn Stokstad"},
 {"name": "Margaret A. Oppenheimer"}], "publishers": [{"name": "Pearson/Prentice Hall"}]}}
''';

/// 米国議会図書館 SRU（Dublin Core。要素に接頭辞がない）
const _loc = '''
<zs:searchRetrieveResponse xmlns:zs="http://www.loc.gov/zing/srw/"><zs:version>1.1</zs:version><zs:numberOfRecords>1</zs:numberOfRecords><zs:records><zs:record><zs:recordSchema>dc</zs:recordSchema><zs:recordData><srw_dc:dc xmlns:srw_dc="info:srw/schema/1/dc-schema">
  <title xmlns="http://purl.org/dc/elements/1.1/">Art history /</title>
  <creator xmlns="http://purl.org/dc/elements/1.1/">Stokstad, Marilyn, 1929-2016.</creator>
  <creator xmlns="http://purl.org/dc/elements/1.1/">Cateforis, David.</creator>
  <publisher xmlns="http://purl.org/dc/elements/1.1/">Upper Saddle River, NJ : Pearson/Prentice Hall,</publisher>
  <date xmlns="http://purl.org/dc/elements/1.1/">c2005.</date>
</srw_dc:dc></zs:recordData></zs:record></zs:records></zs:searchRetrieveResponse>
''';

const _locEmpty = '''
<zs:searchRetrieveResponse xmlns:zs="http://www.loc.gov/zing/srw/"><zs:version>1.1</zs:version><zs:numberOfRecords>0</zs:numberOfRecords></zs:searchRetrieveResponse>
''';

/// フランス国立図書館 SRU（翻訳者の行はテスト用に追加）
const _bnf = '''
<srw:searchRetrieveResponse xmlns:srw="http://www.loc.gov/zing/srw/"><srw:version>1.2</srw:version><srw:numberOfRecords>1</srw:numberOfRecords><srw:records><srw:record><srw:recordSchema>dc</srw:recordSchema><srw:recordData><oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <dc:identifier>http://catalogue.bnf.fr/ark:/12148/cb47345021z</dc:identifier>
  <dc:title>Jaune : histoire d'une couleur / Michel Pastoureau</dc:title>
  <dc:creator>Pastoureau, Michel (1947-....). Auteur du texte</dc:creator>
  <dc:contributor>Dupont, Marie. Traducteur</dc:contributor>
  <dc:publisher>Points (Paris)</dc:publisher>
  <dc:date>2023</dc:date>
</oai_dc:dc></srw:recordData></srw:record></srw:records></srw:searchRetrieveResponse>
''';

/// ドイツ国立図書館 SRU（翻訳者の行はテスト用に追加）
const _dnb = '''
<searchRetrieveResponse xmlns="http://www.loc.gov/zing/srw/"><version>1.1</version><numberOfRecords>1</numberOfRecords><records><record><recordSchema>oai_dc</recordSchema><recordPacking>xml</recordPacking><recordData><dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns="http://www.openarchives.org/OAI/2.0/oai_dc/">
  <dc:title>0 1 2 : Roman - (Null Eins Zwei) / Daniel Wisser</dc:title>
  <dc:creator>Wisser, Daniel [Verfasser]</dc:creator>
  <dc:creator>Fischer, Anna [Übersetzer]</dc:creator>
  <dc:publisher>München : Luchterhand Literaturverlag</dc:publisher>
</dc></recordData></record></records></searchRetrieveResponse>
''';

void main() {
  group('問い合わせる順番（sourcesForIsbn）', () {
    test('ISBN の国・言語の番号で、その国の国立図書館を先にする', () {
      expect(sourcesForIsbn('978-4-309-22671-2'), [LookupSource.ndl, LookupSource.openLibrary]);
      expect(sourcesForIsbn('9782757899410'), [LookupSource.bnf, LookupSource.openLibrary]);
      expect(sourcesForIsbn('979-10-12345-67-6'), [LookupSource.bnf, LookupSource.openLibrary]);
      expect(sourcesForIsbn('9783641294366'), [LookupSource.dnb, LookupSource.openLibrary]);
      expect(sourcesForIsbn('9780131455276'), [LookupSource.openLibrary, LookupSource.loc]);
      expect(sourcesForIsbn('9781587657672'), [LookupSource.openLibrary, LookupSource.loc]);
    });

    test('それ以外（韓国・中国など）は国立国会図書館 → Open Library → 米国議会図書館', () {
      const others = [LookupSource.ndl, LookupSource.openLibrary, LookupSource.loc];
      expect(sourcesForIsbn('9791186351017'), others);
      expect(sourcesForIsbn('9787544861298'), others);
      expect(sourcesForIsbn('9788937460449'), others);
    });

    test('ISBN-10 は ISBN-13 に直してから振り分ける', () {
      expect(sourcesForIsbn('4-309-22671-X'), [LookupSource.ndl, LookupSource.openLibrary]);
      expect(sourcesForIsbn('0131455273'), [LookupSource.openLibrary, LookupSource.loc]);
    });
  });

  group('parseNdlResponse', () {
    test('書名に巻次を付け、責任表示から著者と翻訳者を振り分ける', () {
      final r = parseNdlResponse(_ndlSapiens)!;
      expect(r.source, LookupSource.ndl);
      expect(r.title, 'サピエンス全史 : 文明の構造と人類の幸福 上');
      expect(r.author, 'ユヴァル・ノア・ハラリ');
      expect(r.translator, '柴田裕之');
      expect(r.supervisor, isNull);
      expect(r.publisher, '河出書房新社');
    });

    test('該当なしなら null', () {
      expect(parseNdlResponse(_ndlEmpty), isNull);
    });

    test('外国語資料の書名に付く言語の注記（「 : [中国語]」）を除く', () {
      final xml = _ndlSapiens
          .replaceAll('サピエンス全史 : 文明の構造と人類の幸福', '異境的迷夢深淵 : [中国語]')
          .replaceAll('<dcndl:volume>上</dcndl:volume>', '');
      expect(parseNdlResponse(xml)!.title, '異境的迷夢深淵');
    });
  });

  group('parseResponsibility', () {
    test('役割語のない名前は直後の役割語に含める', () {
      final r = parseResponsibility('山田太郎, 鈴木花子 著 ; 佐藤一郎 監修 ; 田中次郎 訳');
      expect(r.authors, ['山田太郎', '鈴木花子']);
      expect(r.supervisors, ['佐藤一郎']);
      expect(r.translators, ['田中次郎']);
    });

    test('括弧付きの役割語や監訳を判別する', () {
      final r = parseResponsibility('夏目漱石 [著],高橋一郎 監訳');
      expect(r.authors, ['夏目漱石']);
      expect(r.supervisors, ['高橋一郎']);
    });

    test('名前の末尾が役割語と同じ字でも、空白がなければ役割とみなさない', () {
      final r = parseResponsibility('山田文');
      expect(r.authors, ['山田文']);
    });

    test('解説者は著者に含めない', () {
      final r = parseResponsibility('太宰治 著,奥野健男 解説');
      expect(r.authors, ['太宰治']);
    });
  });

  group('parseOpenLibraryResponse', () {
    test('書名・著者・出版社を取り出す', () {
      final r = parseOpenLibraryResponse(_openLibrary, '9780131455276')!;
      expect(r.source, LookupSource.openLibrary);
      expect(r.title, 'Art history');
      expect(r.author, 'Marilyn Stokstad, Margaret A. Oppenheimer');
      expect(r.publisher, 'Pearson/Prentice Hall');
    });

    test('副題は書名に含め、該当なし（空のオブジェクト）は null', () {
      final r = parseOpenLibraryResponse('{"ISBN:1": {"title": "Dune", "subtitle": "Deluxe Edition"}}', '1')!;
      expect(r.title, 'Dune: Deluxe Edition');
      expect(parseOpenLibraryResponse('{}', '9780131455276'), isNull);
    });
  });

  group('parseDublinCoreResponse', () {
    test('米国議会図書館: 書名の区切り記号・生没年・出版地を除き、名前を「名 姓」にする', () {
      final r = parseDublinCoreResponse(_loc, LookupSource.loc)!;
      expect(r.source, LookupSource.loc);
      expect(r.title, 'Art history');
      expect(r.author, 'Marilyn Stokstad, David Cateforis');
      expect(r.publisher, 'Pearson/Prentice Hall');
      expect(parseDublinCoreResponse(_locEmpty, LookupSource.loc), isNull);
    });

    test('フランス国立図書館: 書名の責任表示と出版地を除き、翻訳者を振り分ける', () {
      final r = parseDublinCoreResponse(_bnf, LookupSource.bnf)!;
      expect(r.title, "Jaune : histoire d'une couleur");
      expect(r.author, 'Michel Pastoureau');
      expect(r.translator, 'Marie Dupont');
      expect(r.publisher, 'Points');
    });

    test('ドイツ国立図書館: 角括弧の役割で著者と翻訳者を振り分ける', () {
      final r = parseDublinCoreResponse(_dnb, LookupSource.dnb)!;
      expect(r.title, '0 1 2 : Roman - (Null Eins Zwei)');
      expect(r.author, 'Daniel Wisser');
      expect(r.translator, 'Anna Fischer');
      expect(r.publisher, 'Luchterhand Literaturverlag');
    });
  });

  group('parseCatalogCreator', () {
    test('米国議会図書館の役割語とイニシャル', () {
      expect(parseCatalogCreator('Harari, Yuval N., author.', LookupSource.loc),
          (name: 'Yuval N. Harari', role: CreatorRole.author));
      expect(parseCatalogCreator('Smith, Jane, translator.', LookupSource.loc),
          (name: 'Jane Smith', role: CreatorRole.translator));
      expect(parseCatalogCreator('Reisman, Rosemary M. Canfield.', LookupSource.loc),
          (name: 'Rosemary M. Canfield Reisman', role: CreatorRole.author));
    });

    test('フランス国立図書館: 名前の中のピリオドを役割の区切りと取り違えない', () {
      expect(parseCatalogCreator('Tolkien, J. R. R. (1892-1973). Auteur du texte', LookupSource.bnf),
          (name: 'J. R. R. Tolkien', role: CreatorRole.author));
      expect(parseCatalogCreator('Healthy Alie. Auteur du texte', LookupSource.bnf),
          (name: 'Healthy Alie', role: CreatorRole.author));
    });

    test('挿絵などの役割は「その他」にする（著者がいなければ著者として使う）', () {
      expect(parseCatalogCreator('Martin, Paul [Illustrator]', LookupSource.dnb).role, CreatorRole.other);
    });
  });

  group('IsbnLookupService', () {
    http.Response ok(String body) => http.Response.bytes(utf8.encode(body), 200);

    test('フランスの ISBN はフランス国立図書館に問い合わせ、見つかればそこで終える', () async {
      final hosts = <String>[];
      final service = IsbnLookupService(client: MockClient((req) async {
        hosts.add(req.url.host);
        return ok(_bnf);
      }));
      final r = await service.lookup('978-2-7578-9941-0');
      expect(r!.source, LookupSource.bnf);
      expect(hosts, ['catalogue.bnf.fr']);
    });

    test('最初の取得元で見つからなければ次へ進む（英語: Open Library → 米国議会図書館）', () async {
      final hosts = <String>[];
      final service = IsbnLookupService(client: MockClient((req) async {
        hosts.add(req.url.host);
        if (req.url.host == 'openlibrary.org') return ok('{}');
        expect(req.url.queryParameters['query'], 'bath.isbn=9780131455276');
        return ok(_loc);
      }));
      expect((await service.lookup('9780131455276'))!.source, LookupSource.loc);
      expect(hosts, ['openlibrary.org', 'lx2.loc.gov']);
    });

    test('通信エラーの取得元は飛ばして次へ進む', () async {
      final service = IsbnLookupService(client: MockClient((req) async {
        if (req.url.host == 'ndlsearch.ndl.go.jp') throw http.ClientException('offline');
        return ok(_openLibrary.replaceFirst('9780131455276', '9784309226712'));
      }));
      expect((await service.lookup('9784309226712'))!.source, LookupSource.openLibrary);
    });

    test('どこにもなければ null', () async {
      final service = IsbnLookupService(client: MockClient((req) async {
        if (req.url.host == 'ndlsearch.ndl.go.jp') return ok(_ndlEmpty);
        return ok('{}');
      }));
      expect(await service.lookup('9784309226712'), isNull);
    });

    test('見つからず、途中に通信エラーの取得元があれば「見つからない」ではなく LookupException', () async {
      final service = IsbnLookupService(client: MockClient((req) async {
        if (req.url.host == 'ndlsearch.ndl.go.jp') return http.Response('', 429);
        if (req.url.host == 'openlibrary.org') return ok('{}');
        return ok(_locEmpty);
      }));
      expect(service.lookup('9791186351017'), throwsA(isA<LookupException>()));
    });

    test('すべての取得元が通信エラーなら LookupException', () async {
      final service = IsbnLookupService(client: MockClient((_) async => http.Response('', 503)));
      expect(service.lookup('9784309226712'), throwsA(isA<LookupException>()));
    });

    test('Open Library が求めるとおり、アプリ名と連絡先を User-Agent で名乗る', () async {
      String? ua;
      final service = IsbnLookupService(client: MockClient((req) async {
        ua = req.headers['User-Agent'];
        return ok(_openLibrary);
      }));
      await service.lookup('9780131455276');
      expect(ua, contains('Colophon'));
      expect(ua, contains('https://github.com/colophonbooks'));
    });
  });
}
