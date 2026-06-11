import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../widgets/board_widget.dart';
import '../widgets/game_over_overlay.dart';
import '../size_config.dart';

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GameController>(context);
    final activePlayer = controller.activePlayer;

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
          controller.exitToMenu();
        }
      },
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                                  controller.exitToMenu();
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
                                  controller.resetGame();
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
                      children: controller.players.asMap().entries.map((entry) {
                        int index = entry.key;
                        final player = entry.value;
                        bool isActive = index == controller.currentPlayerIndex;

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
                      controller.hasPlacedLetter
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
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: SosGameBoard(
                        gridSize: controller.gridSize,
                        board: controller.board,
                        claimedLines: controller.claimedLines,
                        activePlayerColor: activePlayer.color,
                        onCellTap: (row, col) {
                          controller.handleCellTap(
                            row,
                            col,
                            onAlreadyPlaced: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'You have already placed a letter. Claim SOSs or tap "End Turn".',
                                  ),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          );
                        },
                        onSosClaimed: (sequence) {
                          controller.handleSosClaimed(
                            sequence,
                            onClaimed: (message, color) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor: color,
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Opacity(
                      opacity: controller.hasPlacedLetter ? 0.4 : 1.0,
                      child: Container(
                        padding: EdgeInsets.all(4.sp),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16.sp),
                        ),
                        child: Row(
                          children: ['S', 'O'].map((letter) {
                            final isSelected = controller.selectedLetter == letter;
                            return GestureDetector(
                              onTap: controller.hasPlacedLetter
                                  ? null
                                  : () => controller.selectLetter(letter),
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
                    if (controller.hasPlacedLetter)
                      ElevatedButton(
                        onPressed: controller.handleEndTurn,
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
          if (controller.gameOver) const GameOverOverlay(),
        ],
      ),
    );
  }
}
