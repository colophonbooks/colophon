import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/app_localizations.dart';
import '../services/isbn.dart';

/// 本の ISBN のバーコードを読み取る。読み取れなかったり、途中でやめたりしたら null。
/// テストではカメラを使えないため、ColophonApp に別の関数を渡して差し替える。
typedef IsbnScanner = Future<String?> Function(BuildContext context);

/// カメラで ISBN のバーコードを読み取る画面を開く（スマホ・タブレット用）。
Future<String?> scanIsbnWithCamera(BuildContext context) => Navigator.push<String>(
      context,
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const BarcodeScanScreen()),
    );

/// カメラの映像から ISBN のバーコードを探し、最初に見つけた ISBN を返して閉じる画面。
class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> with WidgetsBindingObserver {
  final _controller = MobileScannerController(
    // 本のバーコードは EAN-13 だけなので、ほかの形式は探さない（誤読を減らし、処理も軽くなる）
    formats: const [BarcodeFormat.ean13],
    // 既定（Android は 640×480）では、少し離すと細い線を見分けられず読みにくい
    cameraResolution: const Size(1280, 720),
  );

  /// 読み取って閉じ始めたか。閉じる動きの間も読み取りは続くため、2回閉じないようにする。
  var _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  /// カメラの使用を拒否したあと、端末の設定で許可してから戻ってきたら、カメラを起動し直す。
  /// それ以外の中断（裏に回る・通知を開くなど）からの再開は、OS とパッケージが自動で行う。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _controller.value.error == null) return;
    _controller.start().catchError((Object _) {}); // 起動できなければ、エラーの表示のまま
  }

  void _onDetect(BarcodeCapture capture) {
    // 戻る操作で閉じている途中も読み取りは届く。そこで閉じると、下の画面（編集中の画面など）まで閉じてしまう
    if (_done || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    for (final barcode in capture.barcodes) {
      final isbn = isbnFromBarcode(barcode.rawValue);
      if (isbn == null) continue;
      _done = true;
      HapticFeedback.mediumImpact();
      Navigator.pop(context, isbn);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l.scanBarcode),
        actions: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, _) => state.torchState == TorchState.unavailable
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: l.flashlight,
                    isSelected: state.torchState == TorchState.on,
                    icon: const Icon(Icons.flashlight_off_outlined),
                    selectedIcon: const Icon(Icons.flashlight_on),
                    onPressed: _controller.toggleTorch,
                  ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l.cameraUnavailable,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          // カメラを使えないときは、写し方の案内は出さない（エラーの文言と食い違うため）
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, _) => state.error != null
                ? const SizedBox.shrink()
                : Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                        child: Text(l.scanBarcodeHint, style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
