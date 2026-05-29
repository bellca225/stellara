import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/question_repository.dart';
import '../domain/question.dart';

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository();
});

final questionSetProvider = FutureProvider.autoDispose<QuestionSet>((ref) async {
  return ref.read(questionRepositoryProvider).generateQuestions();
});