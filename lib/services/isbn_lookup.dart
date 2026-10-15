import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'isbn.dart';

/// 書誌情報の取得元。いずれも登録不要の公開 API。
enum LookupSource { ndl, openLibrary, loc, bnf, dnb }

class LookupResult {
  const LookupResult({
    required this.source,
    this.title,
    this.author,
    this.translator,
    this.supervisor,
    this.publisher,
    this.edition,
  });

  final LookupSource source;
  final String? title;
  final String? author;
  final String? translator;
  final String? supervisor;
  final String? publisher;
  final String? edition;
}

/// 通信エラーや応答異常（見つからなかった場合は含まない）。
class LookupException implements Exception {
  LookupException(this.cause);
  final Object cause;
}

/// ISBN の国・言語の番号から、問い合わせる順番を決める。
///
/// 各国の本はその国の国立図書館の収録が厚いため、まずそこへ問い合わせる
/// （2026-10 に6言語150冊で測定した取得率に基づく）。
List<LookupSource> sourcesForIsbn(String isbn) {
  final s = isbnMatchKey(isbn) ?? normalizeIsbn(isbn);
  bool group(List<String> prefixes) => prefixes.any(s.startsWith);
  if (group(['9784'])) return const [LookupSource.ndl, LookupSource.openLibrary];
  if (group(['9782', '97910'])) return const [LookupSource.bnf, LookupSource.openLibrary];
  if (group(['9783'])) return const [LookupSource.dnb, LookupSource.openLibrary];
  if (group(['9780', '9781'])) return const [LookupSource.openLibrary, LookupSource.loc];
  return const [LookupSource.ndl, LookupSource.openLibrary, LookupSource.loc];
}

/// ISBN から書誌情報を取得する。[sourcesForIsbn] の順に問い合わせ、最初に見つかった結果を返す。
class IsbnLookupService {
  IsbnLookupService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  /// 国立国会図書館は混雑時に応答が数秒かかるため長めにする。
  static Duration _timeoutFor(LookupSource source) =>
      source == LookupSource.ndl ? const Duration(seconds: 15) : const Duration(seconds: 10);

  /// Open Library はアプリ名と連絡先の明示を求めている。
  static const _headers = {'User-Agent': 'Colophon (https://github.com/colophonbooks)'};

  /// どの取得元でも見つからなければ null。
  /// 見つからず、途中に通信エラーの取得元があれば [LookupException]（その取得元に本があった
  /// かもしれないので「見つからない」とは言い切らない）。
  Future<LookupResult?> lookup(String isbn) async {
    final code = isbnMatchKey(isbn) ?? normalizeIsbn(isbn);
    Object? lastError;
    for (final source in sourcesForIsbn(code)) {
      try {
        final result = await _fetch(source, code);
        if (result != null) return result;
      } catch (e) {
        lastError = e;
      }
    }
    if (lastError != null) throw LookupException(lastError);
    return null;
  }

  Future<LookupResult?> _fetch(LookupSource source, String isbn) async {
    final uri = requestUri(source, isbn);
    final res = await _client.get(uri, headers: _headers).timeout(_timeoutFor(source));
    if (res.statusCode != 200) throw http.ClientException('HTTP ${res.statusCode}', uri);
    final body = utf8.decode(res.bodyBytes);
    return switch (source) {
      LookupSource.ndl => parseNdlResponse(body),
      LookupSource.openLibrary => parseOpenLibraryResponse(body, isbn),
      LookupSource.loc => parseDublinCoreResponse(body, LookupSource.loc),
      LookupSource.bnf => parseDublinCoreResponse(body, LookupSource.bnf),
      LookupSource.dnb => parseDublinCoreResponse(body, LookupSource.dnb),
    };
  }

  void close() => _client.close();
}

/// 各取得元への要求 URL。
Uri requestUri(LookupSource source, String isbn) => switch (source) {
      LookupSource.ndl => Uri.https('ndlsearch.ndl.go.jp', '/api/opensearch', {'isbn': isbn}),
      LookupSource.openLibrary => Uri.https('openlibrary.org', '/api/books',
          {'bibkeys': 'ISBN:$isbn', 'format': 'json', 'jscmd': 'data'}),
      LookupSource.loc => Uri.https('lx2.loc.gov', '/sru/lcdb', {
          'version': '1.1',
          'operation': 'searchRetrieve',
          'query': 'bath.isbn=$isbn',
          'maximumRecords': '1',
          'recordSchema': 'dc',
        }),
      LookupSource.bnf => Uri.https('catalogue.bnf.fr', '/api/SRU', {
          'version': '1.2',
          'operation': 'searchRetrieve',
          'query': 'bib.isbn all "$isbn"',
          'recordSchema': 'dublincore',
          'maximumRecords': '1',
        }),
      LookupSource.dnb => Uri.https('services.dnb.de', '/sru/dnb', {
          'version': '1.1',
          'operation': 'searchRetrieve',
          'query': 'num=$isbn',
          'recordSchema': 'oai_dc',
          'maximumRecords': '1',
        }),
    };

// ---------------------------------------------------------------------------
// 国立国会図書館サーチ（OpenSearch / RSS）
// ---------------------------------------------------------------------------

LookupResult? parseNdlResponse(String xmlText) {
  final doc = XmlDocument.parse(xmlText);
  final item = doc.findAllElements('item').firstOrNull;
  if (item == null) return null;

  String? text(String qualifiedName) {
    final v = item.findElements(qualifiedName).firstOrNull?.innerText.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  // 外国語の資料には「 : [中国語]」のような言語の注記が付くので除く
  var title = (text('dc:title') ?? text('title'))?.replaceAll(RegExp(r'\s*:\s*\[[^\]]+語\]\s*$'), '');
  final volume = text('dcndl:volume');
  if (title != null && volume != null) title = '$title $volume';

  // 「責任表示：ユヴァル・ノア・ハラリ 著,柴田裕之 訳」から役割ごとに振り分ける
  final description = text('description') ?? '';
  final statement =
      RegExp(r'責任表示：(.*?)(?:</li>|$)', multiLine: true).firstMatch(description)?.group(1);
  var roles = statement == null ? null : parseResponsibility(statement);
  if (roles == null || roles.isEmpty) {
    final creators = item
        .findElements('dc:creator')
        .map((e) => _stripLifeDates(e.innerText))
        .where((s) => s.isNotEmpty)
        .toList();
    roles = Responsibility(authors: creators);
  }

  return LookupResult(
    source: LookupSource.ndl,
    title: title,
    author: _joinNames(roles.authors, '、'),
    translator: _joinNames(roles.translators, '、'),
    supervisor: _joinNames(roles.supervisors, '、'),
    publisher: text('dc:publisher'),
    edition: text('dcndl:edition'),
  );
}

class Responsibility {
  const Responsibility({
    this.authors = const [],
    this.translators = const [],
    this.supervisors = const [],
  });

  final List<String> authors;
  final List<String> translators;
  final List<String> supervisors;

  bool get isEmpty => authors.isEmpty && translators.isEmpty && supervisors.isEmpty;
}

const _translatorRoles = {'訳', '翻訳', '共訳', '編訳', '訳・解説', '訳・注'};
const _supervisorRoles = {'監修', '監訳'};
const _ignoredRoles = {'解説', '注', '校注', '装丁', '装画', 'イラスト'};

/// 責任表示（例「山田太郎, 鈴木花子 著 ; 佐藤一郎 訳」）を役割ごとの名前に分ける。
/// 役割語のない名前は、直後に現れる役割語の対象とみなす。
Responsibility parseResponsibility(String statement) {
  final authors = <String>[];
  final translators = <String>[];
  final supervisors = <String>[];
  final pending = <String>[];
  // 役割語の前には空白か括弧を必須にする（「山田文」のように名前の末尾が役割語と同じ字の場合の誤判定防止）
  final rolePattern = RegExp(
      r'^(.*?)(?:\s+|\s*[\[［(（])(訳・解説|訳・注|編著|著者|原作|原著|共訳|編訳|監修|監訳|翻訳|解説|校注|装丁|装画|イラスト|著|作|文|絵|編|訳|注)[\]］)）]?$');

  for (final raw in statement.split(RegExp(r'[,，;；]'))) {
    final part = raw.trim();
    if (part.isEmpty) continue;
    final m = rolePattern.firstMatch(part);
    if (m == null) {
      pending.add(part);
      continue;
    }
    final name = m.group(1)!.trim();
    final role = m.group(2)!;
    final names = [...pending, if (name.isNotEmpty) name];
    pending.clear();
    if (_translatorRoles.contains(role)) {
      translators.addAll(names);
    } else if (_supervisorRoles.contains(role)) {
      supervisors.addAll(names);
    } else if (!_ignoredRoles.contains(role)) {
      authors.addAll(names);
    }
  }
  authors.addAll(pending);
  return Responsibility(authors: authors, translators: translators, supervisors: supervisors);
}

/// 「柴田, 裕之, 1959-」のような典拠形の生没年を除く。
String _stripLifeDates(String s) =>
    s.replaceAll(RegExp(r',\s*\d{3,4}-(\d{3,4})?\s*$'), '').trim();

// ---------------------------------------------------------------------------
// Open Library（JSON）
// ---------------------------------------------------------------------------

LookupResult? parseOpenLibraryResponse(String jsonText, String isbn) {
  final data = jsonDecode(jsonText);
  if (data is! Map) return null;
  final book = data['ISBN:$isbn'];
  if (book is! Map) return null;
  final title = _nonEmpty(book['title'] as String?);
  if (title == null) return null;
  final subtitle = _nonEmpty(book['subtitle'] as String?);
  List<String> names(Object? list) => [
        if (list is List)
          for (final e in list)
            if (e is Map && _nonEmpty(e['name'] as String?) != null) (e['name'] as String).trim(),
      ];
  return LookupResult(
    source: LookupSource.openLibrary,
    title: subtitle == null ? title : '$title: $subtitle',
    author: _joinNames(names(book['authors']), ', '),
    publisher: names(book['publishers']).firstOrNull,
  );
}

// ---------------------------------------------------------------------------
// 米国議会図書館・フランス国立図書館・ドイツ国立図書館（SRU / Dublin Core）
// ---------------------------------------------------------------------------

const _dcNamespace = 'http://purl.org/dc/elements/1.1/';

/// SRU の応答（Dublin Core 形式）の最初のレコードを解析する。
/// 3館とも同じ Dublin Core の要素名だが、書名・著者・出版社の書き方が館ごとに違うので整える。
LookupResult? parseDublinCoreResponse(String xmlText, LookupSource source) {
  final doc = XmlDocument.parse(xmlText);
  final record = doc.descendants
      .whereType<XmlElement>()
      .where((e) => e.localName == 'recordData')
      .firstOrNull;
  if (record == null) return null;

  List<String> values(String name) => [
        for (final e in record.descendants.whereType<XmlElement>())
          if (e.localName == name && e.namespaceUri == _dcNamespace && e.innerText.trim().isNotEmpty)
            e.innerText.trim(),
      ];

  final title = values('title').map(cleanCatalogTitle).firstOrNull;
  if (title == null || title.isEmpty) return null;

  final authors = <String>[];
  final translators = <String>[];
  final others = <String>[];
  for (final raw in [...values('creator'), ...values('contributor')]) {
    final c = parseCatalogCreator(raw, source);
    switch (c.role) {
      case CreatorRole.author:
        authors.add(c.name);
      case CreatorRole.translator:
        translators.add(c.name);
      case CreatorRole.other:
        others.add(c.name);
    }
  }

  return LookupResult(
    source: source,
    title: title,
    // 著者の記載がなく、挿絵などの役割だけがある本（絵本など）は、その人を著者として扱う
    author: _joinNames(authors.isEmpty ? others : authors, ', '),
    translator: _joinNames(translators, ', '),
    publisher: values('publisher').map((p) => cleanCatalogPublisher(p, source)).firstOrNull,
  );
}

/// 目録の書名から、後ろに付く責任表示（「 / 著者名」）と区切り記号を除く。
String cleanCatalogTitle(String raw) {
  var t = raw;
  final slash = t.indexOf(' / ');
  if (slash >= 0) t = t.substring(0, slash);
  return t.replaceAll(RegExp(r'[\s/:;,.]+$'), '').trim();
}

/// 目録の出版者表示から、出版地などを除いた出版社名を取り出す。
/// 例: 「Points (Paris)」「München : Luchterhand」「Pasadena, Calif. : Salem Press,」
String cleanCatalogPublisher(String raw, LookupSource source) {
  var p = raw.trim();
  if (source == LookupSource.bnf) {
    p = p.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '');
  } else {
    final colon = p.lastIndexOf(' : ');
    if (colon >= 0) p = p.substring(colon + 3);
  }
  return p.replaceAll(RegExp(r'[\s,;:.]+$'), '').trim();
}

enum CreatorRole { author, translator, other }

/// 末尾のピリオド。ただしイニシャル（「Yuval N.」の「N.」）の点は残す。
final _trailingPeriod = RegExp(r'(?<!(?:^|[\s\-])\p{Lu})\.$', unicode: true);

const _catalogTranslatorRoles = {'traducteur', 'traductrice', 'übersetzer', 'übersetzerin', 'translator'};
const _catalogAuthorRoles = {
  'auteur du texte', 'auteur', 'verfasser', 'verfasserin', 'author', 'editor', 'herausgeber',
  'herausgeberin', 'directeur de publication', 'éditeur scientifique', 'compiler',
};

/// 目録の著者表示を、名前と役割に分ける。名前は「姓, 名」を「名 姓」に並べ替える。
/// 例: BnF「Pastoureau, Michel (1947-....). Auteur du texte」、DNB「Liedtke, Rüdiger [Verfasser]」、
/// LoC「Stokstad, Marilyn, 1929-2016.」
({String name, CreatorRole role}) parseCatalogCreator(String raw, LookupSource source) {
  var s = raw.trim();
  String? role;
  if (source == LookupSource.dnb) {
    final m = RegExp(r'^(.*?)\s*\[([^\]]+)\]\s*$').firstMatch(s);
    if (m != null) {
      s = m.group(1)!;
      role = m.group(2);
    }
  } else if (source == LookupSource.bnf) {
    final m = RegExp(r'^(.*?)\.\s+([^.]+)$').firstMatch(s);
    if (m != null) {
      s = m.group(1)!;
      role = m.group(2);
    }
    s = s.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '');
  } else {
    s = s.replaceAll(_trailingPeriod, '');
    final m = RegExp(r',\s*((?:author|translator|editor|illustrator|compiler|writer of [a-z ]+)(?:,\s*(?:author|translator|editor|illustrator|compiler))*)$')
        .firstMatch(s);
    if (m != null) {
      role = m.group(1);
      s = s.substring(0, m.start);
    }
    // 生没年（「, 1929-2016」「, 1947-」）を除く
    s = s.replaceAll(RegExp(r',\s*(?:b\.\s*)?\d{3,4}-?(?:\d{3,4})?\??$'), '');
  }
  s = s.trim().replaceAll(RegExp(r',$'), '').replaceAll(_trailingPeriod, '').trim();

  final parts = s.split(RegExp(r',\s*'));
  final name = parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty
      ? '${parts[1]} ${parts[0]}'
      : s;

  final roles = (role ?? '').toLowerCase().split(RegExp(r',\s*')).map((r) => r.trim()).toSet();
  final CreatorRole kind;
  if (roles.any(_catalogTranslatorRoles.contains)) {
    kind = CreatorRole.translator;
  } else if (role == null || roles.any(_catalogAuthorRoles.contains)) {
    kind = CreatorRole.author;
  } else {
    kind = CreatorRole.other;
  }
  return (name: name, role: kind);
}

// ---------------------------------------------------------------------------

String? _nonEmpty(String? s) {
  final t = s?.trim();
  return (t == null || t.isEmpty) ? null : t;
}

String? _joinNames(List<String> names, String separator) {
  final unique = <String>[];
  for (final n in names) {
    if (n.isNotEmpty && !unique.contains(n)) unique.add(n);
  }
  return unique.isEmpty ? null : unique.join(separator);
}
