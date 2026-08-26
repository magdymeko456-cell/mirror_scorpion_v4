import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

enum AndroidOverlayState { started, stopped, unsupported, permissionDenied, failed }

class AndroidOverlayResult {
  const AndroidOverlayResult(this.state, this.message);

  final AndroidOverlayState state;
  final String message;

  bool get isStarted => state == AndroidOverlayState.started;
}

/// طبقة Android فقط لفقاعة ظاهرة يطلبها المستخدم صراحة.
/// لا تطلب Accessibility أو Notification Listener، ولا تقرأ نصوص تطبيقات أخرى.
class AndroidOverlayService {
  bool _isVisible = false;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get isVisible => _isVisible;

  Future<AndroidOverlayResult> showBubble() async {
    if (!isSupported) {
      return const AndroidOverlayResult(
        AndroidOverlayState.unsupported,
        'الفقاعة فوق التطبيقات متاحة على Android فقط.',
      );
    }
    try {
      var permitted = await FlutterOverlayWindow.isPermissionGranted();
      if (!permitted) {
        permitted = await FlutterOverlayWindow.requestPermission();
      }
      if (!permitted) {
        return const AndroidOverlayResult(
          AndroidOverlayState.permissionDenied,
          'لم يُمنح إذن الظهور فوق التطبيقات؛ لم تبدأ الفقاعة.',
        );
      }
      await FlutterOverlayWindow.showOverlay(
        height: 84,
        width: 84,
        enableDrag: true,
        flag: OverlayFlag.defaultFlag,
        positionGravity: PositionGravity.auto,
        startPosition: OverlayPosition(0, 156),
        overlayTitle: 'Mirror Scorpion',
        overlayContent: 'فقاعة ترجمة يفعّلها المستخدم',
      );
      _isVisible = true;
      return const AndroidOverlayResult(
        AndroidOverlayState.started,
        'ظهرت الفقاعة القابلة للسحب مع إشعار foreground. لا تقرأ تطبيقات أخرى.',
      );
    } catch (_) {
      return const AndroidOverlayResult(
        AndroidOverlayState.failed,
        'تعذر بدء الفقاعة. تحقق من إذن الظهور فوق التطبيقات ثم أعد المحاولة.',
      );
    }
  }

  Future<AndroidOverlayResult> closeBubble() async {
    if (!isSupported) {
      return const AndroidOverlayResult(
        AndroidOverlayState.unsupported,
        'الفقاعة فوق التطبيقات متاحة على Android فقط.',
      );
    }
    try {
      await FlutterOverlayWindow.closeOverlay();
      _isVisible = false;
      return const AndroidOverlayResult(
        AndroidOverlayState.stopped,
        'تم إيقاف الفقاعة وإزالة إشعار foreground.',
      );
    } catch (_) {
      return const AndroidOverlayResult(
        AndroidOverlayState.failed,
        'تعذر إيقاف الفقاعة من هذه الجلسة. أوقفها من الإشعار أو أعد فتح التطبيق.',
      );
    }
  }
}

class MirrorScorpionOverlayApp extends StatelessWidget {
  const MirrorScorpionOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF102840),
              border: Border.all(color: Colors.cyanAccent, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
            ),
            child: IconButton(
              tooltip: 'إيقاف فقاعة ميرور سكربيون',
              onPressed: FlutterOverlayWindow.closeOverlay,
              icon: const Icon(Icons.translate, color: Colors.cyanAccent, size: 34),
            ),
          ),
        ),
      ),
    );
  }
}
