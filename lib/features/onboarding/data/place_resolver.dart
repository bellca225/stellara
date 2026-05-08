import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';

class ResolvedPlace {
  const ResolvedPlace({
    required this.latitude,
    required this.longitude,
    required this.placeName,
    required this.source,
  });

  final double latitude;
  final double longitude;
  final String placeName;
  final String source;
}

class PlaceResolver {
  bool get supportsForwardGeocoding =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<ResolvedPlace?> resolve(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || !supportsForwardGeocoding) {
      return null;
    }

    await setLocaleIdentifier('ko_KR');

    for (final candidate in _candidateQueries(trimmed)) {
      try {
        final locations = await locationFromAddress(candidate);
        if (locations.isEmpty) {
          continue;
        }

        final best = locations.first;
        return ResolvedPlace(
          latitude: best.latitude,
          longitude: best.longitude,
          placeName: trimmed,
          source: 'platform-geocoding',
        );
      } on NoResultFoundException {
        continue;
      } on PlatformException {
        continue;
      }
    }

    return null;
  }

  List<String> _candidateQueries(String trimmed) {
    final queries = <String>[trimmed];
    final lowered = trimmed.toLowerCase();
    final hasCountry = lowered.contains('대한민국') ||
        lowered.contains('한국') ||
        lowered.contains('south korea') ||
        lowered.contains('korea');
    if (!hasCountry) {
      queries.add('$trimmed, 대한민국');
      queries.add('$trimmed, South Korea');
    }
    return queries;
  }
}
