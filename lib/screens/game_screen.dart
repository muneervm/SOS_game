import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../size_config.dart';
import 'board_screen.dart';
import 'setup_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final controller = Provider.of<GameController>(context);

    return Scaffold(
      body: SafeArea(
        child: controller.gameStarted
            ? const BoardScreen()
            : const SetupScreen(),
      ),
    );
  }
}
