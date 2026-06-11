import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../size_config.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late List<TextEditingController> _nameControllers;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final controller = Provider.of<GameController>(context);
      _nameControllers = List.generate(
        3,
        (i) => TextEditingController(
          text: i < controller.savedPlayerNames.length
              ? controller.savedPlayerNames[i]
              : 'Player ${i + 1}',
        ),
      );
      _initialized = true;
    }
  }

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GameController>(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                      final isSelected = controller.gridSize == size;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.0.w),
                          child: InkWell(
                            onTap: () => controller.setGridSize(size),
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
                      final isSelected = controller.playerCount == count;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.0.w),
                          child: InkWell(
                            onTap: () => controller.setPlayerCount(count),
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
                    itemCount: controller.playerCount,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 16.h),
                    itemBuilder: (context, playerIndex) {
                      final assignedColorIndex =
                          controller.selectedColorIndices[playerIndex];
                      final assignedColor =
                          controller.availableColors[assignedColorIndex];

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
                              Row(
                                children: List.generate(controller.availableColors.length, (
                                  colorIndex,
                                ) {
                                  final color = controller.availableColors[colorIndex];
                                  final isCurrentlySelectedByThisPlayer =
                                      assignedColorIndex == colorIndex;
                                  bool isTakenByAnother = false;
                                  for (int i = 0; i < controller.playerCount; i++) {
                                    if (i != playerIndex &&
                                        controller.selectedColorIndices[i] ==
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
                                              controller.updateColorIndex(
                                                playerIndex,
                                                colorIndex,
                                              );
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
          ElevatedButton(
            onPressed: () {
              final names = _nameControllers.map((c) => c.text).toList();
              controller.startGame(names);
            },
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
}
