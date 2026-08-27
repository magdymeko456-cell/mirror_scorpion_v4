import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import '../app/royal_dark_theme.dart';
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
  String _gameNotice = 'ابدأ بنقل قطعة بيضاء';
  final List<String> _capturedByWhite = [];
  final List<String> _capturedByBlack = [];

  bool get _computerTurn => _playAgainstComputer && !_chess.isWhiteTurn;

  void _setPlayMode(bool vsComputer) {
    setState(() {
      _playAgainstComputer = vsComputer;
      _resetGame();
    });
  }

  void _setComputerLevel(ChessComputerLevel level) {
    setState(() => _computerLevel = level);
  }

  void _resetGame() {
    _chess.reset();
    _selectedSquare = null;
    _legalTargets = const [];
    _computerThinking = false;
    _capturedByWhite.clear();
    _capturedByBlack.clear();
    _gameNotice = 'مباراة جديدة';
    if (_computerTurn) _scheduleComputer();
  }

  void _scheduleComputer() {
    if (_computerThinking || !mounted) return;
    if (!_computerTurn || _chess.gameOver) return;
    _computerThinking = true;
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (!_computerTurn || _chess.gameOver) {
        _computerThinking = false;
        return;
      }
      if (_chess.moveComputer(level: _computerLevel)) {
        setState(() {
          _computerThinking = false;
          _selectedSquare = null;
          _legalTargets = const [];
          _gameNotice = _buildNotice();
        });
      } else {
        setState(() => _computerThinking = false);
      }
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
      return;
    }

    setState(() {
      _selectedSquare = null;
      _legalTargets = const [];
    });
  }

  void _tryMove(String from, String to) {
    final captured = _chess.pieceAt(to);
    if (captured != null) {
      final sym = ChessGameController.pieceSymbol(captured);
      if (_chess.isWhiteTurn) {
        _capturedByWhite.add(sym);
      } else {
        _capturedByBlack.add(sym);
      }
    }

    if (!_chess.moveHuman(from, to)) return;

    setState(() {
      _selectedSquare = null;
      _legalTargets = const [];
      _gameNotice = _buildNotice();
    });

    _scheduleComputer();
  }

  String _buildNotice() {
    if (_chess.isCheckmate) {
      return _chess.isWhiteTurn ? 'كش مات — الأسود يفوز 🏆' : 'كش مات — الأبيض يفوز 🏆';
    }
    if (_chess.isDraw) return 'تعادل';
    if (_chess.gameOver) return 'انتهت المباراة';
    return _chess.isWhiteTurn ? 'دور الأبيض ♔' : 'دور الأسود ♚';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('نادي الشطرنج - Chess Club'),
          actions: [
            IconButton(
              tooltip: 'مباراة جديدة',
              icon: const Icon(Icons.restart_alt),
              onPressed: _resetGame,
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF18110C), Color(0xFF0F0B08)],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
              children: [
                _buildModeSelector(),
                if (_playAgainstComputer) _buildLevelChips(),
                const SizedBox(height: 10),
                _buildStatusBar(),
                const SizedBox(height: 14),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _buildChessBoard(),
                  ),
                ),
                const SizedBox(height: 14),
                _buildCapturedRow(),
                const SizedBox(height: 10),
                _buildNoticeBar(),
                const SizedBox(height: 8),
                _buildPgnRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Card(
      color: const Color(0xFF241B14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر طريقة اللعب',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFFEAD8C0)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('ضد الكمبيوتر'),
                  selected: _playAgainstComputer,
                  selectedColor: const Color(0xFFB58863),
                  onSelected: (_) => _setPlayMode(true),
                ),
                ChoiceChip(
                  label: const Text('لاعبان محلياً'),
                  selected: !_playAgainstComputer,
                  selectedColor: const Color(0xFFB58863),
                  onSelected: (_) => _setPlayMode(false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: ChessComputerLevel.values.map((level) {
          return ChoiceChip(
            label: Text(level.label),
            selected: _computerLevel == level,
            selectedColor: const Color(0xFFD4A373),
            labelStyle: TextStyle(
              color: _computerLevel == level ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            onSelected: (_) => _setComputerLevel(level),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF241B14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5C3A21)),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _chess.isWhiteTurn ? const Color(0xFFF0D9B5) : const Color(0xFF2B1E16),
              border: Border.all(
                color: _chess.gameOver ? Colors.redAccent : const Color(0xFFD4A373),
                width: 2.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _gameNotice,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _chess.gameOver ? Colors.orangeAccent : const Color(0xFFEAD8C0),
              ),
            ),
          ),
          Text(
            _chess.isWhiteTurn ? 'الأبيض' : 'الأسود',
            style: const TextStyle(color: RoyalColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildChessBoard() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3D2314), width: 10),
          gradient: const LinearGradient(
            colors: [Color(0xFF5C3A21), Color(0xFF3D2314), Color(0xFF5C3A21)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.75),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
            ),
            itemCount: 64,
            itemBuilder: (_, index) {
              final rank = 8 - index ~/ 8;
              final file = String.fromCharCode('a'.codeUnitAt(0) + index % 8);
              return _buildSquare('$file$rank', index);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSquare(String square, int index) {
    final fileIdx = index % 8;
    final rankIdx = index ~/ 8;
    final isLight = (fileIdx + rankIdx).isEven;
    final piece = _chess.pieceAt(square);
    final isSelected = _selectedSquare == square;
    final isTarget = _legalTargets.contains(square);

    // ألوان رقعة خشبية كلاسيكية احترافية (Chess Club Wood Style)
    final lightColor = const Color(0xFFF0D9B5);
    final darkColor = const Color(0xFFB58863);

    return GestureDetector(
      onTap: () => _onSquareTap(square),
      child: Container(
        color: isLight ? lightColor : darkColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isSelected)
              Container(color: const Color(0xFFBACA44).withValues(alpha: 0.75)),
            if (isTarget && piece == null)
              Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                ),
              ),
            if (isTarget && piece != null)
              Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.85),
                      width: 3.5,
                    ),
                  ),
                ),
              ),
            if (piece != null)
              Center(
                child: _ChessPieceToken(
                  symbol: ChessGameController.pieceSymbol(piece),
                  isWhite: piece.color == chess.Color.WHITE,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturedRow() {
    return Row(
      children: [
        Expanded(child: _CapturedGroup(label: 'أسر الأبيض', symbols: _capturedByWhite)),
        const SizedBox(width: 8),
        Expanded(child: _CapturedGroup(label: 'أسر الأسود', symbols: _capturedByBlack)),
      ],
    );
  }

  Widget _buildNoticeBar() {
    if (_computerThinking) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text('الكمبيوتر يفكر…', style: TextStyle(color: RoyalColors.muted)),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPgnRow() {
    return Card(
      color: const Color(0xFF241B14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PGN:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: RoyalColors.muted)),
            const SizedBox(height: 6),
            SelectableText(
              _chess.pgn.isEmpty ? 'النقلات ستظهر هنا…' : _chess.pgn,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: RoyalColors.muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChessPieceToken extends StatelessWidget {
  const _ChessPieceToken({required this.symbol, required this.isWhite});

  final String symbol;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    if (symbol.isEmpty) return const SizedBox.shrink();

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // ظل خشب سفلي للقطعة
        Positioned(
          bottom: -2,
          child: Container(
            width: 24,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
        Text(
          symbol,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isWhite ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1A),
            fontSize: 40,
            height: 1,
            shadows: [
              Shadow(
                color: isWhite ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.2),
                blurRadius: 3,
                offset: const Offset(1, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CapturedGroup extends StatelessWidget {
  const _CapturedGroup({required this.label, required this.symbols});

  final String label;
  final List<String> symbols;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF241B14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5C3A21)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: RoyalColors.muted)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              symbols.isEmpty ? '—' : symbols.join(' '),
              textDirection: TextDirection.ltr,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
