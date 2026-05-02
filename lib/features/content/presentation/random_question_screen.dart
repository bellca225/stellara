import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';

class RandomQuestionScreen extends StatelessWidget {
  const RandomQuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            const WireframeHeader('CONTENT-001 · 랜덤 질문'),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '랜덤 질문',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '이 화면은 나중에 AI가 질문을 만들어 주는 자리예요. 지금은 화면 흐름과 배치만 먼저 잡아두었습니다.',
              style: TextStyle(
                color: AppColors.inkMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _QuestionCard(
              badge: '질문 1',
              question: '요즘 내가 가장 오래 붙잡고 있는 감정은 무엇일까요?',
            ),
            const SizedBox(height: AppSpacing.md),
            const _QuestionCard(
              badge: '질문 2',
              question: '친해지고 싶은 사람에게 먼저 건네고 싶은 말은 무엇인가요?',
            ),
            const SizedBox(height: AppSpacing.md),
            const _QuestionCard(
              badge: '질문 3',
              question: '이번 주의 나를 가장 잘 설명하는 장면은 어떤 모습인가요?',
            ),
            const SizedBox(height: AppSpacing.md),
            const _QuestionCard(
              badge: '직접 만든 질문',
              question: '내가 스스로에게 묻고 싶은 질문을 여기에 적게 됩니다.',
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: () {},
              child: const Text('질문 생성 연결 예정'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.badge,
    required this.question,
  });

  final String badge;
  final String question;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            badge,
            style: const TextStyle(
              color: AppColors.inkMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            question,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
