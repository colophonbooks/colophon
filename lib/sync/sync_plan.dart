import 'dart:convert';

import '../services/isbn.dart';
import '../services/search.dart';
import 'sync_snapshot.dart';

/// 初めて同期するとき、この端末とクラウドの両方にデータがあった場合の扱い（利用者が選ぶ）。
enum FirstSyncMode {
  /// 両方を合わせる。ISBN が同じ書籍は同じ本とみなして1冊にまとめる
  merge,

  /// クラウドの内容に置き換える（この端末だけにある書籍・ノートは削除する）
  useRemote,

  /// この端末の内容に置き換える（クラウドだけにある書籍・ノートは、ほかの端末からも削除する）
  useLocal,
}

/// 同期1回分の作業内容。
class SyncPlan {
  const SyncPlan({
    required this.merged,
    required this.booksToApply,
    required this.notesToApply,
    required this.uploadNeeded,
    this.remoteUnreadable = false,
  });

  /// 統合した結果。[uploadNeeded] ならクラウドへ送る。
  final SyncSnapshot merged;

  /// この端末へ書き込む書籍（削除済みの印を含む）。
  final List<SyncBook> booksToApply;

  /// この端末へ書き込むノート（削除済みの印を含む）。
  final List<SyncNote> notesToApply;

  /// クラウドの内容が [merged] と違う（送る必要がある）か。
  final bool uploadNeeded;

  /// クラウドの同期データに読めない記録があった（送信を見合わせた）。利用者に知らせる。
  final bool remoteUnreadable;

  bool get localChanged => booksToApply.isNotEmpty || notesToApply.isNotEmpty;

  /// 統合後に必要な書影（削除されていない書籍が参照しているもの）。
  Set<String> get coverHashes => {
        for (final b in merged.books)
          if (!b.isDeleted && b.coverHash != null) b.coverHash!,
      };
}

/// この端末の同期データ [local] とクラウドの同期データ [remote] を統合する。
///
/// - 書籍・ノートとも uuid で突き合わせ、更新日時が新しい方を採用する。同時刻なら削除を優先し、
///   それでも決まらなければクラウド側を採用する（どの端末でも同じ結果に落ち着くように）
/// - 削除済みになった書籍のノートは、すべて削除済みにする
/// - [remote] が null（クラウドにまだ何もない）なら、この端末の内容をそのまま送る
/// - [firstSync] は初めての同期で、両方にデータがあるときだけ指定する
///
/// [now] は、ISBN でまとめた書籍や置き換えで削除する書籍に付ける日時。
SyncPlan planSync({
  required SyncSnapshot local,
  required SyncSnapshot? remote,
  FirstSyncMode? firstSync,
  required DateTime now,
}) {
  if (remote == null) {
    return SyncPlan(merged: local, booksToApply: const [], notesToApply: const [], uploadNeeded: true);
  }
  final plan = _plan(local, remote, firstSync, now);
  // クラウドに読めない記録があれば送らない。送ると、その記録（削除の印かもしれない）がクラウドから消える
  return remote.unreadableRecords == 0
      ? plan
      : SyncPlan(
          merged: plan.merged,
          booksToApply: plan.booksToApply,
          notesToApply: plan.notesToApply,
          uploadNeeded: false,
          remoteUnreadable: true,
        );
}

SyncPlan _plan(SyncSnapshot local, SyncSnapshot remote, FirstSyncMode? firstSync, DateTime now) {
  switch (firstSync) {
    case FirstSyncMode.useRemote:
      return _replaceLocal(local, remote, now);
    case FirstSyncMode.useLocal:
      return _replaceRemote(local, remote, now);
    case FirstSyncMode.merge:
      return _merge(_combineSameIsbn(local, remote, now), remote, actualLocal: local);
    case null:
      return _merge(local, remote);
  }
}

/// [actualLocal] は、[local] を書き換えてから統合する場合（ISBN でまとめる場合）の、この端末の実際の内容。
/// この端末へ書き込む差分は、実際の内容と比べて求める。
SyncPlan _merge(SyncSnapshot local, SyncSnapshot remote, {SyncSnapshot? actualLocal}) {
  final localBooks = _byUuid(local.books, (b) => b.uuid);
  final remoteBooks = _byUuid(remote.books, (b) => b.uuid);
  final localNotes = _byUuid(local.notes, (n) => n.uuid);
  final remoteNotes = _byUuid(remote.notes, (n) => n.uuid);
  final actualBooks = actualLocal == null ? localBooks : _byUuid(actualLocal.books, (b) => b.uuid);
  final actualNotes = actualLocal == null ? localNotes : _byUuid(actualLocal.notes, (n) => n.uuid);

  final books = <String, SyncBook>{
    for (final uuid in {...remoteBooks.keys, ...localBooks.keys})
      uuid: _newer(localBooks[uuid], remoteBooks[uuid], (b) => b.updatedAt, (b) => b.isDeleted),
  };
  final notes = <String, SyncNote>{
    for (final uuid in {...remoteNotes.keys, ...localNotes.keys})
      uuid: _newer(localNotes[uuid], remoteNotes[uuid], (n) => n.updatedAt, (n) => n.isDeleted),
  };

  // 書籍の削除で一緒に消えたノート（削除日時が書籍と同じ）は、書籍がもう片方の端末の編集で
  // 復活した場合、もう片方に残っているノートを採る。書籍の更新日時にそろえて、次回からは落ち着かせる
  for (final n in notes.values.toList()) {
    final book = books[n.bookUuid];
    if (!n.isDeleted || book == null || book.isDeleted) continue;
    final deletedWithBook = [localBooks[n.bookUuid], remoteBooks[n.bookUuid]]
        .any((b) => b != null && b.isDeleted && b.deletedAt == n.deletedAt);
    final alive = [localNotes[n.uuid], remoteNotes[n.uuid]].where((x) => x != null && !x.isDeleted).firstOrNull;
    if (deletedWithBook && alive != null) notes[n.uuid] = alive.copyWith(updatedAt: book.updatedAt);
  }

  // 書籍の削除はノートの変更より後に起きている（ノートを変えると書籍の更新日時も進むため）。
  // 削除済みになった書籍に残ったノートは削除済みにそろえる
  for (final n in notes.values.toList()) {
    final book = books[n.bookUuid];
    if (!n.isDeleted && book != null && book.isDeleted) {
      notes[n.uuid] = n.copyWith(updatedAt: book.updatedAt, deletedAt: book.deletedAt);
    }
  }

  // ノートの並び順を実際のノートにそろえる。別の端末で足されたノートは並び順に入っていないので、
  // 作成日時順に後ろへ付ける。どの端末でも同じ結果になるので、1回送れば落ち着く
  final aliveNotes = <String, List<SyncNote>>{};
  for (final n in notes.values) {
    if (!n.isDeleted) (aliveNotes[n.bookUuid] ??= []).add(n);
  }
  for (final b in books.values.toList()) {
    if (b.isDeleted) continue;
    final alive = aliveNotes[b.uuid] ?? const <SyncNote>[];
    final remaining = {for (final n in alive) n.uuid};
    final ordered = [
      for (final uuid in b.noteOrder)
        if (remaining.remove(uuid)) uuid,
    ];
    final extra = [
      for (final n in alive)
        if (remaining.contains(n.uuid)) n,
    ]..sort((x, y) => x.createdAt != y.createdAt ? x.createdAt.compareTo(y.createdAt) : x.uuid.compareTo(y.uuid));
    final order = [...ordered, for (final n in extra) n.uuid];
    if (order.join('\n') != b.noteOrder.join('\n')) books[b.uuid] = b.copyWith(noteOrder: order);
  }

  return SyncPlan(
    merged: SyncSnapshot(books: books.values.toList(), notes: notes.values.toList()),
    // この端末にない書籍・ノートの削除済みの印は、消すものがないので書き込まない
    booksToApply: [
      for (final b in books.values)
        if (!_same(actualBooks[b.uuid]?.toJson(), b.toJson()) && (actualBooks.containsKey(b.uuid) || !b.isDeleted)) b,
    ],
    notesToApply: [
      for (final n in notes.values)
        if (!_same(actualNotes[n.uuid]?.toJson(), n.toJson()) && (actualNotes.containsKey(n.uuid) || !n.isDeleted)) n,
    ],
    uploadNeeded: books.values.any((b) => !_same(remoteBooks[b.uuid]?.toJson(), b.toJson())) ||
        notes.values.any((n) => !_same(remoteNotes[n.uuid]?.toJson(), n.toJson())),
  );
}

/// この端末だけにある書籍と、クラウドだけにある書籍で ISBN が同じものを1冊にまとめる。
///
/// まとめた書籍はクラウド側の uuid を使い（ほかの端末とそろえるため）、内容は更新日時が新しい方、
/// 読了日・タグは両方を合わせ、ノートは両方を残す。この端末側の元の書籍は削除済みにする。
SyncSnapshot _combineSameIsbn(SyncSnapshot local, SyncSnapshot remote, DateTime now) {
  final remoteUuids = {for (final b in remote.books) b.uuid};
  final localUuids = {for (final b in local.books) b.uuid};
  final remoteOnlyByIsbn = <String, SyncBook>{};
  for (final b in remote.books) {
    final key = b.isDeleted || localUuids.contains(b.uuid) ? null : _isbnKey(b);
    if (key != null) remoteOnlyByIsbn.putIfAbsent(key, () => b);
  }

  final replaced = <String, String>{}; // この端末の uuid → まとめ先（クラウド）の uuid
  final books = <SyncBook>[];
  for (final b in local.books) {
    final key = b.isDeleted || remoteUuids.contains(b.uuid) ? null : _isbnKey(b);
    final partner = key == null ? null : remoteOnlyByIsbn.remove(key);
    if (partner == null) {
      books.add(b);
      continue;
    }
    replaced[b.uuid] = partner.uuid;
    final base = b.updatedAt.isAfter(partner.updatedAt) ? b : partner;
    final localNoteUuids = b.noteOrder;
    books
      ..add(base.copyWith(
        uuid: partner.uuid,
        readDates: ({...partner.readDates, ...b.readDates}.toList()..sort()),
        tags: _unionTags(partner.tags, b.tags),
        noteOrder: [...partner.noteOrder, ...localNoteUuids.where((u) => !partner.noteOrder.contains(u))],
        updatedAt: now,
      ))
      ..add(SyncBook.tombstone(b.uuid, createdAt: b.createdAt, at: now));
  }
  return SyncSnapshot(
    books: books,
    notes: [
      for (final n in local.notes)
        if (replaced[n.bookUuid] case final target?) n.copyWith(bookUuid: target, updatedAt: now) else n,
    ],
  );
}

/// クラウドの内容に置き換える。この端末だけにあるものは削除済みにする（クラウドへは送らない）。
SyncPlan _replaceLocal(SyncSnapshot local, SyncSnapshot remote, DateTime now) {
  final remoteBooks = {for (final b in remote.books) b.uuid};
  final remoteNotes = {for (final n in remote.notes) n.uuid};
  final localBooks = _byUuid(local.books, (b) => b.uuid);
  final localNotes = _byUuid(local.notes, (n) => n.uuid);
  return SyncPlan(
    merged: remote,
    booksToApply: [
      for (final b in remote.books)
        if (!_same(localBooks[b.uuid]?.toJson(), b.toJson())) b,
      for (final b in local.books)
        if (!remoteBooks.contains(b.uuid) && !b.isDeleted) SyncBook.tombstone(b.uuid, createdAt: b.createdAt, at: now),
    ],
    notesToApply: [
      for (final n in remote.notes)
        if (!_same(localNotes[n.uuid]?.toJson(), n.toJson())) n,
      for (final n in local.notes)
        if (!remoteNotes.contains(n.uuid) && !n.isDeleted) n.copyWith(updatedAt: now, deletedAt: now),
    ],
    uploadNeeded: false,
  );
}

/// この端末の内容に置き換える。クラウドだけにあるものは削除済みにして送り、ほかの端末からも消す。
///
/// 両方にあって内容が違う書籍・ノートは、更新日時を [now] にしてから送る。元の日時のままだと、
/// ほかの端末に残っている新しい日時の版が次の同期で勝ち、置き換えた内容が戻されるため。
/// この端末にも同じ日時を書き込み、送った内容とそろえる。
SyncPlan _replaceRemote(SyncSnapshot local, SyncSnapshot remote, DateTime now) {
  final localBooks = {for (final b in local.books) b.uuid};
  final localNotes = {for (final n in local.notes) n.uuid};
  final remoteBooks = _byUuid(remote.books, (b) => b.uuid);
  final remoteNotes = _byUuid(remote.notes, (n) => n.uuid);
  final restampedBooks = [
    for (final b in local.books)
      if (remoteBooks[b.uuid] != null && !_same(remoteBooks[b.uuid]!.toJson(), b.toJson())) b.copyWith(updatedAt: now),
  ];
  final restampedNotes = [
    for (final n in local.notes)
      if (remoteNotes[n.uuid] != null && !_same(remoteNotes[n.uuid]!.toJson(), n.toJson())) n.copyWith(updatedAt: now),
  ];
  final restampedBookIds = {for (final b in restampedBooks) b.uuid};
  final restampedNoteIds = {for (final n in restampedNotes) n.uuid};
  final merged = SyncSnapshot(
    books: [
      for (final b in local.books)
        if (!restampedBookIds.contains(b.uuid)) b,
      ...restampedBooks,
      for (final b in remote.books)
        if (!localBooks.contains(b.uuid))
          b.isDeleted ? b : SyncBook.tombstone(b.uuid, createdAt: b.createdAt, at: now),
    ],
    notes: [
      for (final n in local.notes)
        if (!restampedNoteIds.contains(n.uuid)) n,
      ...restampedNotes,
      for (final n in remote.notes)
        if (!localNotes.contains(n.uuid)) n.isDeleted ? n : n.copyWith(updatedAt: now, deletedAt: now),
    ],
  );
  return SyncPlan(merged: merged, booksToApply: restampedBooks, notesToApply: restampedNotes, uploadNeeded: true);
}

String? _isbnKey(SyncBook b) => b.isbn == null ? null : isbnMatchKey(b.isbn!);

List<String> _unionTags(List<String> a, List<String> b) {
  final seen = <String>{};
  return [
    for (final t in [...a, ...b])
      if (seen.add(tagKey(t))) t,
  ]..sort((x, y) => tagKey(x).compareTo(tagKey(y)));
}

Map<String, T> _byUuid<T>(List<T> items, String Function(T) uuid) => {for (final i in items) uuid(i): i};

T _newer<T extends Object>(T? local, T? remote, DateTime Function(T) updatedAt, bool Function(T) deleted) {
  if (local == null) return remote!;
  if (remote == null) return local;
  final l = updatedAt(local), r = updatedAt(remote);
  if (l.isAfter(r)) return local;
  if (r.isAfter(l)) return remote;
  if (deleted(local) != deleted(remote)) return deleted(local) ? local : remote;
  return remote;
}

/// 同期データ上で同じ内容か。タグは同一判定用のキー（大文字小文字・全角半角を区別しない）の集合で比べる。
/// 端末ごとにタグの表記（「SF」と「sf」など）が違っても、同じタグとみなして書き込みを繰り返さないため。
bool _same(Map<String, dynamic>? a, Map<String, dynamic> b) =>
    a != null && jsonEncode(_comparable(a)) == jsonEncode(_comparable(b));

Map<String, dynamic> _comparable(Map<String, dynamic> json) {
  final tags = json['tags'];
  if (tags is! List) return json;
  return {...json, 'tags': ({for (final t in tags) tagKey(t as String)}.toList()..sort())};
}
