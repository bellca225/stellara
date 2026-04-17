import 'package:flutter/material.dart';

void main() {
  runApp(const StellaraApp());
}

const _ink = Color(0xFF151A1D);
const _muted = Color(0xFF66726E);
const _paper = Color(0xFFF7F8F3);
const _panel = Colors.white;
const _line = Color(0xFFDDE6E1);
const _teal = Color(0xFF0F766E);
const _coral = Color(0xFFE15B46);
const _gold = Color(0xFFF0B429);
const _sage = Color(0xFFE4F1E1);
const _lilac = Color(0xFFE5DDF5);
const _mist = Color(0xFFE9EFF7);

class StellaraApp extends StatelessWidget {
  const StellaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stellara',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _teal,
          primary: _teal,
          secondary: _coral,
          tertiary: _gold,
          surface: _paper,
        ),
        scaffoldBackgroundColor: _paper,
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: _ink,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1.08,
          ),
          headlineMedium: TextStyle(
            color: _ink,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
          titleLarge: TextStyle(
            color: _ink,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
          titleMedium: TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(color: _ink, fontSize: 16, height: 1.4),
          bodyMedium: TextStyle(color: _muted, fontSize: 14, height: 1.35),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _goOnboarding(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
          children: [
            const _ScreenCode(code: 'LOGIN-001', label: '카카오 로그인'),
            const SizedBox(height: 34),
            const _BrandMark(size: 72),
            const SizedBox(height: 22),
            Text(
              '내 별자리 차트로\n관계와 하루를 읽어요',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              '출생 정보로 나의 행성을 만들고 친구와의 궁합, 오늘의 운세, 랜덤 질문을 가볍게 확인합니다.',
              style: TextStyle(color: _muted, fontSize: 16, height: 1.45),
            ),
            const SizedBox(height: 30),
            const _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle('API 연결 구상'),
                  SizedBox(height: 14),
                  _IntegrationRow(
                    icon: Icons.chat_bubble_outline,
                    title: '카카오 OAuth',
                    detail: '로그인 성공 후 사용자 고유 ID 발급',
                  ),
                  _IntegrationRow(
                    icon: Icons.lock_outline,
                    title: '보안 저장',
                    detail: 'JWT와 토큰은 secure storage에 저장',
                  ),
                  _IntegrationRow(
                    icon: Icons.cloud_queue,
                    title: '차트 생성',
                    detail: '출생지 좌표 변환 후 점성술 API 호출',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _KakaoButton(onPressed: () => _goOnboarding(context)),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AppShell()),
                );
              },
              child: const Text('목업 데이터로 바로 둘러보기'),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nicknameController = TextEditingController(text: '물병자리의 꿈');
  final _dateController = TextEditingController(text: '1995-02-15');
  final _timeController = TextEditingController(text: '14:30');
  final _placeController = TextEditingController(text: '서울특별시');

  @override
  void dispose() {
    _nicknameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  void _startApp() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
          children: [
            const _ScreenCode(code: 'ONBOARDING-001', label: '출생 정보 입력'),
            const SizedBox(height: 24),
            Text(
              '차트를 만들기 위한\n첫 정보를 알려주세요',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              '실제 연결 단계에서는 출생지를 위도와 경도로 변환하고, 점성술 계산 결과를 Firestore에 저장합니다.',
              style: TextStyle(color: _muted, fontSize: 15, height: 1.45),
            ),
            const SizedBox(height: 24),
            _Panel(
              child: Column(
                children: [
                  _InputField(
                    label: '닉네임',
                    icon: Icons.badge_outlined,
                    controller: _nicknameController,
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    label: '생년월일',
                    icon: Icons.calendar_today_outlined,
                    controller: _dateController,
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    label: '출생 시간',
                    icon: Icons.schedule_outlined,
                    controller: _timeController,
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    label: '출생지',
                    icon: Icons.place_outlined,
                    controller: _placeController,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _Panel(
              background: _mist,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle('생성 예정 데이터'),
                  SizedBox(height: 12),
                  _PillRow(items: ['친구 코드 AQU2024', '나탈 차트', 'Big 3']),
                  SizedBox(height: 12),
                  Text(
                    'Google Geocoding API → Prokerala Astrology API → Firestore charts 컬렉션 순서로 연결할 예정입니다.',
                    style: TextStyle(color: _muted, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _PrimaryButton(
              label: '차트 생성하고 시작',
              icon: Icons.auto_awesome,
              onPressed: _startApp,
            ),
          ],
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const RandomQuestionScreen(),
      const TodayFortuneScreen(),
      const MyPageScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        backgroundColor: Colors.white,
        indicatorColor: _sage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.question_answer_outlined),
            selectedIcon: Icon(Icons.question_answer),
            label: '랜덤질문',
          ),
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: '오늘운세',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _Page(
      code: 'MAIN-001',
      title: '나의 우주',
      subtitle: '물병자리',
      trailing: IconButton(
        tooltip: '친구 관리',
        onPressed: () => _push(context, const FriendScreen()),
        icon: const Icon(Icons.group_add_outlined),
      ),
      children: [
        _PlanetOrbit(
          centerLabel: '나',
          partnerLabel: '박',
          caption: '함께 뜬 행성',
          onPlanetTap: () => _push(context, const AstrologyScreen()),
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: '친구 관리',
          icon: Icons.people_outline,
          onPressed: () => _push(context, const FriendScreen()),
        ),
        const SizedBox(height: 16),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('나의 Big 3'),
              const SizedBox(height: 12),
              const _PillRow(items: ['태양: 물병자리', '달: 게자리', '상승: 사자자리']),
              const SizedBox(height: 16),
              _SecondaryButton(
                label: '상세 보기',
                icon: Icons.read_more_outlined,
                onPressed: () => _push(context, const AstrologyScreen()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: _SectionTitle('즐겨찾기 친구')),
            TextButton(
              onPressed: () => _push(context, const FriendScreen()),
              child: const Text('편집'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._favoriteFriends.map(
          (friend) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FriendPreviewTile(
              friend: friend,
              onTap: () => _push(context, MatchScreen(friend: friend)),
            ),
          ),
        ),
      ],
    );
  }
}

class AstrologyScreen extends StatelessWidget {
  const AstrologyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DetailPage(
      code: 'ASTROLOGY-001',
      title: '점성술 분석',
      children: [
        Center(
          child: Container(
            width: 174,
            height: 174,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _line, width: 3),
            ),
            child: Center(
              child: Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _line, width: 2),
                ),
                child: const Center(
                  child: Text(
                    '출생 차트\n1995-02-15',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, height: 1.35),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        const _SectionTitle('상세 분석'),
        const SizedBox(height: 12),
        const _AnalysisCard(
          title: '태양 in 물병자리',
          detail: '독립적이고 창의적인 성향을 가지고 있습니다.',
          accent: _teal,
        ),
        const _AnalysisCard(
          title: '달 in 게자리',
          detail: '감정적으로 민감하고 직관적입니다.',
          accent: _coral,
        ),
        const _AnalysisCard(
          title: '수성 in 물병자리',
          detail: '논리적이고 분석적인 사고를 합니다.',
          accent: _gold,
        ),
        const _AnalysisCard(
          title: '금성 in 염소자리',
          detail: '진지하고 헌신적인 사랑을 추구합니다.',
          accent: _lilac,
        ),
      ],
    );
  }
}

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  final Set<String> _favoriteIds = {'friend-1', 'friend-2', 'friend-3'};

  void _toggleFavorite(String id) {
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
        return;
      }

      if (_favoriteIds.length < 3) {
        _favoriteIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _DetailPage(
      code: 'FRIEND-001',
      title: '친구 관리',
      children: [
        _Panel(
          background: _mist,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('친구 요청'),
              const SizedBox(height: 12),
              _RequestTile(name: '서윤', code: 'SYU1204', onAccept: () {}),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('랜덤 코드 검색'),
              const SizedBox(height: 12),
              TextField(
                decoration: _inputDecoration(
                  label: '친구 코드',
                  icon: Icons.search,
                  suffix: const Text('검색'),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '요청 후 상대방이 수락하면 친구 목록에 추가됩니다.',
                style: TextStyle(color: _muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '친구 목록 · 즐겨찾기 ${_favoriteIds.length}/3',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        ..._allFriends.map(
          (friend) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FriendManageTile(
              friend: friend,
              favorite: _favoriteIds.contains(friend.id),
              onFavorite: () => _toggleFavorite(friend.id),
              onMatch: () => _push(context, MatchScreen(friend: friend)),
            ),
          ),
        ),
      ],
    );
  }
}

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _Page(
      code: 'MYPAGE-001',
      title: '마이페이지',
      subtitle: '물병자리의 꿈',
      children: [
        const Center(child: _ZodiacAvatar(label: '물', size: 112)),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            '물병자리의 꿈',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ),
        const Center(
          child: Text('물병자리', style: TextStyle(color: _muted)),
        ),
        const SizedBox(height: 20),
        const _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('내 친구 코드', style: TextStyle(color: _muted)),
              SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'AQU2024',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(Icons.copy_outlined, color: _muted),
                ],
              ),
              Text('친구에게 이 코드를 공유하세요', style: TextStyle(color: _muted)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _SectionTitle('출생 정보'),
        const SizedBox(height: 10),
        const _Panel(
          child: Column(
            children: [
              _InfoRow(label: '생년월일', value: '1995-02-15'),
              Divider(color: _line),
              _InfoRow(label: '출생 시간', value: '14:30'),
              Divider(color: _line),
              _InfoRow(label: '출생지', value: '서울특별시'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SecondaryButton(
          label: '출생 정보 및 닉네임 수정',
          icon: Icons.edit_outlined,
          onPressed: () {},
        ),
        const SizedBox(height: 10),
        _PrimaryButton(label: '차트 재생성', icon: Icons.refresh, onPressed: () {}),
        const SizedBox(height: 10),
        _OutlineWideButton(
          label: '로그아웃',
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }
}

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key, required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    return _DetailPage(
      code: 'MATCH-001',
      title: '${friend.name}님과 궁합',
      children: [
        _Panel(
          background: _sage,
          child: Column(
            children: [
              const Text('총 궁합 점수', style: TextStyle(color: _muted)),
              const SizedBox(height: 8),
              const Text(
                '87%',
                style: TextStyle(fontSize: 54, fontWeight: FontWeight.w900),
              ),
              const Text(
                '다른 속도로 같은 방향을 보는 조합입니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _ScoreBar(label: '감정', score: 92, color: _coral),
        const _ScoreBar(label: '대화', score: 78, color: _teal),
        const _ScoreBar(label: '연애', score: 86, color: _gold),
        const SizedBox(height: 12),
        const _Panel(
          child: Text(
            '감정 표현은 부드럽고, 대화는 솔직할수록 좋아집니다. 서로의 독립성을 존중하면 오래 안정적인 관계가 됩니다.',
            style: TextStyle(color: _muted, height: 1.45),
          ),
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: 'SNS 공유',
          icon: Icons.ios_share_outlined,
          onPressed: () => _push(context, const ShareResultScreen()),
        ),
      ],
    );
  }
}

class RandomQuestionScreen extends StatelessWidget {
  const RandomQuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _Page(
      code: 'CONTENT-001',
      title: '랜덤 질문',
      subtitle: '오늘 열어볼 대화',
      children: [
        const _QuestionCard(
          tag: 'AI 생성',
          question: '오늘 내가 가장 솔직하게 말하고 싶은 감정은 무엇일까요?',
          accent: _sage,
        ),
        const _QuestionCard(
          tag: 'AI 생성',
          question: '친구에게 고마움을 전한다면 어떤 장면부터 떠오르나요?',
          accent: _mist,
        ),
        const _QuestionCard(
          tag: 'AI 생성',
          question: '이번 주에 나를 조금 더 가볍게 만드는 선택은 무엇일까요?',
          accent: Color(0xFFFFF1D6),
        ),
        const _QuestionCard(
          tag: '사용자 생성',
          question: '내 차트에서 가장 닮고 싶은 행성은 무엇인가요?',
          accent: _lilac,
        ),
        const SizedBox(height: 10),
        _PrimaryButton(
          label: 'SNS 공유',
          icon: Icons.ios_share_outlined,
          onPressed: () => _push(context, const ShareResultScreen()),
        ),
      ],
    );
  }
}

class TodayFortuneScreen extends StatelessWidget {
  const TodayFortuneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _Page(
      code: 'TODAY-001',
      title: '오늘의 운세',
      subtitle: '작게 맞추는 하루의 리듬',
      children: [
        const _Panel(
          background: Color(0xFFFFF1D6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('오늘의 한 줄'),
              SizedBox(height: 10),
              Text(
                '낯선 제안 안에 좋은 힌트가 숨어 있습니다. 결정은 천천히 해도 괜찮아요.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.42,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('오늘의 감정'),
              SizedBox(height: 12),
              _MoodRow(
                icon: Icons.water_drop_outlined,
                label: '차분함',
                detail: '감정을 정리하기 좋은 날',
              ),
              _MoodRow(
                icon: Icons.bolt_outlined,
                label: '집중력',
                detail: '오후에 더 또렷해집니다',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _Panel(
          background: _sage,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('행운 요소'),
              SizedBox(height: 12),
              _PillRow(items: ['숫자 7', '색상 코랄', '장소 책방']),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: '운세 공유',
          icon: Icons.ios_share_outlined,
          onPressed: () => _push(context, const ShareResultScreen()),
        ),
      ],
    );
  }
}

class ShareResultScreen extends StatelessWidget {
  const ShareResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DetailPage(
      code: 'SHARE-001',
      title: '결과 공유',
      children: [
        const _Panel(
          background: _mist,
          child: Column(
            children: [
              _BrandMark(size: 64),
              SizedBox(height: 16),
              Text(
                '오늘의 Stellara',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 8),
              Text(
                '낯선 제안 안에 좋은 힌트가 숨어 있습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SecondaryButton(
          label: '이미지 저장',
          icon: Icons.download_outlined,
          onPressed: () {},
        ),
        const SizedBox(height: 10),
        _PrimaryButton(
          label: 'SNS 공유',
          icon: Icons.ios_share_outlined,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.code,
    required this.title,
    required this.children,
    this.subtitle,
    this.trailing,
  });

  final String code;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
        children: [
          _ScreenCode(code: code, label: subtitle ?? title),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: const TextStyle(color: _muted, fontSize: 16),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
  }
}

class _DetailPage extends StatelessWidget {
  const _DetailPage({
    required this.code,
    required this.title,
    required this.children,
  });

  final String code;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _paper,
        surfaceTintColor: _paper,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          children: [
            _ScreenCode(code: code, label: title),
            const SizedBox(height: 22),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ScreenCode extends StatelessWidget {
  const _ScreenCode({required this.code, required this.label});

  final String code;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            code,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _muted, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.auto_awesome, color: Colors.white, size: size * 0.52),
    );
  }
}

class _KakaoButton extends StatelessWidget {
  const _KakaoButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFEE500),
          foregroundColor: _ink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.chat_bubble, size: 20),
        label: const Text(
          '카카오로 시작하기',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: _ink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _OutlineWideButton extends StatelessWidget {
  const _OutlineWideButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: _ink,
          side: const BorderSide(color: _ink, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.background = _panel,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final Color background;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.icon,
    required this.controller,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    suffixIcon: suffix == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(widthFactor: 1, child: suffix),
          ),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _teal, width: 2),
    ),
  );
}

class _IntegrationRow extends StatelessWidget {
  const _IntegrationRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _sage,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _teal, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(detail, style: const TextStyle(color: _muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillRow extends StatelessWidget {
  const _PillRow({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) => _Pill(item)).toList(),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
      ),
    );
  }
}

class _PlanetOrbit extends StatelessWidget {
  const _PlanetOrbit({
    required this.centerLabel,
    required this.partnerLabel,
    required this.caption,
    required this.onPlanetTap,
  });

  final String centerLabel;
  final String partnerLabel;
  final String caption;
  final VoidCallback onPlanetTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 292,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 256,
            height: 256,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _line, width: 2),
            ),
          ),
          Container(
            width: 146,
            height: 146,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _line, width: 2),
            ),
          ),
          _OrbitBody(
            label: centerLabel,
            size: 82,
            color: Colors.white,
            borderColor: _teal,
          ),
          Positioned(
            right: 86,
            top: 100,
            child: _OrbitBody(
              label: partnerLabel,
              size: 66,
              color: _paper,
              borderColor: _coral,
            ),
          ),
          Positioned(
            left: 42,
            top: 28,
            child: _PlanetChip(label: '태양', color: _gold, onTap: onPlanetTap),
          ),
          Positioned(
            right: 34,
            bottom: 62,
            child: _PlanetChip(label: '달', color: _coral, onTap: onPlanetTap),
          ),
          Positioned(
            left: 70,
            bottom: 30,
            child: _PlanetChip(label: '수성', color: _teal, onTap: onPlanetTap),
          ),
          Positioned(
            bottom: 78,
            child: Text(
              caption,
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitBody extends StatelessWidget {
  const _OrbitBody({
    required this.label,
    required this.size,
    required this.color,
    required this.borderColor,
  });

  final String label;
  final double size;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _PlanetChip extends StatelessWidget {
  const _PlanetChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ZodiacAvatar extends StatelessWidget {
  const _ZodiacAvatar({required this.label, this.size = 62});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: _line, width: 2),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(fontSize: size * 0.26, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _FriendPreviewTile extends StatelessWidget {
  const _FriendPreviewTile({required this.friend, required this.onTap});

  final Friend friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            _ZodiacAvatar(label: friend.sign.substring(0, 1), size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${friend.sign} · ${friend.code}',
                    style: const TextStyle(color: _muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.favorite, color: _coral),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: _muted),
          ],
        ),
      ),
    );
  }
}

class _FriendManageTile extends StatelessWidget {
  const _FriendManageTile({
    required this.friend,
    required this.favorite,
    required this.onFavorite,
    required this.onMatch,
  });

  final Friend friend;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onMatch;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              _ZodiacAvatar(label: friend.sign.substring(0, 1), size: 50),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${friend.sign} · ${friend.code}',
                      style: const TextStyle(color: _muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onFavorite,
                icon: Icon(
                  favorite ? Icons.star : Icons.star_border,
                  color: favorite ? _gold : _muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SecondaryButton(
            label: '궁합 보기',
            icon: Icons.favorite_border,
            onPressed: onMatch,
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.name,
    required this.code,
    required this.onAccept,
  });

  final String name;
  final String code;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _ZodiacAvatar(label: '쌍', size: 46),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$name · $code',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _teal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onAccept,
          child: const Text('수락'),
        ),
      ],
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.title,
    required this.detail,
    required this.accent,
  });

  final String title;
  final String detail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Panel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 58,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(detail, style: const TextStyle(color: _muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.tag,
    required this.question,
    required this.accent,
  });

  final String tag;
  final String question;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Panel(
        background: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Pill(tag),
            const SizedBox(height: 14),
            Text(
              question,
              style: const TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodRow extends StatelessWidget {
  const _MoodRow({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: _teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(detail, style: const TextStyle(color: _muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '$score%',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 10,
                backgroundColor: const Color(0xFFE6ECEA),
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: _muted)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

void _push(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

class Friend {
  const Friend({
    required this.id,
    required this.name,
    required this.sign,
    required this.code,
  });

  final String id;
  final String name;
  final String sign;
  final String code;
}

const _favoriteFriends = [
  Friend(id: 'friend-1', name: '하린', sign: '사자자리', code: 'LEO731'),
  Friend(id: 'friend-2', name: '준서', sign: '천칭자리', code: 'LIB204'),
  Friend(id: 'friend-3', name: '민아', sign: '쌍둥이자리', code: 'GEM512'),
];

const _allFriends = [
  ..._favoriteFriends,
  Friend(id: 'friend-4', name: '도윤', sign: '염소자리', code: 'CAP810'),
];
