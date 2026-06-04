import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A1F), Color(0xFF0F1729), Color(0xFF1E3A8A)],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // 일반 별들 (고정)
            ...List.generate(40, (i) {
              final x = (i * 137.5) % 100;
              final y = (i * 97.3) % 100;
              final size = (i % 3 + 1) * 0.6;
              final opacity = (i % 5 + 3) / 10;
              return Positioned(
                left: x / 100 * MediaQuery.of(context).size.width,
                top: y / 100 * MediaQuery.of(context).size.height,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),

            // 반짝이는 별 5개
            ...List.generate(5, (i) {
              final rng = math.Random(i * 31 + 7);
              final x = rng.nextDouble() * 90 + 5;
              final y = rng.nextDouble() * 70 + 5;
              final size = rng.nextDouble() * 1.5 + 1.2;
              // 각자 다른 딜레이와 주기
              final delay = Duration(
                milliseconds: (i * 1300 + rng.nextInt(800)),
              );
              final period = Duration(
                milliseconds: (1800 + i * 700 + rng.nextInt(600)),
              );
              return Positioned(
                left: x / 100 * MediaQuery.of(context).size.width,
                top: y / 100 * MediaQuery.of(context).size.height,
                child: _TwinklingStar(size: size, delay: delay, period: period),
              );
            }),

            IndexedStack(index: _index, children: _pages),
            Positioned(
              left: 24,
              right: 24,
              bottom: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F23),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 0.636,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.50),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      _NavItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: '홈',
                        selected: _index == 0,
                        onTap: () => setState(() => _index = 0),
                      ),
                      _NavItemSvg(
                        svgActive:
                            '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M9.93617 15.4986C9.84691 15.1526 9.66654 14.8368 9.41385 14.5841C9.16115 14.3314 8.84536 14.151 8.49932 14.0617L2.36496 12.4799C2.2603 12.4502 2.16819 12.3872 2.1026 12.3004C2.03701 12.2136 2.00153 12.1078 2.00153 11.999C2.00153 11.8902 2.03701 11.7843 2.1026 11.6975C2.16819 11.6108 2.2603 11.5477 2.36496 11.518L8.49932 9.93518C8.84524 9.84599 9.16095 9.66578 9.41363 9.41327C9.66631 9.16076 9.84675 8.84518 9.93617 8.49933L11.518 2.36497C11.5474 2.2599 11.6104 2.16733 11.6973 2.10139C11.7842 2.03545 11.8904 1.99976 11.9995 1.99976C12.1086 1.99976 12.2147 2.03545 12.3016 2.10139C12.3885 2.16733 12.4515 2.2599 12.4809 2.36497L14.0617 8.49933C14.151 8.84536 14.3314 9.16116 14.5841 9.41385C14.8368 9.66654 15.1526 9.84691 15.4986 9.93618L21.633 11.517C21.7384 11.5461 21.8315 11.609 21.8978 11.6961C21.9641 11.7831 22 11.8895 22 11.999C22 12.1084 21.9641 12.2148 21.8978 12.3019C21.8315 12.3889 21.7384 12.4518 21.633 12.4809L15.4986 14.0617C15.1526 14.151 14.8368 14.3314 14.5841 14.5841C14.3314 14.8368 14.151 15.1526 14.0617 15.4986L12.4799 21.633C12.4505 21.738 12.3875 21.8306 12.3006 21.8965C12.2137 21.9625 12.1076 21.9982 11.9985 21.9982C11.8894 21.9982 11.7832 21.9625 11.6963 21.8965C11.6094 21.8306 11.5464 21.738 11.517 21.633L9.93617 15.4986Z" stroke="white" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M19.9979 2.99969V6.99969" stroke="white" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M21.9981 4.99945H17.9981" stroke="white" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M3.99959 16.9982V18.9982" stroke="white" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M4.99969 17.9981H2.99969" stroke="white" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''',
                        svgInactive:
                            '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<g opacity="0.6">
<path d="M9.93617 15.4986C9.84691 15.1526 9.66654 14.8368 9.41385 14.5841C9.16115 14.3314 8.84536 14.151 8.49932 14.0617L2.36496 12.4799C2.2603 12.4502 2.16819 12.3872 2.1026 12.3004C2.03701 12.2136 2.00153 12.1078 2.00153 11.999C2.00153 11.8902 2.03701 11.7843 2.1026 11.6975C2.16819 11.6108 2.2603 11.5477 2.36496 11.518L8.49932 9.93518C8.84524 9.84599 9.16095 9.66578 9.41363 9.41327C9.66631 9.16076 9.84675 8.84518 9.93617 8.49933L11.518 2.36497C11.5474 2.2599 11.6104 2.16733 11.6973 2.10139C11.7842 2.03545 11.8904 1.99976 11.9995 1.99976C12.1086 1.99976 12.2147 2.03545 12.3016 2.10139C12.3885 2.16733 12.4515 2.2599 12.4809 2.36497L14.0617 8.49933C14.151 8.84536 14.3314 9.16116 14.5841 9.41385C14.8368 9.66654 15.1526 9.84691 15.4986 9.93618L21.633 11.517C21.7384 11.5461 21.8315 11.609 21.8978 11.6961C21.9641 11.7831 22 11.8895 22 11.999C22 12.1084 21.9641 12.2148 21.8978 12.3019C21.8315 12.3889 21.7384 12.4518 21.633 12.4809L15.4986 14.0617C15.1526 14.151 14.8368 14.3314 14.5841 14.5841C14.3314 14.8368 14.151 15.1526 14.0617 15.4986L12.4799 21.633C12.4505 21.738 12.3875 21.8306 12.3006 21.8965C12.2137 21.9625 12.1076 21.9982 11.9985 21.9982C11.8894 21.9982 11.7832 21.9625 11.6963 21.8965C11.6094 21.8306 11.5464 21.738 11.517 21.633L9.93617 15.4986Z" stroke="#BEDBFF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M19.9979 2.99969V6.99969" stroke="#BEDBFF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M21.9981 4.99945H17.9981" stroke="#BEDBFF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M3.99959 16.9982V18.9982" stroke="#BEDBFF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M4.99969 17.9981H2.99969" stroke="#BEDBFF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/>
</g>
</svg>''',
                        label: '랜덤질문',
                        selected: _index == 1,
                        onTap: () => setState(() => _index = 1),
                      ),
                      _NavItem(
                        icon: Icons.wb_sunny_outlined,
                        activeIcon: Icons.wb_sunny,
                        label: '오늘의 운세',
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
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 반짝이는 별 위젯
// ──────────────────────────────────────────────
class _TwinklingStar extends StatefulWidget {
  final double size;
  final Duration delay;
  final Duration period;

  const _TwinklingStar({
    required this.size,
    required this.delay,
    required this.period,
  });

  @override
  State<_TwinklingStar> createState() => _TwinklingStarState();
}

class _TwinklingStarState extends State<_TwinklingStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.period);

    // 딜레이 후 시작
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });

    // 0.05 ~ 1.0 사이로 반짝임 (완전히 사라지지 않게)
    _anim = Tween<double>(
      begin: 0.05,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(_anim.value * 0.8),
                blurRadius: widget.size * 2,
                spreadRadius: widget.size * 0.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 네비게이션 위젯 (기존 유지)
// ──────────────────────────────────────────────
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? activeIcon : icon,
              size: 24,
              color: selected ? Colors.white : AppColors.inkSubtle,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.inkSubtle,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemSvg extends StatelessWidget {
  const _NavItemSvg({
    required this.svgActive,
    required this.svgInactive,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String svgActive;
  final String svgInactive;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.string(
              selected ? svgActive : svgInactive,
              width: 24,
              height: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.inkSubtle,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
