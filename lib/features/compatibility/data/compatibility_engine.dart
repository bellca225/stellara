// lib/features/compatibility/data/compatibility_engine.dart
//
// 저장된 나탈 차트를 바탕으로 궁합 결과를 로컬에서 결정론적으로 계산한다.
//
// 설계 의도
// - 외부 synastry API 가 없거나 실패해도 결과를 낼 수 있어야 한다.
// - 같은 두 차트면 항상 같은 결과를 반환해 캐시 효율을 높인다.
// - 점수뿐 아니라 화면/AI가 바로 사용할 자연어 해설까지 함께 만든다.

import '../../../core/utils/astro_text.dart';
import '../../astrology/domain/natal_chart.dart';
import '../domain/synastry_result.dart';

class CompatibilityEngine {
  const CompatibilityEngine();

  static const engineVersion = 'compat.v2';

  SynastryResult evaluate({
    required String pairKey,
    required String chartPairVersion,
    required NatalChart me,
    required NatalChart partner,
    required String source,
  }) {
    final emotion = _categoryScore(
      me,
      partner,
      const [
        _Rule('Moon', 'Moon', 1.4),
        _Rule('Moon', 'Venus', 1.2),
        _Rule('Moon', 'Sun', 1.0),
        _Rule('Venus', 'Venus', 0.9),
        _Rule('Sun', 'Moon', 1.0),
      ],
      basePairs: const [
        ('Moon', 'Moon'),
        ('Moon', 'Venus'),
        ('Moon', 'Sun'),
      ],
    );

    final communication = _categoryScore(
      me,
      partner,
      const [
        _Rule('Mercury', 'Mercury', 1.5),
        _Rule('Mercury', 'Sun', 0.9),
        _Rule('Mercury', 'Moon', 0.9),
        _Rule('Mercury', 'Venus', 0.8),
        _Rule('Mercury', 'Mars', 1.0),
      ],
      basePairs: const [
        ('Mercury', 'Mercury'),
        ('Mercury', 'Sun'),
        ('Mercury', 'Moon'),
      ],
    );

    final romance = _categoryScore(
      me,
      partner,
      const [
        _Rule('Venus', 'Mars', 1.5),
        _Rule('Venus', 'Venus', 1.1),
        _Rule('Mars', 'Mars', 0.9),
        _Rule('Sun', 'Venus', 0.9),
        _Rule('Moon', 'Mars', 0.8),
      ],
      basePairs: const [
        ('Venus', 'Mars'),
        ('Venus', 'Venus'),
        ('Mars', 'Mars'),
      ],
    );

    final friendship = _categoryScore(
      me,
      partner,
      const [
        _Rule('Sun', 'Sun', 1.2),
        _Rule('Mercury', 'Mercury', 1.0),
        _Rule('Moon', 'Moon', 1.0),
        _Rule('Venus', 'Sun', 0.8),
        _Rule('Sun', 'Moon', 0.8),
      ],
      basePairs: const [
        ('Sun', 'Sun'),
        ('Mercury', 'Mercury'),
        ('Moon', 'Moon'),
      ],
    );

    final highlights = _buildHighlights(me, partner);
    final strengths = highlights.where((h) => h.impact > 0).take(3).map((h) {
      return _strengthText(h);
    }).toList();
    final challenges = highlights.where((h) => h.impact < 0).take(3).map((h) {
      return _challengeText(h);
    }).toList();

    final totalScore = ((emotion.score +
                communication.score +
                romance.score +
                friendship.score) /
            4)
        .round()
        .clamp(0, 100)
        .toInt();

    final emotionalMatch =
        _categoryNarrative('감정', emotion.score, emotion.topPositive, emotion.topNegative);
    final communicationStyle = _categoryNarrative(
      '대화',
      communication.score,
      communication.topPositive,
      communication.topNegative,
    );
    final romanticMatch =
        _categoryNarrative('연애', romance.score, romance.topPositive, romance.topNegative);
    final friendshipMatch = _categoryNarrative(
      '우정',
      friendship.score,
      friendship.topPositive,
      friendship.topNegative,
    );

    final summary = _buildSummary(
      totalScore: totalScore,
      friendshipScore: friendship.score,
      emotionalMatch: emotionalMatch,
      communicationStyle: communicationStyle,
      romanticMatch: romanticMatch,
      friendshipMatch: friendshipMatch,
      strengths: strengths,
      challenges: challenges,
    );

    return SynastryResult(
      totalScore: totalScore,
      emotionScore: emotion.score,
      communicationScore: communication.score,
      romanceScore: romance.score,
      friendshipScore: friendship.score,
      summary: summary,
      emotionalMatch: emotionalMatch,
      communicationStyle: communicationStyle,
      romanticMatch: romanticMatch,
      friendshipMatch: friendshipMatch,
      strengths: strengths,
      challenges: challenges,
      source: source,
      engineVersion: engineVersion,
      pairKey: pairKey,
      chartPairVersion: chartPairVersion,
    );
  }

  _CategoryResult _categoryScore(
    NatalChart me,
    NatalChart partner,
    List<_Rule> rules, {
    required List<(String, String)> basePairs,
  }) {
    double score = 52;
    _AspectHit? topPositive;
    _AspectHit? topNegative;

    for (final basePair in basePairs) {
      final left = _findPlanet(me, basePair.$1);
      final right = _findPlanet(partner, basePair.$2);
      if (left == null || right == null) continue;
      score += _signAffinity(left.sign, right.sign) * 6.0;
    }

    for (final rule in rules) {
      final hit = _matchRule(me, partner, rule);
      if (hit == null) continue;
      score += hit.impact;
      if (topPositive == null || hit.impact > topPositive.impact) {
        if (hit.impact > 0) topPositive = hit;
      }
      if (topNegative == null || hit.impact < topNegative.impact) {
        if (hit.impact < 0) topNegative = hit;
      }
    }

    return _CategoryResult(
      score: score.round().clamp(0, 100).toInt(),
      topPositive: topPositive,
      topNegative: topNegative,
    );
  }

  List<_AspectHit> _buildHighlights(NatalChart me, NatalChart partner) {
    const pairs = [
      _Rule('Sun', 'Sun', 1.0),
      _Rule('Sun', 'Moon', 1.1),
      _Rule('Moon', 'Moon', 1.2),
      _Rule('Mercury', 'Mercury', 1.2),
      _Rule('Venus', 'Venus', 1.1),
      _Rule('Venus', 'Mars', 1.3),
      _Rule('Mars', 'Mars', 0.9),
      _Rule('Mercury', 'Mars', 0.9),
    ];

    final hits = <_AspectHit>[];
    for (final rule in pairs) {
      final hit = _matchRule(me, partner, rule);
      if (hit != null) hits.add(hit);
    }
    hits.sort((a, b) => b.impact.abs().compareTo(a.impact.abs()));
    return hits;
  }

  _AspectHit? _matchRule(NatalChart me, NatalChart partner, _Rule rule) {
    final left = _findPlanet(me, rule.leftPlanet);
    final right = _findPlanet(partner, rule.rightPlanet);
    if (left == null || right == null) return null;

    final aspect = _majorAspect(left.degree, right.degree);
    if (aspect == null) return null;

    final signAffinity = _signAffinity(left.sign, right.sign);
    final impact = (aspect.weight * 10.0 * rule.weight) + (signAffinity * 2.5);

    return _AspectHit(
      leftPlanet: left.name,
      rightPlanet: right.name,
      leftSign: left.sign,
      rightSign: right.sign,
      aspect: aspect.name,
      orb: aspect.orb,
      impact: impact,
    );
  }

  Planet? _findPlanet(NatalChart chart, String name) {
    for (final planet in chart.planets) {
      if (planet.name.toLowerCase() == name.toLowerCase()) return planet;
    }
    return null;
  }

  _AspectMatch? _majorAspect(double a, double b) {
    final distance = _angularDistance(a, b);
    const definitions = <_AspectDefinition>[
      _AspectDefinition('conjunction', 0, 8, 1.0),
      _AspectDefinition('sextile', 60, 5, 0.65),
      _AspectDefinition('square', 90, 6, -0.9),
      _AspectDefinition('trine', 120, 6, 0.95),
      _AspectDefinition('opposition', 180, 7, -0.75),
    ];

    _AspectMatch? best;
    for (final def in definitions) {
      final orb = (distance - def.targetAngle).abs();
      if (orb > def.maxOrb) continue;
      if (best == null || orb < best.orb) {
        best = _AspectMatch(def.name, orb, def.weight);
      }
    }
    return best;
  }

  double _angularDistance(double a, double b) {
    final raw = (a - b).abs() % 360.0;
    return raw > 180.0 ? 360.0 - raw : raw;
  }

  double _signAffinity(String left, String right) {
    final leftIndex = _signIndex(left);
    final rightIndex = _signIndex(right);
    if (leftIndex == -1 || rightIndex == -1) return 0;

    final leftElement = leftIndex % 4;
    final rightElement = rightIndex % 4;
    if (leftIndex == rightIndex) return 1.2;
    if (leftElement == rightElement) return 1.0;

    final distance = (leftIndex - rightIndex).abs();
    final wrappedDistance = distance > 6 ? 12 - distance : distance;
    if (wrappedDistance == 2 || wrappedDistance == 4) return 0.45;
    if (wrappedDistance == 6) return -0.55;
    return -0.1;
  }

  int _signIndex(String sign) {
    const signs = [
      'Aries',
      'Taurus',
      'Gemini',
      'Cancer',
      'Leo',
      'Virgo',
      'Libra',
      'Scorpio',
      'Sagittarius',
      'Capricorn',
      'Aquarius',
      'Pisces',
    ];
    return signs.indexWhere((s) => s.toLowerCase() == sign.toLowerCase());
  }

  String _categoryNarrative(
    String category,
    int score,
    _AspectHit? positive,
    _AspectHit? negative,
  ) {
    final base = switch (category) {
      '감정' => score >= 75
          ? '서로의 감정 결을 빠르게 읽어내는 편이에요.'
          : score >= 60
              ? '기본적인 정서 호흡은 잘 맞지만 타이밍 조율이 중요해요.'
              : '감정 표현 방식이 달라 의식적인 확인이 필요해요.',
      '대화' => score >= 75
          ? '말이 이어질 때 생각의 속도와 포인트가 잘 맞는 조합이에요.'
          : score >= 60
              ? '대화는 무난하지만 오해가 쌓이지 않게 정리해주는 것이 좋아요.'
              : '말을 꺼내는 방식과 받아들이는 방식이 꽤 다를 수 있어요.',
      '연애' => score >= 75
          ? '끌림과 리듬이 자연스럽게 이어져 설렘을 만들기 쉬워요.'
          : score >= 60
              ? '호감은 충분하지만 표현 방식은 조금 다를 수 있어요.'
              : '좋아하는 방식과 속도가 달라 배려가 꼭 필요해요.',
      '우정' => score >= 75
          ? '같이 있을 때 텐션이 잘 맞아 오래 가는 친구가 되기 쉬워요.'
          : score >= 60
              ? '편한 지점은 많지만 역할 분담을 잘 잡는 편이 좋아요.'
              : '친해지기까지 시간이 걸리지만 선을 이해하면 안정적이에요.',
      _ => '',
    };

    final positiveText = positive == null ? '' : ' ${_positiveNarrative(positive)}';
    final negativeText = negative == null ? '' : ' 다만 ${_negativeNarrative(negative)}';
    return '$base$positiveText$negativeText'.trim();
  }

  String _positiveNarrative(_AspectHit hit) {
    return '${planetNameKo(hit.leftPlanet)}-${planetNameKo(hit.rightPlanet)} '
        '${aspectNameKo(hit.aspect)} 흐름 덕분에 강점이 더 또렷해집니다.';
  }

  String _negativeNarrative(_AspectHit hit) {
    return '${planetNameKo(hit.leftPlanet)}-${planetNameKo(hit.rightPlanet)} '
        '${aspectNameKo(hit.aspect)} 때문에 리듬 차이가 드러날 수 있어요.';
  }

  String _strengthText(_AspectHit hit) {
    return '${planetNameKo(hit.leftPlanet)} ${zodiacNameKo(hit.leftSign)}와 '
        '${planetNameKo(hit.rightPlanet)} ${zodiacNameKo(hit.rightSign)}의 '
        '${aspectNameKo(hit.aspect)}이 관계의 시너지를 만들어줘요.';
  }

  String _challengeText(_AspectHit hit) {
    return '${planetNameKo(hit.leftPlanet)} ${zodiacNameKo(hit.leftSign)}와 '
        '${planetNameKo(hit.rightPlanet)} ${zodiacNameKo(hit.rightSign)}의 '
        '${aspectNameKo(hit.aspect)}이 부딪히면 감정선이나 속도 차이가 커질 수 있어요.';
  }

  String _buildSummary({
    required int totalScore,
    required int friendshipScore,
    required String emotionalMatch,
    required String communicationStyle,
    required String romanticMatch,
    required String friendshipMatch,
    required List<String> strengths,
    required List<String> challenges,
  }) {
    final overall = totalScore >= 78
        ? '전체적으로는 서로의 장점이 자연스럽게 맞물리는 조합입니다.'
        : totalScore >= 62
            ? '기본적인 궁합은 좋은 편이고, 대화와 감정 확인을 조금 더 챙기면 더 편안해질 수 있어요.'
            : '리듬 차이가 분명하지만 서로의 방식을 이해하면 관계를 충분히 안정적으로 만들 수 있어요.';
    final friendshipLead = friendshipScore >= 75
        ? ' 특히 친구로 붙어 있을 때 텐션이 잘 맞는 편이라 가볍게 만나도 케미가 살아나요.'
        : friendshipScore <= 45
            ? ' 다만 친구로서도 리듬을 맞추는 데 시간이 조금 필요할 수 있어요.'
            : '';

    final strengthText = strengths.isEmpty
        ? ''
        : '\n\n강점\n- ${strengths.take(2).join('\n- ')}';
    final challengeText = challenges.isEmpty
        ? ''
        : '\n\n주의할 점\n- ${challenges.take(2).join('\n- ')}';

    return '$overall$friendshipLead\n\n'
        '우정 결: $friendshipMatch\n'
        '감정 결: $emotionalMatch\n'
        '대화 결: $communicationStyle\n'
        '연애 결: $romanticMatch'
        '$strengthText'
        '$challengeText';
  }
}

class _Rule {
  const _Rule(this.leftPlanet, this.rightPlanet, this.weight);

  final String leftPlanet;
  final String rightPlanet;
  final double weight;
}

class _AspectDefinition {
  const _AspectDefinition(
    this.name,
    this.targetAngle,
    this.maxOrb,
    this.weight,
  );

  final String name;
  final double targetAngle;
  final double maxOrb;
  final double weight;
}

class _AspectMatch {
  const _AspectMatch(this.name, this.orb, this.weight);

  final String name;
  final double orb;
  final double weight;
}

class _AspectHit {
  const _AspectHit({
    required this.leftPlanet,
    required this.rightPlanet,
    required this.leftSign,
    required this.rightSign,
    required this.aspect,
    required this.orb,
    required this.impact,
  });

  final String leftPlanet;
  final String rightPlanet;
  final String leftSign;
  final String rightSign;
  final String aspect;
  final double orb;
  final double impact;
}

class _CategoryResult {
  const _CategoryResult({
    required this.score,
    this.topPositive,
    this.topNegative,
  });

  final int score;
  final _AspectHit? topPositive;
  final _AspectHit? topNegative;
}
