import 'package:flutter/material.dart';

class Player {
  final String name;
  final Color color;
  final String colorName; // 'red', 'green', 'blue'
  int score;

  Player({
    required this.name,
    required this.color,
    required this.colorName,
    this.score = 0,
  });

  Player copyWith({
    String? name,
    Color? color,
    String? colorName,
    int? score,
  }) {
    return Player(
      name: name ?? this.name,
      color: color ?? this.color,
      colorName: colorName ?? this.colorName,
      score: score ?? this.score,
    );
  }
}

class SosSequence {
  final int r1, c1;
  final int rMid, cMid;
  final int r2, c2;

  SosSequence(int row1, int col1, int row2, int col2)
      : r1 = row1 < row2 || (row1 == row2 && col1 < col2) ? row1 : row2,
        c1 = row1 < row2 || (row1 == row2 && col1 < col2) ? col1 : col2,
        r2 = row1 < row2 || (row1 == row2 && col1 < col2) ? row2 : row1,
        c2 = row1 < row2 || (row1 == row2 && col1 < col2) ? col2 : col1,
        rMid = (row1 + row2) ~/ 2,
        cMid = (col1 + col2) ~/ 2;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SosSequence &&
          runtimeType == other.runtimeType &&
          r1 == other.r1 &&
          c1 == other.c1 &&
          r2 == other.r2 &&
          c2 == other.c2;

  @override
  int get hashCode => Object.hash(r1, c1, r2, c2);

  @override
  String toString() {
    return 'SosSequence(($r1,$c1) -> ($rMid,$cMid) -> ($r2,$c2))';
  }
}

class ClaimedSos {
  final SosSequence sequence;
  final Player player;

  ClaimedSos({
    required this.sequence,
    required this.player,
  });
}
