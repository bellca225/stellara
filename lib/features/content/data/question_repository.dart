import 'dart:math';

import '../../../core/utils/astro_text.dart';
import '../domain/question_item.dart';

enum _QuestionTheme { charm, communication, timing, strength, stress, future }

class QuestionRepository {
  Future<List<QuestionItem>> generate({
    required String providerPreference,
    required String friendUid,
    required String friendName,
    String? friendSign,
    String? mySign,
    int count = 3,
    int revision = 0,
  }) async {
    // 현재 브랜치에서는 local question set 만 사용한다.
    await Future<void>.delayed(const Duration(milliseconds: 220));

    final templates = List<_QuestionTheme>.from(_QuestionTheme.values);
    final random = Random(friendUid.hashCode ^ (revision * 37));
    templates.shuffle(random);
    final picked = templates.take(count.clamp(1, templates.length)).toList();

    return [
      for (var i = 0; i < picked.length; i++)
        QuestionItem(
          id: '$friendUid-$revision-$i-${picked[i].name}',
          prompt: _promptForTheme(picked[i], friendName),
          answer: _answerForTheme(
            theme: picked[i],
            friendName: friendName,
            friendSign: friendSign,
            mySign: mySign,
          ),
          source: QuestionSource.localPreset,
        ),
    ];
  }

  Future<QuestionItem> answerCustom({
    required String providerPreference,
    required String friendUid,
    required String friendName,
    required String userPrompt,
    String? friendSign,
    String? mySign,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final theme = _themeFromPrompt(userPrompt);
    return QuestionItem(
      id: 'custom-$friendUid-${userPrompt.hashCode}',
      prompt: userPrompt,
      answer: _customAnswer(
        theme: theme,
        friendName: friendName,
        friendSign: friendSign,
        mySign: mySign,
        userPrompt: userPrompt,
      ),
      source: QuestionSource.localCustom,
    );
  }

  String _promptForTheme(_QuestionTheme theme, String friendName) {
    switch (theme) {
      case _QuestionTheme.charm:
        return '$friendName의 가장 자연스러운 매력 포인트는 무엇일까?';
      case _QuestionTheme.communication:
        return '$friendName와 더 가까워지려면 어떤 대화 방식이 잘 맞을까?';
      case _QuestionTheme.timing:
        return '$friendName와 지금 관계를 진전시키기 좋은 타이밍은 언제일까?';
      case _QuestionTheme.strength:
        return '$friendName가 요즘 특히 빛낼 수 있는 강점은 무엇일까?';
      case _QuestionTheme.stress:
        return '$friendName는 스트레스를 받을 때 어떤 반응 패턴이 나올까?';
      case _QuestionTheme.future:
        return '$friendName가 앞으로 더 크게 성장할 방향은 무엇일까?';
    }
  }

  String _answerForTheme({
    required _QuestionTheme theme,
    required String friendName,
    String? friendSign,
    String? mySign,
  }) {
    final friendTone = _friendTone(friendSign);
    final pairHint = _pairHint(mySign);

    switch (theme) {
      case _QuestionTheme.charm:
        return '$friendName님은 $friendTone 그래서 처음부터 강하게 드러나기보다, '
            '편안한 분위기 속에서 자기만의 매력을 천천히 보여주는 타입에 가깝습니다. '
            '$pairHint';
      case _QuestionTheme.communication:
        return '$friendName님과의 대화는 질문을 빠르게 던지기보다, '
            '상대가 익숙해질 시간을 주면서 리듬을 맞출수록 더 깊어집니다. '
            '$friendTone';
      case _QuestionTheme.timing:
        return '지금은 결과를 서두르기보다 작은 연결을 자주 만드는 편이 좋습니다. '
            '$friendName님은 관계의 안정감을 느낄수록 반응이 분명해질 가능성이 큽니다. '
            '$pairHint';
      case _QuestionTheme.strength:
        return '$friendName님은 최근 자신이 잘 아는 방식 안에서 꾸준히 밀어붙일 때 강점이 살아납니다. '
            '$friendTone 그래서 한 번 흐름을 잡으면 생각보다 오래 집중할 수 있습니다.';
      case _QuestionTheme.stress:
        return '$friendName님은 스트레스를 받으면 감정이나 속도를 바로 드러내기보다, '
            '혼자 정리할 시간을 먼저 가지려는 경향이 있습니다. '
            '$friendTone';
      case _QuestionTheme.future:
        return '$friendName님의 다음 성장 포인트는 이미 잘하는 것을 더 선명하게 드러내는 데 있습니다. '
            '$friendTone 그래서 억지로 새로운 캐릭터를 만들기보다 자기 리듬을 믿는 편이 유리합니다.';
    }
  }

  _QuestionTheme _themeFromPrompt(String prompt) {
    final text = prompt.toLowerCase();
    if (text.contains('매력') || text.contains('좋아') || text.contains('호감')) {
      return _QuestionTheme.charm;
    }
    if (text.contains('대화') || text.contains('말') || text.contains('소통')) {
      return _QuestionTheme.communication;
    }
    if (text.contains('언제') || text.contains('타이밍') || text.contains('가까워')) {
      return _QuestionTheme.timing;
    }
    if (text.contains('재능') || text.contains('강점') || text.contains('잘해')) {
      return _QuestionTheme.strength;
    }
    if (text.contains('힘들') || text.contains('스트레스') || text.contains('불안')) {
      return _QuestionTheme.stress;
    }
    return _QuestionTheme.future;
  }

  String _customAnswer({
    required _QuestionTheme theme,
    required String friendName,
    required String userPrompt,
    String? friendSign,
    String? mySign,
  }) {
    final lead = _answerForTheme(
      theme: theme,
      friendName: friendName,
      friendSign: friendSign,
      mySign: mySign,
    );
    return lead;
  }

  String _friendTone(String? friendSign) {
    final normalized = friendSign?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty || normalized == '-') {
      return '별자리 정보가 아직 충분하지 않지만, 한 번 마음을 정하면 자기 리듬을 지키려는 면이 있어 보여요.';
    }
    final signName = zodiacNameKo(normalized);
    final tone = signToneKo(normalized);
    return '$signName 기질이 보여서 $tone';
  }

  String _pairHint(String? mySign) {
    final normalized = mySign?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty || normalized == '-') {
      return '조금 천천히 리듬을 맞추는 방식이 오히려 관계를 편안하게 만듭니다.';
    }
    return '${zodiacNameKo(normalized)}인 당신이 먼저 분위기를 부드럽게 열어주면 '
        '서로의 속도를 맞추는 데 도움이 됩니다.';
  }
}
