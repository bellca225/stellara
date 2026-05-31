import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../content/presentation/random_question_screen.dart';
import '../home/presentation/main_home_screen.dart';
import '../horoscope/presentation/today_screen.dart';
import '../profile/presentation/my_page_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _pages = <Widget>[
    MainHomeScreen(),
    RandomQuestionScreen(),
    TodayScreen(),
    MyPageScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          decoration: const BoxDecoration(
            color: AppColors.paper,
            border: Border(
              top: BorderSide(color: AppColors.line),
            ),
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: '홈',
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: '랜덤질문',
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
              _NavItem(
                icon: Icons.wb_sunny_outlined,
                activeIcon: Icons.wb_sunny,
                label: '오늘의운세',
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: '마이페이지',
                selected: _index == 3,
                onTap: () => setState(() => _index = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? AppColors.paper : AppColors.inkSubtle;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected ? AppColors.ink : AppColors.paper,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected ? AppColors.ink : AppColors.inkSubtle,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  selected ? activeIcon : icon,
                  size: 18,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.ink : AppColors.inkMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
