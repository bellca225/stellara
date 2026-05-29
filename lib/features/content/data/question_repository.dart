import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../domain/question.dart';

class QuestionRepository {
  Future<QuestionSet> generateQuestions({String? zodiacSign}) async {
    if (kDebugMode) {
      await Future.delayed(const Duration(seconds: 1));
      return const QuestionSet(
        aiQuestions: [
          Question(id: '1', text: '요즘 내가 가장 오래 붙잡고 있는 감정은 무엇일까요?', isUserCreated: false),
          Question(id: '2', text: '친해지고 싶은 사람에게 먼저 건네고 싶은 말은 무엇인가요?', isUserCreated: false),
          Question(id: '3', text: '이번 주의 나를 가장 잘 설명하는 장면은 어떤 모습인가요?', isUserCreated: false),
        ],
        userQuestion: null,
      );
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': const String.fromEnvironment('ANTHROPIC_API_KEY'),
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-haiku-4-5-20251001',
          'max_tokens': 500,
          'messages': [
            {
              'role': 'user',
              'content': '별자리 앱 사용자를 위한 자기성찰 질문 3개를 만들어줘. JSON 배열로만 답해줘. 예: ["질문1", "질문2", "질문3"]'
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'] as String;
        final questions = jsonDecode(text) as List;
        return QuestionSet(
          aiQuestions: questions.asMap().entries.map((e) => Question(
            id: '${e.key + 1}',
            text: e.value as String,
            isUserCreated: false,
          )).toList(),
          userQuestion: null,
        );
      }
    } catch (e) {
      debugPrint('AI 질문 생성 실패: $e');
    }

    return const QuestionSet(
      aiQuestions: [
        Question(id: '1', text: '요즘 내가 가장 오래 붙잡고 있는 감정은 무엇일까요?', isUserCreated: false),
        Question(id: '2', text: '친해지고 싶은 사람에게 먼저 건네고 싶은 말은 무엇인가요?', isUserCreated: false),
        Question(id: '3', text: '이번 주의 나를 가장 잘 설명하는 장면은 어떤 모습인가요?', isUserCreated: false),
      ],
      userQuestion: null,
    );
  }
}