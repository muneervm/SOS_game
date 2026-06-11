import 'package:flutter/material.dart';
import 'game_models.dart';
import 'size_config.dart';

void main() {
  runApp(const SosGameApp());
}

class SosGameApp extends StatelessWidget {
  const SosGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOS Match',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6), // Sky Blue
          secondary: Color(0xFF10B981), // Emerald Green
          surface: Color(0xFF1E293B), // Slate 800
        ),
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Game Setup State
  bool _gameStarted = false;
  int _gridSize = 10;
  int _playerCount = 2;

  final List<TextEditingController> _nameControllers = [
    TextEditingController(text: 'Player 1'),
    TextEditingController(text: 'Player 2'),
    TextEditingController(text: 'Player 3'),
  ];

  final List<Color> _availableColors = [
    const Color(0xFFEF4444), // Rose/Red
    const Color(0xFF10B981), // Emerald/Green
    const Color(0xFF3B82F6), // Blue
  ];

  // Assign default colors uniquely
  final List<int> _selectedColorIndices = [0, 1, 2];

  // Active Game State
  List<List<String>> _board = [];
  List<ClaimedSos> _claimedLines = [];
  List<Player> _players = [];
  int _currentPlayerIndex = 0;
  String _selectedLetter = 'S';
  bool _hasPlacedLetter = false;
  bool _earnedExtraTurn = false;
  bool _gameOver = false;
  int _passesInARow = 0;

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _players = [];
      for (int i = 0; i < _playerCount; i++) {
        final color = _availableColors[_selectedColorIndices[i]];
        String colorName = 'red';
        if (color == const Color(0xFF10B981)) colorName = 'green';
        if (color == const Color(0xFF3B82F6)) colorName = 'blue';

        _players.add(
          Player(
            name: _nameControllers[i].text.trim().isEmpty
                ? 'Player ${i + 1}'
                : _nameControllers[i].text.trim(),
            color: color,
            colorName: colorName,
          ),
        );
      }

      _board = List.generate(
        _gridSize,
        (_) => List.generate(_gridSize, (_) => ''),
      );
      _claimedLines = [];
      _currentPlayerIndex = 0;
      _selectedLetter = 'S';
      _hasPlacedLetter = false;
      _earnedExtraTurn = false;
      _gameOver = false;
      _passesInARow = 0;
      _gameStarted = true;
    });
  }

  void _resetGame() {
    setState(() {
      // Keep players but reset their scores
      for (var player in _players) {
        player.score = 0;
      }
      _board = List.generate(
        _gridSize,
        (_) => List.generate(_gridSize, (_) => ''),
      );
      _claimedLines = [];
      _currentPlayerIndex = 0;
      _selectedLetter = 'S';
      _hasPlacedLetter = false;
      _earnedExtraTurn = false;
      _gameOver = false;
      _passesInARow = 0;
    });
  }

  void _exitToMenu() {
    setState(() {
      _gameStarted = false;
    });
  }

  Set<SosSequence> _findAllSosSequences() {
    final Set<SosSequence> sequences = {};
    final List<List<int>> directions = [
      [0, 1], // Horizontal
      [1, 0], // Vertical
      [1, 1], // Diagonal Down-Right
      [1, -1], // Diagonal Down-Left
    ];

    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize; c++) {
        for (var dir in directions) {
          int dr = dir[0];
          int dc = dir[1];

          int rStart = r;
          int cStart = c;
          int rEnd = r + 2 * dr;
          int cEnd = c + 2 * dc;

          if (rEnd >= 0 && rEnd < _gridSize && cEnd >= 0 && cEnd < _gridSize) {
            int rMid = r + dr;
            int cMid = c + dc;

            if (_board[rStart][cStart] == 'S' &&
                _board[rMid][cMid] == 'O' &&
                _board[rEnd][cEnd] == 'S') {
              sequences.add(SosSequence(rStart, cStart, rEnd, cEnd));
            }
          }
        }
      }
    }
    return sequences;
  }

  void _handleCellTap(int row, int col) {
    if (_gameOver) return;
    if (_hasPlacedLetter) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You have already placed a letter. Claim SOSs or tap "End Turn".',
          ),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _board[row][col] = _selectedLetter;
      _hasPlacedLetter = true;
      _passesInARow = 0;

      final allSequences = _findAllSosSequences();
      final unclaimedCount = allSequences.length - _claimedLines.length;

      if (unclaimedCount == 0) {
        if (_earnedExtraTurn) {
          // Since they earned an extra turn earlier (e.g. by claiming a missed SOS),
          // they get another placement.
          _hasPlacedLetter = false;
          _earnedExtraTurn = false;
        } else {
          // No unclaimed SOSs formed, and no extra turn earned, end turn automatically
          _nextTurn();
        }
      }

      _checkGameOver();
    });
  }

  void _handleSosClaimed(SosSequence sequence) {
    if (_gameOver) return;

    final alreadyClaimed = _claimedLines.any(
      (claimed) => claimed.sequence == sequence,
    );
    if (alreadyClaimed) return;

    setState(() {
      final currentPlayer = _players[_currentPlayerIndex];
      _claimedLines.add(ClaimedSos(sequence: sequence, player: currentPlayer));
      currentPlayer.score += 1;
      _earnedExtraTurn = true;
      _passesInARow = 0;

      final allSequences = _findAllSosSequences();
      final unclaimedCount = allSequences.length - _claimedLines.length;

      if (unclaimedCount == 0) {
        if (_hasPlacedLetter) {
          // Claimed all SOSs, extra turn granted
          _hasPlacedLetter = false;
          _earnedExtraTurn = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${currentPlayer.name} claimed an SOS! Place another letter.',
              ),
              backgroundColor: currentPlayer.color,
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${currentPlayer.name} claimed an SOS! Claim more or tap "End Turn".',
            ),
            backgroundColor: currentPlayer.color,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      _checkGameOver();
    });
  }

  void _handleEndTurn() {
    setState(() {
      _passesInARow++;
      if (_passesInARow >= _players.length) {
        _gameOver = true;
      } else {
        _nextTurn();
      }
    });
  }

  void _nextTurn() {
    _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
    _hasPlacedLetter = false;
    _earnedExtraTurn = false;
  }

  void _checkGameOver() {
    bool isFull = true;
    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize; c++) {
        if (_board[r][c].isEmpty) {
          isFull = false;
          break;
        }
      }
    }

    if (isFull) {
      final allSequences = _findAllSosSequences();
      final unclaimedCount = allSequences.length - _claimedLines.length;
      if (unclaimedCount == 0) {
        _gameOver = true;
      }
    }
  }

  List<Player> _getWinners() {
    int maxScore = -1;
    for (var p in _players) {
      if (p.score > maxScore) {
        maxScore = p.score;
      }
    }
    return _players.where((p) => p.score == maxScore).toList();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      body: SafeArea(
        child: _gameStarted ? _buildGameBoardScreen() : _buildSetupScreen(),
      ),
    );
  }

  // --- SETUP SCREEN ---
  Widget _buildSetupScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header title
          Center(
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFF10B981),
                      Color(0xFFEF4444),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'SOS MATCH',
                    style: TextStyle(
                      fontSize: 48.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.w,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'A classic strategic connection game',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 40.h),

          // Grid Size selection
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.sp),
            ),
            elevation: 8.sp,
            child: Padding(
              padding: EdgeInsets.all(20.0.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Grid Size',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [8, 9, 10].map((size) {
                      final isSelected = _gridSize == size;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.0.w),
                          child: InkWell(
                            onTap: () => setState(() => _gridSize = size),
                            borderRadius: BorderRadius.circular(12.sp),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF3B82F6)
                                    : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12.sp),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF60A5FA)
                                      : Colors.white.withValues(alpha: 0.05),
                                  width: 1.5.w,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${size}x$size',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20.h),

          // Player Count selection
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.sp),
            ),
            elevation: 8.sp,
            child: Padding(
              padding: EdgeInsets.all(20.0.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Number of Players',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [2, 3].map((count) {
                      final isSelected = _playerCount == count;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.0.w),
                          child: InkWell(
                            onTap: () => setState(() {
                              _playerCount = count;
                            }),
                            borderRadius: BorderRadius.circular(12.sp),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF10B981)
                                    : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12.sp),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF34D399)
                                      : Colors.white.withValues(alpha: 0.05),
                                  width: 1.5.w,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$count Players',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20.h),

          // Players input card
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.sp),
            ),
            elevation: 8.sp,
            child: Padding(
              padding: EdgeInsets.all(20.0.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Players Profile',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _playerCount,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 16.h),
                    itemBuilder: (context, playerIndex) {
                      final assignedColorIndex =
                          _selectedColorIndices[playerIndex];
                      final assignedColor =
                          _availableColors[assignedColorIndex];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Player ${playerIndex + 1}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: assignedColor,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameControllers[playerIndex],
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.04),
                                    hintText: 'Enter name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        12.sp,
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 14.h,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              // Color Selection Circles
                              Row(
                                children: List.generate(_availableColors.length, (
                                  colorIndex,
                                ) {
                                  final color = _availableColors[colorIndex];
                                  final isCurrentlySelectedByThisPlayer =
                                      assignedColorIndex == colorIndex;
                                  // Check if this color is already selected by another player
                                  bool isTakenByAnother = false;
                                  for (int i = 0; i < _playerCount; i++) {
                                    if (i != playerIndex &&
                                        _selectedColorIndices[i] ==
                                            colorIndex) {
                                      isTakenByAnother = true;
                                      break;
                                    }
                                  }

                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4.0.w,
                                    ),
                                    child: GestureDetector(
                                      onTap: isTakenByAnother
                                          ? null
                                          : () {
                                              setState(() {
                                                _selectedColorIndices[playerIndex] =
                                                    colorIndex;
                                              });
                                            },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width: 36.w,
                                        height: 36.h,
                                        decoration: BoxDecoration(
                                          color: isTakenByAnother
                                              ? color.withValues(alpha: 0.15)
                                              : color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                isCurrentlySelectedByThisPlayer
                                                ? Colors.white
                                                : Colors.transparent,
                                            width: 2.5.w,
                                          ),
                                          boxShadow:
                                              isCurrentlySelectedByThisPlayer
                                              ? [
                                                  BoxShadow(
                                                    color: color.withValues(alpha: 0.6),
                                                    blurRadius: 8.sp,
                                                    spreadRadius: 1.sp,
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: isTakenByAnother
                                            ? Icon(
                                                Icons.close,
                                                size: 16.sp,
                                                color: Colors.white.withValues(alpha: 0.3),
                                              )
                                            : isCurrentlySelectedByThisPlayer
                                            ? Icon(
                                                Icons.check,
                                                size: 16.sp,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 32.h),

          // Start Match Button
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.sp),
              ),
              elevation: 4.sp,
            ),
            child: Text(
              'START MATCH',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5.w,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBoardScreen() {
    final activePlayer = _players[_currentPlayerIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Match?'),
            content: const Text(
              'Are you sure you want to end this match and return to the main menu?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('EXIT'),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          _exitToMenu();
        }
      },
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top header with Back and Reset buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Exit Match?'),
                            content: const Text(
                              'Are you sure you want to end this match?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('CANCEL'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _exitToMenu();
                                },
                                child: const Text('EXIT'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Text(
                      'SOS MATCH',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.w,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Reset Match?'),
                            content: const Text(
                              'Reset the board and scores to start over?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('CANCEL'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _resetGame();
                                },
                                child: const Text('RESET'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Scoreboard card
                Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.sp),
                  ),
                  elevation: 8.sp,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0.w,
                      vertical: 12.0.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _players.asMap().entries.map((entry) {
                        int index = entry.key;
                        Player player = entry.value;
                        bool isActive = index == _currentPlayerIndex;

                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? player.color.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12.sp),
                            border: Border.all(
                              color: isActive
                                  ? player.color
                                  : Colors.transparent,
                              width: 1.5.w,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                player.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? player.color
                                      : Colors.white70,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '${player.score} pts',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w900,
                                  color: player.color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Active turn instructions
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: activePlayer.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20.sp),
                    ),
                    child: Text(
                      _hasPlacedLetter
                          ? 'SOS detected! Drag S to S to claim, or tap End Turn.'
                          : "${activePlayer.name}'s turn: Place 'S' or 'O'",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: activePlayer.color,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // The Game Board
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: SosGameBoard(
                        gridSize: _gridSize,
                        board: _board,
                        claimedLines: _claimedLines,
                        activePlayerColor: activePlayer.color,
                        onCellTap: _handleCellTap,
                        onSosClaimed: _handleSosClaimed,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                // Bottom Letter Selector and End Turn Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Opacity(
                      opacity: _hasPlacedLetter ? 0.4 : 1.0,
                      child: Container(
                        padding: EdgeInsets.all(4.sp),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16.sp),
                        ),
                        child: Row(
                          children: ['S', 'O'].map((letter) {
                            final isSelected = _selectedLetter == letter;
                            return GestureDetector(
                              onTap: _hasPlacedLetter
                                  ? null
                                  : () => setState(
                                      () => _selectedLetter = letter,
                                    ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.w,
                                  vertical: 12.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? activePlayer.color
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12.sp),
                                ),
                                child: Text(
                                  letter,
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    // End Turn Button
                    if (_hasPlacedLetter)
                      ElevatedButton(
                        onPressed: _handleEndTurn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activePlayer.color,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 14.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.sp),
                          ),
                          elevation: 4.sp,
                        ),
                        child: Text(
                          'END TURN',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10.h),
              ],
            ),
          ),

          // Game Over Modal Overlay
          if (_gameOver) _buildGameOverOverlay(),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    final winners = _getWinners();
    final isTie = winners.length > 1;

    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 32.w),
          padding: EdgeInsets.all(28.sp),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24.sp),
            border: Border.all(color: Colors.white12, width: 1.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20.sp,
                spreadRadius: 5.sp,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy/Medal Icon
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                ).createShader(bounds),
                child: Icon(
                  Icons.emoji_events,
                  size: 72.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20.h),

              Text(
                isTie ? 'TIE GAME!' : 'VICTORY!',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.w,
                ),
              ),
              SizedBox(height: 12.h),

              // Winner Info
              if (!isTie)
                Text(
                  winners[0].name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: winners[0].color,
                  ),
                )
              else
                Text(
                  winners.map((w) => w.name).join(' & '),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              SizedBox(height: 24.h),

              // Scores summary
              const Divider(color: Colors.white12),
              SizedBox(height: 12.h),
              ..._players.map(
                (p) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          color: p.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${p.score} Points',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 28.h),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _exitToMenu,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.sp),
                        ),
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: const Text(
                        'MAIN MENU',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _resetGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.sp),
                        ),
                      ),
                      child: const Text(
                        'PLAY AGAIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SosGameBoard extends StatefulWidget {
  final int gridSize;
  final List<List<String>> board;
  final List<ClaimedSos> claimedLines;
  final Color activePlayerColor;
  final Function(int row, int col) onCellTap;
  final Function(SosSequence sequence) onSosClaimed;

  const SosGameBoard({
    super.key,
    required this.gridSize,
    required this.board,
    required this.claimedLines,
    required this.activePlayerColor,
    required this.onCellTap,
    required this.onSosClaimed,
  });

  @override
  State<SosGameBoard> createState() => _SosGameBoardState();
}

class _SosGameBoardState extends State<SosGameBoard> {
  Offset? dragStartOffset;
  Offset? dragEndOffset;
  int? dragStartRow, dragStartCol;
  int? dragEndRow, dragEndCol;

  int? tapCandidateRow, tapCandidateCol;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final cellSize = size / widget.gridSize;

        return GestureDetector(
          onPanDown: (details) {
            final localPosition = details.localPosition;
            int col = (localPosition.dx / cellSize).floor();
            int row = (localPosition.dy / cellSize).floor();

            if (row >= 0 &&
                row < widget.gridSize &&
                col >= 0 &&
                col < widget.gridSize) {
              final content = widget.board[row][col];
              if (content.isEmpty) {
                tapCandidateRow = row;
                tapCandidateCol = col;
                dragStartRow = null;
                dragStartCol = null;
              } else if (content == 'S') {
                tapCandidateRow = null;
                tapCandidateCol = null;
                dragStartRow = row;
                dragStartCol = col;
                dragStartOffset = Offset(
                  (col + 0.5) * cellSize,
                  (row + 0.5) * cellSize,
                );
                dragEndOffset = dragStartOffset;
              }
            }
          },
          onPanUpdate: (details) {
            final localPosition = details.localPosition;
            if (dragStartOffset != null) {
              setState(() {
                dragEndOffset = localPosition;

                int col = (localPosition.dx / cellSize).floor();
                int row = (localPosition.dy / cellSize).floor();
                if (row >= 0 &&
                    row < widget.gridSize &&
                    col >= 0 &&
                    col < widget.gridSize) {
                  dragEndRow = row;
                  dragEndCol = col;
                } else {
                  dragEndRow = null;
                  dragEndCol = null;
                }
              });
            } else if (tapCandidateRow != null) {
              int col = (localPosition.dx / cellSize).floor();
              int row = (localPosition.dy / cellSize).floor();
              if (row != tapCandidateRow || col != tapCandidateCol) {
                tapCandidateRow = null;
                tapCandidateCol = null;
              }
            }
          },
          onPanEnd: (details) {
            if (dragStartRow != null &&
                dragStartCol != null &&
                dragEndRow != null &&
                dragEndCol != null) {
              int r1 = dragStartRow!;
              int c1 = dragStartCol!;
              int r2 = dragEndRow!;
              int c2 = dragEndCol!;

              if ((r1 != r2 || c1 != c2) && widget.board[r2][c2] == 'S') {
                int dr = r2 - r1;
                int dc = c2 - c1;

                if ((dr.abs() == 2 && dc == 0) ||
                    (dc.abs() == 2 && dr == 0) ||
                    (dr.abs() == 2 && dc.abs() == 2)) {
                  int rMid = r1 + dr ~/ 2;
                  int cMid = c1 + dc ~/ 2;

                  if (widget.board[rMid][cMid] == 'O') {
                    final seq = SosSequence(r1, c1, r2, c2);
                    widget.onSosClaimed(seq);
                  }
                }
              }
            } else if (tapCandidateRow != null && tapCandidateCol != null) {
              widget.onCellTap(tapCandidateRow!, tapCandidateCol!);
            }

            setState(() {
              dragStartOffset = null;
              dragEndOffset = null;
              dragStartRow = null;
              dragStartCol = null;
              dragEndRow = null;
              dragEndCol = null;
              tapCandidateRow = null;
              tapCandidateCol = null;
            });
          },
          child: Stack(
            children: [
              // Grid background and cells
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Slate 800
                  borderRadius: BorderRadius.circular(16.sp),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 15.sp,
                      offset: Offset(0, 8.h),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.sp),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: widget.gridSize,
                    ),
                    itemCount: widget.gridSize * widget.gridSize,
                    itemBuilder: (context, index) {
                      final row = index ~/ widget.gridSize;
                      final col = index % widget.gridSize;
                      final letter = widget.board[row][col];

                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                            width: 0.8.w,
                          ),
                        ),
                        child: Center(
                          child: AnimatedScale(
                            scale: letter.isEmpty ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.elasticOut,
                            child: letter.isEmpty
                                ? const SizedBox()
                                : Text(
                                    letter,
                                    style: TextStyle(
                                      fontSize: widget.gridSize >= 10 ? 18.sp : 22.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          offset: const Offset(1, 1),
                                          blurRadius: 2.sp,
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Glowing lines layer
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.sp),
                    child: CustomPaint(
                      painter: SosLinesPainter(
                        gridSize: widget.gridSize,
                        claimedLines: widget.claimedLines,
                        dragStartOffset: dragStartOffset,
                        dragEndOffset: dragEndOffset,
                        activePlayerColor: widget.activePlayerColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SosLinesPainter extends CustomPainter {
  final int gridSize;
  final List<ClaimedSos> claimedLines;
  final Offset? dragStartOffset;
  final Offset? dragEndOffset;
  final Color activePlayerColor;

  SosLinesPainter({
    required this.gridSize,
    required this.claimedLines,
    this.dragStartOffset,
    this.dragEndOffset,
    required this.activePlayerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / gridSize;

    // Draw claimed lines
    for (var claimed in claimedLines) {
      final seq = claimed.sequence;
      final start = Offset(
        (seq.c1 + 0.5) * cellSize,
        (seq.r1 + 0.5) * cellSize,
      );
      final end = Offset((seq.c2 + 0.5) * cellSize, (seq.r2 + 0.5) * cellSize);

      final paint = Paint()
        ..color = claimed.player.color
        ..strokeWidth = 5.0.w
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Draw a subtle glow effect behind the line
      final glowPaint = Paint()
        ..color = claimed.player.color.withValues(alpha: 0.4)
        ..strokeWidth = 10.0.w
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0.w)
        ..style = PaintingStyle.stroke;

      canvas.drawLine(start, end, glowPaint);
      canvas.drawLine(start, end, paint);
    }

    // Draw active drag preview line
    if (dragStartOffset != null && dragEndOffset != null) {
      final paint = Paint()
        ..color = activePlayerColor.withValues(alpha: 0.8)
        ..strokeWidth = 3.5.w
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Draw dashed line for active drag
      final dashWidth = 5.0.w;
      final dashSpace = 4.0.w;

      var start = dragStartOffset!;
      var end = dragEndOffset!;
      var dx = end.dx - start.dx;
      var dy = end.dy - start.dy;
      var distance = (end - start).distance;

      if (distance > 0) {
        var ux = dx / distance;
        var uy = dy / distance;

        var currentDistance = 0.0;
        while (currentDistance < distance) {
          var p1 = Offset(
            start.dx + ux * currentDistance,
            start.dy + uy * currentDistance,
          );
          currentDistance += dashWidth;
          if (currentDistance > distance) currentDistance = distance;
          var p2 = Offset(
            start.dx + ux * currentDistance,
            start.dy + uy * currentDistance,
          );
          canvas.drawLine(p1, p2, paint);
          currentDistance += dashSpace;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SosLinesPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize ||
        oldDelegate.claimedLines != claimedLines ||
        oldDelegate.dragStartOffset != dragStartOffset ||
        oldDelegate.dragEndOffset != dragEndOffset ||
        oldDelegate.activePlayerColor != activePlayerColor;
  }
}
