import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';
import '../application/question_providers.dart';

class RandomQuestionScreen extends ConsumerStatefulWidget {
  const RandomQuestionScreen({super.key});

  @override
  ConsumerState<RandomQuestionScreen> createState() => _RandomQuestionScreenState();
}

class _RandomQuestionScreenState extends ConsumerState<RandomQuestionScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questionSet = ref.watch(questionSetProvider);

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
            const ScreenCodeChip(code: 'CONTENT-001', label: '랜덤 질문'),
            const SizedBox(height: AppSpacing.xl),
            Text('랜덤 질문', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'AI가 오늘의 별자리를 바탕으로 질문을 만들어드려요.',
              style: TextStyle(color: AppColors.inkMuted, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xl),
            questionSet.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Text('질문을 불러오지 못했어요.'),
              data: (qs) => Column(
                children: [
                  ...qs.aiQuestions.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _QuestionCard(
                        badge: '질문 ${e.key + 1}',
                        question: e.value.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '직접 만든 질문',
                    style: TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '내가 스스로에게 묻고 싶은 질문을 적어보세요.',
                      border: InputBorder.none,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: () => ref.refresh(questionSetProvider),
              child: const Text('질문 다시 생성'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.badge, required this.question});

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
          Text(question, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}