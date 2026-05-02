const Map<String, String> _signNames = {
  'aries': '양자리',
  'taurus': '황소자리',
  'gemini': '쌍둥이자리',
  'cancer': '게자리',
  'leo': '사자자리',
  'virgo': '처녀자리',
  'libra': '천칭자리',
  'scorpio': '전갈자리',
  'sagittarius': '사수자리',
  'capricorn': '염소자리',
  'aquarius': '물병자리',
  'pisces': '물고기자리',
};

const Map<String, String> _signEmojis = {
  'aries': '♈',
  'taurus': '♉',
  'gemini': '♊',
  'cancer': '♋',
  'leo': '♌',
  'virgo': '♍',
  'libra': '♎',
  'scorpio': '♏',
  'sagittarius': '♐',
  'capricorn': '♑',
  'aquarius': '♒',
  'pisces': '♓',
};

const Map<String, String> _planetNames = {
  'sun': '태양',
  'moon': '달',
  'mercury': '수성',
  'venus': '금성',
  'mars': '화성',
  'jupiter': '목성',
  'saturn': '토성',
  'uranus': '천왕성',
  'neptune': '해왕성',
  'pluto': '명왕성',
  'ascendant': '상승궁',
};

const Map<String, String> _aspectNames = {
  'conjunction': '합',
  'trine': '삼분',
  'square': '사분',
  'sextile': '육분',
  'opposition': '대립',
};

const Map<String, String> _moods = {
  'calm': '차분함',
  'energetic': '활기참',
  'focused': '집중됨',
  'soft': '부드러움',
};

const Map<String, String> _colors = {
  'indigo': '인디고',
  'blue': '파랑',
  'red': '빨강',
  'yellow': '노랑',
  'green': '초록',
  'white': '흰색',
  'black': '검정',
};

String zodiacNameKo(String raw) {
  final key = raw.trim().toLowerCase();
  return _signNames[key] ?? raw;
}

String zodiacEmoji(String raw) {
  final key = raw.trim().toLowerCase();
  return _signEmojis[key] ?? '';
}

String zodiacLabelKo(String raw) {
  final name = zodiacNameKo(raw);
  final emoji = zodiacEmoji(raw);
  return emoji.isEmpty ? name : '$name $emoji';
}

String planetNameKo(String raw) {
  final key = raw.trim().toLowerCase();
  return _planetNames[key] ?? raw;
}

String aspectNameKo(String raw) {
  final key = raw.trim().toLowerCase();
  return _aspectNames[key] ?? raw;
}

String moodKo(String raw) {
  final key = raw.trim().toLowerCase();
  return _moods[key] ?? raw;
}

String colorKo(String raw) {
  final key = raw.trim().toLowerCase();
  return _colors[key] ?? raw;
}

String signToneKo(String sign) {
  switch (sign.trim().toLowerCase()) {
    case 'aries':
      return '시작이 빠르고 마음이 움직이면 바로 행동으로 옮기는 편입니다.';
    case 'taurus':
      return '좋다고 느낀 것을 오래 지키고 차근차근 쌓아가는 힘이 있습니다.';
    case 'gemini':
      return '호기심이 넓고 대화 속에서 에너지를 얻는 흐름이 강합니다.';
    case 'cancer':
      return '가까운 사람을 살피고 정서적 안정감을 중요하게 여깁니다.';
    case 'leo':
      return '자신의 빛을 자연스럽게 드러내며 존재감 있게 표현하는 편입니다.';
    case 'virgo':
      return '세밀하게 정리하고 현실적인 기준으로 상황을 다듬는 감각이 좋습니다.';
    case 'libra':
      return '균형감과 관계의 조화를 중요하게 여기며 분위기를 부드럽게 만듭니다.';
    case 'scorpio':
      return '감정의 결이 깊고 중요한 대상에는 강한 몰입을 보입니다.';
    case 'sagittarius':
      return '넓은 시야와 솔직한 추진력으로 새로운 경험을 향해 나아갑니다.';
    case 'capricorn':
      return '책임감 있게 목표를 붙들고 긴 호흡으로 결과를 만드는 타입입니다.';
    case 'aquarius':
      return '독립적인 시선과 새로운 방식에 대한 관심이 뚜렷합니다.';
    case 'pisces':
      return '감수성이 풍부하고 분위기와 감정을 섬세하게 받아들이는 편입니다.';
    default:
      return '자신만의 리듬을 따라 움직이며 상황에 맞게 반응합니다.';
  }
}

String planetToneKo(String planet) {
  switch (planet.trim().toLowerCase()) {
    case 'sun':
      return '자아 표현에서는 스스로 방향을 정하려는 힘이 선명합니다.';
    case 'moon':
      return '감정의 흐름에서는 마음의 안전과 편안함을 먼저 살핍니다.';
    case 'mercury':
      return '생각을 정리하고 말로 풀어내는 과정에서 강점을 보입니다.';
    case 'venus':
      return '좋아하는 사람과 공간을 오래 아끼고 돌보려는 마음이 큽니다.';
    case 'mars':
      return '움직이기로 마음먹으면 꾸준하게 밀어붙이는 추진력이 있습니다.';
    case 'jupiter':
      return '시야를 넓히고 더 큰 가능성을 믿게 만드는 낙관이 깔려 있습니다.';
    case 'saturn':
      return '시간을 들여 단단한 기준을 세우고 책임을 지려는 면이 강합니다.';
    default:
      return '이 영역에서 자신만의 리듬과 반응 패턴이 분명하게 드러납니다.';
  }
}

String planetReadingKo({
  required String planet,
  required String sign,
}) {
  return '${signToneKo(sign)} ${planetToneKo(planet)}';
}

String firstLetter(String text, {String fallback = '나'}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return fallback;
  }
  return trimmed.substring(0, 1);
}
