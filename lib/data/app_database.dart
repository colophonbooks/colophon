import 'package:sqlite3/sqlite3.dart';

/// DBスキーマのバージョン。テーブル構成を変えたら上げ、[_migrations] に手順を追加する。
const int schemaVersion = 4;

/// 初版のスキーマ。以降の変更は [_migrations] に追記する（既存の文は書き換えない）。
const _schemaV1 = [
  '''
  CREATE TABLE books (
    id          INTEGER PRIMARY KEY,
    uuid        TEXT NOT NULL UNIQUE,
    title       TEXT NOT NULL,
    author      TEXT,
    translator  TEXT,
    supervisor  TEXT,
    publisher   TEXT,
    isbn        TEXT,
    edition     TEXT,
    status      TEXT NOT NULL DEFAULT 'unset'
                CHECK (status IN ('unset', 'unread', 'reading', 'finished')),
    progress    INTEGER CHECK (progress BETWEEN 0 AND 100),
    cover       BLOB,
    cover_type  TEXT,
    thumbnail   BLOB,
    created_at  TEXT NOT NULL,
    updated_at  TEXT NOT NULL
  )''',
  '''
  CREATE TABLE notes (
    id          INTEGER PRIMARY KEY,
    book_id     INTEGER NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    position    INTEGER NOT NULL,
    category    TEXT CHECK (category IN ('impression', 'learning', 'memo', 'excerpt', 'other')),
    page        INTEGER CHECK (page >= 1),
    body        TEXT NOT NULL,
    created_at  TEXT NOT NULL,
    updated_at  TEXT NOT NULL
  )''',
  'CREATE INDEX notes_book ON notes(book_id, position)',
  '''
  CREATE TABLE read_records (
    id          INTEGER PRIMARY KEY,
    book_id     INTEGER NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    finished_on TEXT NOT NULL
  )''',
  'CREATE INDEX read_records_book ON read_records(book_id)',
  '''
  CREATE TABLE tags (
    id       INTEGER PRIMARY KEY,
    name     TEXT NOT NULL,
    -- 同一タグ判定用（NFKC＋小文字化）。SQLite の NOCASE は ASCII しか扱えないためアプリ側で作る
    name_key TEXT NOT NULL UNIQUE
  )''',
  '''
  CREATE TABLE book_tags (
    book_id INTEGER NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    tag_id  INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (book_id, tag_id)
  )''',
];

/// SQL だけで UUID（v4 形式）を作る式。移行時に既存のノートへ ID を振るために使う。
const _sqlUuid = "lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || "
    "substr(lower(hex(randomblob(2))), 2) || '-' || substr('89ab', 1 + (abs(random()) % 4), 1) || "
    "substr(lower(hex(randomblob(2))), 2) || '-' || lower(hex(randomblob(6)))";

/// v2: 端末間の同期に備える。
/// - 削除した書籍・ノートは行を残して deleted_at を記録する（削除を他の端末へ伝えるため）
/// - ノートに端末をまたいで同一と分かる ID（uuid）を振る
const _schemaV2 = [
  'ALTER TABLE books ADD COLUMN deleted_at TEXT',
  'ALTER TABLE notes ADD COLUMN uuid TEXT',
  'ALTER TABLE notes ADD COLUMN deleted_at TEXT',
  'UPDATE notes SET uuid = $_sqlUuid WHERE uuid IS NULL',
  'CREATE UNIQUE INDEX notes_uuid ON notes(uuid)',
];

/// v3: ノートのお気に入り（0=なし、1=あり）。
const _schemaV3 = [
  'ALTER TABLE notes ADD COLUMN favorite INTEGER NOT NULL DEFAULT 0 CHECK (favorite IN (0, 1))',
];

/// v4: 書影の SHA-256（16進）。同期で書影を内容ごとに1ファイルとして扱い、変わったものだけ送るため。
/// 既存の書影の値は SQL では計算できないので空のままにし、同期データを作るときに埋める。
const _schemaV4 = [
  'ALTER TABLE books ADD COLUMN cover_hash TEXT',
];

/// バージョン N へ上げる手順。キー N の文を実行すると user_version = N になる。
const Map<int, List<String>> _migrations = {
  1: _schemaV1,
  2: _schemaV2,
  3: _schemaV3,
  4: _schemaV4,
};

/// 新しいアプリで作られたDBを古いアプリで開こうとしたときの例外。
class NewerSchemaException implements Exception {
  NewerSchemaException(this.version);
  final int version;
}

Database openAppDatabase(String path) => prepareDatabase(sqlite3.open(path));

Database openInMemoryDatabase() => prepareDatabase(sqlite3.openInMemory());

/// 接続ごとの設定とスキーマの作成・更新を行う。
Database prepareDatabase(Database db) {
  db.execute('PRAGMA foreign_keys = ON');
  // 同じDBを別のウィンドウ等が書き込み中でも、すぐ失敗せず少し待つ
  db.execute('PRAGMA busy_timeout = 3000');
  migrate(db);
  return db;
}

int readSchemaVersion(Database db) =>
    db.select('PRAGMA user_version').first.columnAt(0) as int;

/// [target] はテストで古いスキーマを再現するためのもの。通常は省略する。
void migrate(Database db, {int target = schemaVersion}) {
  final current = readSchemaVersion(db);
  if (current > schemaVersion) throw NewerSchemaException(current);
  for (var v = current + 1; v <= target; v++) {
    db.execute('BEGIN');
    try {
      for (final sql in _migrations[v]!) {
        db.execute(sql);
      }
      db.execute('PRAGMA user_version = $v');
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }
}
