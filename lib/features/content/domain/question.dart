class Question {
  const Question({
    required this.id,
    required this.text,
    required this.isUserCreated,
  });

  final String id;
  final String text;
  final bool isUserCreated;
}

class QuestionSet {
  const QuestionSet({
    required this.aiQuestions,
    required this.userQuestion,
  });

  final List<Question> aiQuestions;
  final String? userQuestion;
}
