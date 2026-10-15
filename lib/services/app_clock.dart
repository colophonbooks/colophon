/// 作成日時・更新日時・削除日時として記録する現在時刻（UTC）。
///
/// 同期では端末どうしの記録時刻を比べて新しい方を採用するため、端末の時計のずれを
/// Google のサーバー時刻との差（[offset]）で補正する。画面に出すだけの時刻には使わない。
abstract final class AppClock {
  static Duration offset = Duration.zero;

  static DateTime now() => DateTime.now().toUtc().add(offset);
}
