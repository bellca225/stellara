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

  static const _homeActiveSvg =
      '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M14.9991 20.9988V12.9988C14.9991 12.7336 14.8937 12.4792 14.7062 12.2917C14.5186 12.1041 14.2643 11.9988 13.9991 11.9988H9.99907C9.73385 11.9988 9.4795 12.1041 9.29196 12.2917C9.10443 12.4792 8.99907 12.7336 8.99907 12.9988V20.9988" stroke="#51A2FF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M2.99969 9.99895C2.99963 9.70805 3.06302 9.42063 3.18546 9.15676C3.3079 8.89288 3.48644 8.65889 3.70862 8.47111L10.7079 2.47274C11.0688 2.16768 11.5262 2.00031 11.9988 2.00031C12.4714 2.00031 12.9287 2.16768 13.2896 2.47274L20.2889 8.47111C20.5111 8.65889 20.6896 8.89288 20.8121 9.15676C20.9345 9.42063 20.9979 9.70805 20.9978 9.99895V18.998C20.9978 19.5284 20.7871 20.037 20.4121 20.4121C20.0371 20.7871 19.5284 20.9978 18.998 20.9978H4.99949C4.46911 20.9978 3.96045 20.7871 3.58542 20.4121C3.21039 20.037 2.99969 19.5284 2.99969 18.998V9.99895Z" stroke="#51A2FF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/></svg>''';

  static const _homeInactiveSvg =
      '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M14.9991 20.9988V12.9988C14.9991 12.7336 14.8937 12.4792 14.7062 12.2917C14.5186 12.1041 14.2643 11.9988 13.9991 11.9988H9.99907C9.73385 11.9988 9.4795 12.1041 9.29196 12.2917C9.10443 12.4792 8.99907 12.7336 8.99907 12.9988V20.9988" stroke="#6B8BB5" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M2.99969 9.99895C2.99963 9.70805 3.06302 9.42063 3.18546 9.15676C3.3079 8.89288 3.48644 8.65889 3.70862 8.47111L10.7079 2.47274C11.0688 2.16768 11.5262 2.00031 11.9988 2.00031C12.4714 2.00031 12.9287 2.16768 13.2896 2.47274L20.2889 8.47111C20.5111 8.65889 20.6896 8.89288 20.8121 9.15676C20.9345 9.42063 20.9979 9.70805 20.9978 9.99895V18.998C20.9978 19.5284 20.7871 20.037 20.4121 20.4121C20.0371 20.7871 19.5284 20.9978 18.998 20.9978H4.99949C4.46911 20.9978 3.96045 20.7871 3.58542 20.4121C3.21039 20.037 2.99969 19.5284 2.99969 18.998V9.99895Z" stroke="#6B8BB5" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/></svg>''';

  static const _randomActiveSvg =
      '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M9.93617 15.4986C9.84691 15.1526 9.66654 14.8368 9.41385 14.5841C9.16115 14.3314 8.84536 14.151 8.49932 14.0617L2.36496 12.4799C2.2603 12.4502 2.16819 12.3872 2.1026 12.3004C2.03701 12.2136 2.00153 12.1078 2.00153 11.999C2.00153 11.8902 2.03701 11.7843 2.1026 11.6975C2.16819 11.6108 2.2603 11.5477 2.36496 11.518L8.49932 9.93518C8.84524 9.84599 9.16095 9.66578 9.41363 9.41327C9.66631 9.16076 9.84675 8.84518 9.93617 8.49933L11.518 2.36497C11.5474 2.2599 11.6104 2.16733 11.6973 2.10139C11.7842 2.03545 11.8904 1.99976 11.9995 1.99976C12.1086 1.99976 12.2147 2.03545 12.3016 2.10139C12.3885 2.16733 12.4515 2.2599 12.4809 2.36497L14.0617 8.49933C14.151 8.84536 14.3314 9.16116 14.5841 9.41385C14.8368 9.66654 15.1526 9.84691 15.4986 9.93618L21.633 11.517C21.7384 11.5461 21.8315 11.609 21.8978 11.6961C21.9641 11.7831 22 11.8895 22 11.999C22 12.1084 21.9641 12.2148 21.8978 12.3019C21.8315 12.3889 21.7384 12.4518 21.633 12.4809L15.4986 14.0617C15.1526 14.151 14.8368 14.3314 14.5841 14.5841C14.3314 14.8368 14.151 15.1526 14.0617 15.4986L12.4799 21.633C12.4505 21.738 12.3875 21.8306 12.3006 21.8965C12.2137 21.9625 12.1076 21.9982 11.9985 21.9982C11.8894 21.9982 11.7832 21.9625 11.6963 21.8965C11.6094 21.8306 11.5464 21.738 11.517 21.633L9.93617 15.4986Z" stroke="#51A2FF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M19.9979 2.99969V6.99969" stroke="#51A2FF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M21.9981 4.99945H17.9981" stroke="#51A2FF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M3.99957 16.9982V18.9982" stroke="#51A2FF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M4.99969 17.9981H2.99969" stroke="#51A2FF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/></svg>''';

  static const _randomInactiveSvg =
      '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><g opacity="0.6"><path d="M9.93617 15.4986C9.84691 15.1526 9.66654 14.8368 9.41385 14.5841C9.16115 14.3314 8.84536 14.151 8.49932 14.0617L2.36496 12.4799C2.2603 12.4502 2.16819 12.3872 2.1026 12.3004C2.03701 12.2136 2.00153 12.1078 2.00153 11.999C2.00153 11.8902 2.03701 11.7843 2.1026 11.6975C2.16819 11.6108 2.2603 11.5477 2.36496 11.518L8.49932 9.93518C8.84524 9.84599 9.16095 9.66578 9.41363 9.41327C9.66631 9.16076 9.84675 8.84518 9.93617 8.49933L11.518 2.36497C11.5474 2.2599 11.6104 2.16733 11.6973 2.10139C11.7842 2.03545 11.8904 1.99976 11.9995 1.99976C12.1086 1.99976 12.2147 2.03545 12.3016 2.10139C12.3885 2.16733 12.4515 2.2599 12.4809 2.36497L14.0617 8.49933C14.151 8.84536 14.3314 9.16116 14.5841 9.41385C14.8368 9.66654 15.1526 9.84691 15.4986 9.93618L21.633 11.517C21.7384 11.5461 21.8315 11.609 21.8978 11.6961C21.9641 11.7831 22 11.8895 22 11.999C22 12.1084 21.9641 12.2148 21.8978 12.3019C21.8315 12.3889 21.7384 12.4518 21.633 12.4809L15.4986 14.0617C15.1526 14.151 14.8368 14.3314 14.5841 14.5841C14.3314 14.8368 14.151 15.1526 14.0617 15.4986L12.4799 21.633C12.4505 21.738 12.3875 21.8306 12.3006 21.8965C12.2137 21.9625 12.1076 21.9982 11.9985 21.9982C11.8894 21.9982 11.7832 21.9625 11.6963 21.8965C11.6094 21.8306 11.5464 21.738 11.517 21.633L9.93617 15.4986Z" stroke="#BEDBFF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M19.9979 2.99969V6.99969" stroke="#BEDBFF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M21.9981 4.99945H17.9981" stroke="#BEDBFF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M3.99957 16.9982V18.9982" stroke="#BEDBFF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M4.99969 17.9981H2.99969" stroke="#BEDBFF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/></g></svg>''';

  static const _sunActiveSvg =
      '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M11.9992 15.9991C14.2083 15.9991 15.9992 14.2083 15.9992 11.9991C15.9992 9.79001 14.2083 7.99915 11.9992 7.99915C9.79004 7.99915 7.99918 9.79001 7.99918 11.9991C7.99918 14.2083 9.79004 15.9991 11.9992 15.9991Z" stroke="#51A2FF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M11.9987 1.99982V3.99982" stroke="#51A2FF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M11.9987 19.9979V21.9979" stroke="#51A2FF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M4.92947 4.9295L6.33947 6.3395" stroke="#51A2FF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M17.6582 17.6581L19.0682 19.0681" stroke="#51A2FF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M1.99979 11.9988H3.99979" stroke="#51A2FF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M19.9979 11.9988H21.9979" stroke="#51A2FF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M6.33947 17.6581L4.92947 19.0681" stroke="#51A2FF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M19.0682 4.9295L17.6582 6.3395" stroke="#51A2FF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/></svg>''';

  static const _sunInactiveSvg =
      '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M11.9992 15.9991C14.2083 15.9991 15.9992 14.2083 15.9992 11.9991C15.9992 9.79001 14.2083 7.99915 11.9992 7.99915C9.79004 7.99915 7.99918 9.79001 7.99918 11.9991C7.99918 14.2083 9.79004 15.9991 11.9992 15.9991Z" stroke="#BEDBFF" stroke-opacity="0.6" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M11.9987 1.99982V3.99982" stroke="#BEDBFF" stroke-opacity="0.6" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M11.9987 19.9979V21.9979" stroke="#BEDBFF" stroke-opacity="0.6" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M4.92947 4.9295L6.33947 6.3395" stroke="#BEDBFF" stroke-opacity="0.6" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M17.6582 17.6581L19.0682 19.0681" stroke="#BEDBFF" stroke-opacity="0.6" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M1.99979 11.9988H3.99979" stroke="#BEDBFF" stroke-opacity="0.6" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M19.9979 11.9988H21.9979" stroke="#BEDBFF" stroke-opacity="0.6" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M6.33947 17.6581L4.92947 19.0681" stroke="#BEDBFF" stroke-opacity="0.6" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M19.0682 4.9295L17.6582 6.3395" stroke="#BEDBFF" stroke-opacity="0.6" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/></svg>''';

  static const _personActiveSvg =
      '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M18.998 20.9978V18.998C18.998 17.9372 18.5766 16.9199 17.8266 16.1699C17.0765 15.4198 16.0592 14.9984 14.9984 14.9984H8.99906C7.93831 14.9984 6.921 15.4198 6.17093 16.1699C5.42086 16.9199 4.99948 17.9372 4.99948 18.998V20.9978" stroke="#51A2FF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M11.9992 10.9997C14.2083 10.9997 15.9992 9.20883 15.9992 6.99969C15.9992 4.79056 14.2083 2.99969 11.9992 2.99969C9.79004 2.99969 7.99918 4.79056 7.99918 6.99969C7.99918 9.20883 9.79004 10.9997 11.9992 10.9997Z" stroke="#51A2FF" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/></svg>''';

  static const _personInactiveSvg =
      '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M18.998 20.9978V18.998C18.998 17.9372 18.5766 16.9199 17.8266 16.1699C17.0765 15.4198 16.0592 14.9984 14.9984 14.9984H8.99906C7.93831 14.9984 6.921 15.4198 6.17093 16.1699C5.42086 16.9199 4.99948 17.9372 4.99948 18.998V20.9978" stroke="#BEDBFF" stroke-opacity="0.6" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/><path d="M11.9992 10.9997C14.2083 10.9997 15.9992 9.20883 15.9992 6.99969C15.9992 4.79056 14.2083 2.99969 11.9992 2.99969C9.79004 2.99969 7.99918 4.79056 7.99918 6.99969C7.99918 9.20883 9.79004 10.9997 11.9992 10.9997Z" stroke="#BEDBFF" stroke-opacity="0.6" stroke-width="1.99979" stroke-linecap="round" stroke-linejoin="round"/></svg>''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: IndexedStack(index: _index, children: _pages),
          ),
          Positioned(
            left: 16.5,
            right: 16.5,
            bottom: 20,
            child: Container(
              height: 76,
              padding: const EdgeInsets.only(
                top: 8.5,
                left: 16.5,
                bottom: 0.636,
                right: 16.5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A1F),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: const Color(0x1AFFFFFF),
                  width: 0.636,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x801E3A8A),
                    offset: Offset(0, 5),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  _SvgNavItem(
                    activeSvg: _homeActiveSvg,
                    inactiveSvg: _homeInactiveSvg,
                    label: '홈',
                    selected: _index == 0,
                    onTap: () => setState(() => _index = 0),
                  ),
                  _SvgNavItem(
                    activeSvg: _randomActiveSvg,
                    inactiveSvg: _randomInactiveSvg,
                    label: '랜덤질문',
                    selected: _index == 1,
                    onTap: () => setState(() => _index = 1),
                  ),
                  _SvgNavItem(
                    activeSvg: _sunActiveSvg,
                    inactiveSvg: _sunInactiveSvg,
                    label: '오늘의 운세',
                    selected: _index == 2,
                    onTap: () => setState(() => _index = 2),
                  ),
                  _SvgNavItem(
                    activeSvg: _personActiveSvg,
                    inactiveSvg: _personInactiveSvg,
                    label: '마이페이지',
                    selected: _index == 3,
                    onTap: () => setState(() => _index = 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SvgNavItem extends StatelessWidget {
  const _SvgNavItem({
    required this.activeSvg,
    required this.inactiveSvg,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String activeSvg;
  final String inactiveSvg;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.string(
              selected ? activeSvg : inactiveSvg,
              width: 24,
              height: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0x99BEDBFF),
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
