import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';

class GameController extends ChangeNotifier {
  bool _gameStarted = false;
  int _gridSize = 10;
  int _playerCount = 2;

  final List<Color> _availableColors = [
    const Color(0xFFEF4444),
    const Color(0xFF10B981),
    const Color(0xFF3B82F6),
  ];

  final List<int> _selectedColorIndices = [0, 1, 2];
  List<String> _savedPlayerNames = ['Player 1', 'Player 2', 'Player 3'];

  List<List<String>> _board = [];
  List<ClaimedSos> _claimedLines = [];
  List<Player> _players = [];
  int _currentPlayerIndex = 0;
  String _selectedLetter = 'S';
  bool _hasPlacedLetter = false;
  bool _earnedExtraTurn = false;
  bool _gameOver = false;
  int _passesInARow = 0;

  bool get gameStarted => _gameStarted;
  int get gridSize => _gridSize;
  int get playerCount => _playerCount;
  List<Color> get availableColors => _availableColors;
  List<int> get selectedColorIndices => _selectedColorIndices;
  List<String> get savedPlayerNames => _savedPlayerNames;
  List<List<String>> get board => _board;
  List<ClaimedSos> get claimedLines => _claimedLines;
  List<Player> get players => _players;
  int get currentPlayerIndex => _currentPlayerIndex;
  String get selectedLetter => _selectedLetter;
  bool get hasPlacedLetter => _hasPlacedLetter;
  bool get earnedExtraTurn => _earnedExtraTurn;
  bool get gameOver => _gameOver;
  int get passesInARow => _passesInARow;

  Player get activePlayer => _players[_currentPlayerIndex];

  GameController() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _gridSize = prefs.getInt('gridSize') ?? 10;
      _playerCount = prefs.getInt('playerCount') ?? 2;
      
      final names = prefs.getStringList('savedPlayerNames');
      if (names != null && names.length >= 3) {
        _savedPlayerNames = names;
      }
      
      final colors = prefs.getStringList('selectedColorIndices');
      if (colors != null && colors.length >= 3) {
        _selectedColorIndices[0] = int.tryParse(colors[0]) ?? 0;
        _selectedColorIndices[1] = int.tryParse(colors[1]) ?? 1;
        _selectedColorIndices[2] = int.tryParse(colors[2]) ?? 2;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('gridSize', _gridSize);
      await prefs.setInt('playerCount', _playerCount);
      await prefs.setStringList('savedPlayerNames', _savedPlayerNames);
      await prefs.setStringList(
        'selectedColorIndices',
        _selectedColorIndices.map((i) => i.toString()).toList(),
      );
    } catch (_) {}
  }

  void setGridSize(int size) {
    _gridSize = size;
    _saveSettings();
    notifyListeners();
  }

  void setPlayerCount(int count) {
    _playerCount = count;
    _saveSettings();
    notifyListeners();
  }

  void selectLetter(String letter) {
    _selectedLetter = letter;
    notifyListeners();
  }

  void updateColorIndex(int playerIndex, int colorIndex) {
    bool isTaken = false;
    for (int i = 0; i < _playerCount; i++) {
      if (i != playerIndex && _selectedColorIndices[i] == colorIndex) {
        isTaken = true;
        break;
      }
    }
    if (!isTaken) {
      _selectedColorIndices[playerIndex] = colorIndex;
      _saveSettings();
      notifyListeners();
    }
  }

  void startGame(List<String> names) {
    _players = [];
    _savedPlayerNames = List.from(names);
    _saveSettings();

    for (int i = 0; i < _playerCount; i++) {
      final color = _availableColors[_selectedColorIndices[i]];
      String colorName = 'red';
      if (color == const Color(0xFF10B981)) colorName = 'green';
      if (color == const Color(0xFF3B82F6)) colorName = 'blue';

      _players.add(
        Player(
          name: names[i].trim().isEmpty ? 'Player ${i + 1}' : names[i].trim(),
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
    notifyListeners();
  }

  void resetGame() {
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
    notifyListeners();
  }

  void exitToMenu() {
    _gameStarted = false;
    notifyListeners();
  }

  void handleCellTap(int row, int col, {required VoidCallback onAlreadyPlaced}) {
    if (_gameOver) return;
    if (_hasPlacedLetter) {
      onAlreadyPlaced();
      return;
    }

    _board[row][col] = _selectedLetter;
    _hasPlacedLetter = true;
    _passesInARow = 0;

    final allSequences = _findAllSosSequences();
    final unclaimedCount = allSequences.length - _claimedLines.length;

    if (unclaimedCount == 0) {
      if (_earnedExtraTurn) {
        _hasPlacedLetter = false;
        _earnedExtraTurn = false;
      } else {
        _nextTurn();
      }
    }

    _checkGameOver();
    notifyListeners();
  }

  void handleSosClaimed(SosSequence sequence, {required Function(String message, Color color) onClaimed}) {
    if (_gameOver) return;

    final alreadyClaimed = _claimedLines.any(
      (claimed) => claimed.sequence == sequence,
    );
    if (alreadyClaimed) return;

    final currentPlayer = _players[_currentPlayerIndex];
    _claimedLines.add(ClaimedSos(sequence: sequence, player: currentPlayer));
    currentPlayer.score += 1;
    _earnedExtraTurn = true;
    _passesInARow = 0;

    final allSequences = _findAllSosSequences();
    final unclaimedCount = allSequences.length - _claimedLines.length;

    if (unclaimedCount == 0) {
      if (_hasPlacedLetter) {
        _hasPlacedLetter = false;
        _earnedExtraTurn = false;
        onClaimed('${currentPlayer.name} claimed an SOS! Place another letter.', currentPlayer.color);
      }
    } else {
      onClaimed('${currentPlayer.name} claimed an SOS! Claim more or tap "End Turn".', currentPlayer.color);
    }

    _checkGameOver();
    notifyListeners();
  }

  void handleEndTurn() {
    _passesInARow++;
    if (_passesInARow >= _players.length) {
      _gameOver = true;
    } else {
      _nextTurn();
    }
    notifyListeners();
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

  Set<SosSequence> _findAllSosSequences() {
    final Set<SosSequence> sequences = {};
    final List<List<int>> directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
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

  List<Player> getWinners() {
    int maxScore = -1;
    for (var p in _players) {
      if (p.score > maxScore) {
        maxScore = p.score;
      }
    }
    return _players.where((p) => p.score == maxScore).toList();
  }
}
