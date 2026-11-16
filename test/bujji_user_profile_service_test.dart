import 'package:flutter_test/flutter_test.dart';
import 'package:bujji_ai/services/bujji_user_profile_service.dart';

void main() {
  group('BujjiUserProfileService.ageBandForDateOfBirth', () {
    final today = DateTime(2026, 11, 16);

    test('returns child for ages below 13', () {
      expect(
        BujjiUserProfileService.ageBandForDateOfBirth(
          DateTime(2013, 11, 17),
          now: today,
        ),
        'child',
      );
    });

    test('returns teen at age 13 and through age 17', () {
      expect(
        BujjiUserProfileService.ageBandForDateOfBirth(
          DateTime(2013, 11, 16),
          now: today,
        ),
        'teen',
      );
      expect(
        BujjiUserProfileService.ageBandForDateOfBirth(
          DateTime(2008, 11, 17),
          now: today,
        ),
        'teen',
      );
    });

    test('returns young adult at ages 18 through 29', () {
      expect(
        BujjiUserProfileService.ageBandForDateOfBirth(
          DateTime(2008, 11, 16),
          now: today,
        ),
        'young_adult',
      );
      expect(
        BujjiUserProfileService.ageBandForDateOfBirth(
          DateTime(1996, 11, 17),
          now: today,
        ),
        'young_adult',
      );
    });

    test('returns adult at ages 30 through 59', () {
      expect(
        BujjiUserProfileService.ageBandForDateOfBirth(
          DateTime(1996, 11, 16),
          now: today,
        ),
        'adult',
      );
    });

    test('returns senior from age 60', () {
      expect(
        BujjiUserProfileService.ageBandForDateOfBirth(
          DateTime(1966, 11, 16),
          now: today,
        ),
        'senior',
      );
    });

    test('rejects future dates and ages above 120', () {
      expect(
        BujjiUserProfileService.ageBandForDateOfBirth(
          DateTime(2026, 11, 17),
          now: today,
        ),
        isNull,
      );
      expect(
        BujjiUserProfileService.ageBandForDateOfBirth(
          DateTime(1905, 11, 16),
          now: today,
        ),
        isNull,
      );
    });
  });
}
