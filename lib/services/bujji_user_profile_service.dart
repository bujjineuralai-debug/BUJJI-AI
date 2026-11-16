import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Loads only the minimum profile context needed for conversational addressing.
/// Date of birth stays in the user's Firestore profile; only a coarse age band
/// is sent to the Worker. If profile loading fails, chat continues without it.
class BujjiUserProfileService {
  BujjiUserProfileService._();

  static const _validPreferences = {'auto', 'respectful', 'casual'};

  static String? ageBandForDateOfBirth(
    DateTime dateOfBirth, {
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final dob = DateTime(dateOfBirth.year, dateOfBirth.month, dateOfBirth.day);
    final currentDate = DateTime(today.year, today.month, today.day);
    if (dob.isAfter(currentDate)) return null;

    var age = currentDate.year - dob.year;
    if (currentDate.month < dob.month ||
        (currentDate.month == dob.month && currentDate.day < dob.day)) {
      age--;
    }
    if (age < 0 || age > 120) return null;
    if (age < 13) return 'child';
    if (age < 18) return 'teen';
    if (age < 30) return 'young_adult';
    if (age < 60) return 'adult';
    return 'senior';
  }

  static Future<Map<String, dynamic>> forConversation({
    required bool firstAssistantMessage,
  }) async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        user = (await FirebaseAuth.instance.signInAnonymously()).user;
      }
      if (user == null) {
        return {'firstAssistantMessage': firstAssistantMessage};
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = snapshot.data() ?? <String, dynamic>{};
      final rawDob = data['dateOfBirth'];
      final rawPreference = data['preferredAddress']?.toString() ?? 'auto';
      final preference = _validPreferences.contains(rawPreference)
          ? rawPreference
          : 'auto';

      final parsedDob = rawDob is String ? DateTime.tryParse(rawDob) : null;
      final ageBand = parsedDob == null ? null : ageBandForDateOfBirth(parsedDob);

      return {
        if (ageBand != null) 'ageBand': ageBand,
        'preferredAddress': preference,
        'firstAssistantMessage': firstAssistantMessage,
      };
    } catch (_) {
      // Personalization is optional and must never block chat.
      return {'firstAssistantMessage': firstAssistantMessage};
    }
  }
}
