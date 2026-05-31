import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';
import '../../auth/application/auth_providers.dart';

class RandomQuestionScreen extends ConsumerStatefulWidget {
  const RandomQuestionScreen({super.key});

  @override
  ConsumerState<RandomQuestionScreen> createState() =>
      _RandomQuestionScreenState();
}

class _RandomQuestionScreenState extends ConsumerState<RandomQuestionScreen> {
  String? _selectedFriendName;
  String _question = '김민수는 어떤 행동 패턴?';
  String _answer =
      '어떤 행동 패턴은 매우 능동적이고 진취적인 성향을 가집니다. 새로운 아이디어를 탐색하여 더욱 나은 미래를 만들어 나갑니다.';
  bool _showAnswer = true;

  final _questions = [
    '어떤 매력 포인트가 있을까?',
    '지금으로부터 얼마나 가까울까?',
    '10년 후의 모습은 어떨까?',
    '어떤 분야에서 재능이 있을까?',
    '지금 가장 바라는 것은 무엇일까?',
  ];

  void _newQuestion() {
    setState(() {
      _question = _questions[DateTime.now().millisecond % _questions.length];
      _showAnswer = false;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showAnswer = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StarBackground(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    '랜덤 질문',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '친구를 선택하고 함께하는 질문을 탐색해보세요',
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.glass,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFriendName,
                        hint: const Text(
                          '친구 선택',
                          style: TextStyle(color: AppColors.inkSubtle),
                        ),
                        dropdownColor: const Color(0xFF0D1B3E),
                        style: const TextStyle(color: Colors.white),
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.inkMuted,
                        ),
                        items: ['김민수', '이지은', '박서준', '최유진']
                            .map(
                              (name) => DropdownMenuItem(
                                value: name,
                                child: Text(name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedFriendName = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.glass,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Text(
                      _selectedFriendName != null
                          ? '$_selectedFriendName는 $_question'
                          : _question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_showAnswer)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.glass,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: AppColors.primaryLight,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '별자리 해석',
                                style: TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _answer,
                            style: const TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _newQuestion,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('새 질문'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: AppColors.glassBorder,
                            ),
                            backgroundColor: AppColors.glass,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('공유하기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
