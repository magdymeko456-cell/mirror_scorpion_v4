import 'dart:math';

import 'package:chess/chess.dart' as chess;

/// قواعد شطرنج قانونية محلية وخصم مادي بسيط. لا يمثل هذا الملف مشهداً 3D؛
/// يبقى عرض القطع ثلاثي الأبعاد مرحلة منفصلة بعد نموذج توافق المحرك.
class ChessGameController {
  ChessGameController() : _game = chess.Chess();

  chess.Chess _game;
  final Random _random = Random();

  chess.Piece? pieceAt(String square) => _game.get(square);
  bool get isWhiteTurn => _game.turn == chess.Color.WHITE;
  bool get gameOver => _game.game_over;
  bool get isCheckmate => _game.in_checkmate;
  bool get isDraw => _game.in_draw;
  String get pgn => _game.pgn();

  List<String> legalMovesFrom(String square) {
    final legalTargets = <String>[];
    for (final move in _game.moves({'verbose': true})) {
      if (move is Map && move['from'] == square && move['to'] is String) {
        legalTargets.add(move['to'] as String);
      }
    }
    return legalTargets;
  }

  bool movePlayer(String from, String to) {
    if (!isWhiteTurn || gameOver) return false;
    return _game.move({'from': from, 'to': to, 'promotion': 'q'});
  }

  bool moveComputer() {
    if (isWhiteTurn || gameOver) return false;
    final moves = _game.moves().whereType<String>().toList();
    if (moves.isEmpty) return false;

    var bestScore = 1 << 30;
    final bestMoves = <String>[];
    for (final move in moves) {
      final candidate = _game.copy();
      if (!candidate.move(move)) continue;
      final score = _materialScore(candidate);
      if (score < bestScore) {
        bestScore = score;
        bestMoves
          ..clear()
          ..add(move);
      } else if (score == bestScore) {
        bestMoves.add(move);
      }
    }
    if (bestMoves.isEmpty) return false;
    return _game.move(bestMoves[_random.nextInt(bestMoves.length)]);
  }

  void reset() => _game = chess.Chess();

  int _materialScore(chess.Chess position) {
    final values = {
      chess.Chess.PAWN: 100,
      chess.Chess.KNIGHT: 320,
      chess.Chess.BISHOP: 330,
      chess.Chess.ROOK: 500,
      chess.Chess.QUEEN: 900,
      chess.Chess.KING: 20000,
    };
    var score = 0;
    for (final file in const ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']) {
      for (var rank = 1; rank <= 8; rank++) {
        final piece = position.get('$file$rank');
        if (piece == null) continue;
        final value = values[piece.type] ?? 0;
        score += piece.color == chess.Color.WHITE ? value : -value;
      }
    }
    return score;
  }
}
