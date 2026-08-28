import 'dart:async';
import 'package:flutter/foundation.dart';

class SharedTextInbox extends ChangeNotifier {
  String _pendingText = '';
  final StreamController<String> _textStreamController = StreamController<String>.broadcast();

  String get pendingText => _pendingText;
  Stream<String> get textStream => _textStreamController.stream;

  void updateSharedText(String text) {
    _pendingText = text;
    _textStreamController.add(text);
    notifyListeners();
  }

  void clear() {
    _pendingText = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _textStreamController.close();
    super.dispose();
  }
}
