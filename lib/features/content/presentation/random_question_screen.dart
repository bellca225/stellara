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
  String _question = '김민수와 함께 여행 가면?';
  String _answer =
      '함께 여행을 가면 즉흥적이고 모험적인 여정이 될 것입니다. 계획에 없던 장소를 발견하여 잊지 못할 추억을 만들 수 있습니다.';
  bool _showAnswer = true;

  final _questions = [
    '함께 가장 해보고 싶은 여행지는?',
    '서로에게 가장 고마운 순간은?',
    '10년 후 우리는 어떤 모습일까?',
    '함께하면 가장 즐거운 활동은?',
    '서로의 가장 닮은 점은 무엇일까?',
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
                  const ScreenCodeChip(code: 'CONTENT-001', label: '랜덤 질문'),
                  const SizedBox(height: 20),
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
                    '친구를 선택하고 점성술 질문을 받아보세요',
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // 친구 선택
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
                        items: ['김민수', '박서연', '이지원', '최유나']
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
                  // 질문 카드
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
                          ? '$_selectedFriendName와 $_question'
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
                  // 점성술 답변
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
                                '점성술 답변',
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
                  // 버튼들
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
