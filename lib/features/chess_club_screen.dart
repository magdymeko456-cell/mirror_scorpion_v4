import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import '../core/games/chess_game_controller.dart';

class ChessClubScreen extends StatefulWidget {
  const ChessClubScreen({super.key});

  @override
  State<ChessClubScreen> createState() => _ChessClubScreenState();
}

class _ChessClubScreenState extends State<ChessClubScreen> {
  final ChessGameController _chess = ChessGameController();

  bool _playAgainstComputer = true;
  ChessComputerLevel _computerLevel = ChessComputerLevel.medium;
  String? _selectedSquare;
  List<String> _legalTargets = const [];
  bool _computerThinking = false;
  String _gameNotice = 'دور الأبيض';
  String? _suggestedHint;

  bool get _computerTurn => _playAgainstComputer && !_chess.isWhiteTurn;

  void _resetGame() {
    setState(() {
      _chess.reset();
      _selectedSquare = null;
      _legalTargets = const [];
      _computerThinking = false;
      _suggestedHint = null;
      _gameNotice = 'مباراة جديدة — دور الأبيض';
    });
    if (_computerTurn) _scheduleComputer();
  }

  void _scheduleComputer() {
    if (_computerThinking || !mounted) return;
    if (!_computerTurn || _chess.gameOver) return;
    _computerThinking = true;

    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (!_computerTurn || _chess.gameOver) {
        setState(() => _computerThinking = false);
        return;
      }
      if (_chess.moveComputer(level: _computerLevel)) {
        setState(() {
          _computerThinking = false;
          _selectedSquare = null;
          _legalTargets = const [];
          _suggestedHint = null;
          _gameNotice = _buildNotice();
        });
      } else {
        setState(() => _computerThinking = false);
      }
    });
  }

  void _getBestHint() {
    if (_chess.gameOver) return;
    final hintMove = _chess.getBestMove(level: _computerLevel);
    setState(() {
      _suggestedHint = hintMove != null ? 'التلميح الموصى به: $hintMove' : 'لا يوجد تلميح مباشر';
    });
  }

  void _onSquareTap(String square) {
    if (_chess.gameOver || _computerTurn || _computerThinking) return;

    final piece = _chess.pieceAt(square);
    final isOwn = piece != null &&
        piece.color == (_chess.isWhiteTurn ? chess.Color.WHITE : chess.Color.BLACK);

    if (isOwn) {
      setState(() {
        _selectedSquare = square;
        _legalTargets = _chess.legalMovesFrom(square);
      });
      return;
    }

    if (_selectedSquare != null && _legalTargets.contains(square)) {
      _tryMove(_selectedSquare!, square);
    }
  }

  void _tryMove(String from, String to) {
    final success = _chess.makeMove(from, to);
    if (success) {
      setState(() {
        _selectedSquare = null;
        _legalTargets = const [];
        _suggestedHint = null;
        _gameNotice = _buildNotice();
      });
      if (_computerTurn) _scheduleComputer();
    }
  }

  String _buildNotice() {
    if (_chess.inCheckmate) return 'كش مات! انتهت اللعبة';
    if (_chess.inDraw) return 'تعادل!';
    if (_chess.inCheck) return 'كش ملك! ${_chess.isWhiteTurn ? "دور الأبيض" : "دور الأسود"}';
    return _chess.isWhiteTurn ? 'دور الأبيض' : 'دور الأسود';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ركن الشطرنج 3D والألغاز'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline, color: Colors.amber),
            tooltip: 'تلميح ونقلة مقترحة',
            onPressed: _getBestHint,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة المباراة',
            onPressed: _resetGame,
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط التحكم بالخيارات والمستويات
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1E1E2C),
            child: Row(
              children: [
                const Text('المستوى: ', style: TextStyle(color: Colors.white70)),
                DropdownButton<ChessComputerLevel>(
                  value: _computerLevel,
                  dropdownColor: const Color(0xFF2A2A3D),
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                  items: ChessComputerLevel.values.map((lvl) {
                    return DropdownMenuItem(
                      value: lvl,
                      child: Text(lvl.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _computerLevel = val);
                  },
                ),
                const Spacer(),
                FilterChip(
                  label: Text(_playAgainstComputer ? 'ضد الكمبيوتر' : 'لاعبان'),
                  selected: _playAgainstComputer,
                  onSelected: (val) => setState(() => _playAgainstComputer = val),
                ),
              ],
            ),
          ),
          if (_suggestedHint != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.amber.withValues(alpha: 0.2),
              child: Text(
                _suggestedHint!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _gameNotice,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          // الرقعة بالتصميم المطور المجسم 3D
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                    itemCount: 64,
                    itemBuilder: (context, index) {
                      final rank = 8 - (index ~/ 8);
                      final fileIndex = index % 8;
                      final fileName = String.fromCharCode('a'.codeUnitAt(0) + fileIndex);
                      final square = '$fileName$rank';

                      final isDark = (rank + fileIndex) % 2 == 0;
                      final isSelected = _selectedSquare == square;
                      final isTarget = _legalTargets.contains(square);
                      final piece = _chess.pieceAt(square);

                      return GestureDetector(
                        onTap: () => _onSquareTap(square),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.amber.withValues(alpha: 0.8)
                                : isTarget
                                    ? Colors.green.withValues(alpha: 0.6)
                                    : isDark
                                        ? const Color(0xFFB58863)
                                        : const Color(0xFFF0D9B5),
                            border: Border.all(
                              color: Colors.black12,
                              width: 0.5,
                            ),
                          ),
                          child: Center(
                            child: piece == null
                                ? null
                                : Text(
                                    _chess.getPieceSymbol(piece),
                                    style: TextStyle(
                                      fontSize: 32,
                                      shadows: const [
                                        Shadow(
                                          offset: Offset(2, 2),
                                          blurRadius: 3,
                                          color: Colors.black45,
                                        ),
                                      ],
                                      color: piece.color == chess.Color.WHITE
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
