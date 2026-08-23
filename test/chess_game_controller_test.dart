import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/games/chess_game_controller.dart';

void main() {
  test('starts with legal white pawn moves and alternates with local computer', () {
    final game = ChessGameController();

    expect(game.legalMovesFrom('e2'), containsAll(<String>['e3', 'e4']));
    expect(game.movePlayer('e2', 'e4'), isTrue);
    expect(game.isWhiteTurn, isFalse);
    expect(game.moveComputer(), isTrue);
    expect(game.isWhiteTurn, isTrue);
  });

  test('does not let the player move while it is the computer turn', () {
    final game = ChessGameController();

    expect(game.movePlayer('e2', 'e4'), isTrue);
    expect(game.movePlayer('d2', 'd4'), isFalse);
  });

  test('maps starting pieces to visible Unicode chess symbols', () {
    final game = ChessGameController();

    expect(ChessGameController.pieceSymbol(game.pieceAt('e2')), '♙');
    expect(ChessGameController.pieceSymbol(game.pieceAt('e7')), '♟');
    expect(ChessGameController.pieceSymbol(game.pieceAt('d1')), '♕');
    expect(ChessGameController.pieceSymbol(game.pieceAt('d8')), '♛');
    expect(ChessGameController.pieceSymbol(game.pieceAt('e4')), isEmpty);
  });
}
