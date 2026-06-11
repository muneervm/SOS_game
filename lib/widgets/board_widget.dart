import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../size_config.dart';

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
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
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

      final glowPaint = Paint()
        ..color = claimed.player.color.withValues(alpha: 0.4)
        ..strokeWidth = 10.0.w
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0.w)
        ..style = PaintingStyle.stroke;

      canvas.drawLine(start, end, glowPaint);
      canvas.drawLine(start, end, paint);
    }

    if (dragStartOffset != null && dragEndOffset != null) {
      final paint = Paint()
        ..color = activePlayerColor.withValues(alpha: 0.8)
        ..strokeWidth = 3.5.w
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

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
