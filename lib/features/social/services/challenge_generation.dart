import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge_model.dart';
import '../../../core/services/firebase_service.dart';

class ChallengeGenerationService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Generate daily challenges
  static Future<void> generateDailyChallenges() async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Check if today's challenges already exist
    final existingChallenges =
        await _firestore
            .collection('challenges')
            .where('type', isEqualTo: 'daily')
            .where('dateStr', isEqualTo: todayStr)
            .get();

    if (existingChallenges.docs.isNotEmpty) {
      print('Daily challenges already exist for $todayStr');
      return;
    }

    // Daily challenge templates
    final dailyChallenges = [
      {
        'title': 'Morning Focus',
        'description': 'Complete 60 minutes of focused work before noon',
        'targetMinutes': 60,
        'rewardPoints': 50,
      },
      {
        'title': 'Deep Work Session',
        'description': 'Complete a 90-minute uninterrupted focus session',
        'targetMinutes': 90,
        'rewardPoints': 75,
      },
      {
        'title': 'Pomodoro Master',
        'description': 'Complete 4 Pomodoro sessions (25 minutes each)',
        'targetMinutes': 100,
        'rewardPoints': 100,
      },
      {
        'title': 'Evening Study',
        'description': 'Focus for 45 minutes after 6 PM',
        'targetMinutes': 45,
        'rewardPoints': 40,
      },
    ];

    // Create challenges
    final batch = _firestore.batch();

    for (final template in dailyChallenges) {
      final docRef = _firestore.collection('challenges').doc();
      batch.set(docRef, {
        'title': template['title'],
        'description': template['description'],
        'type': 'daily',
        'status': 'active',
        'targetMinutes': template['targetMinutes'],
        'currentMinutes': 0,
        'startDate': Timestamp.fromDate(
          DateTime(today.year, today.month, today.day, 0, 0, 0),
        ),
        'endDate': Timestamp.fromDate(
          DateTime(today.year, today.month, today.day, 23, 59, 59),
        ),
        'participants': [],
        'createdBy': 'system',
        'participantProgress': {},
        'rewardPoints': template['rewardPoints'],
        'dateStr': todayStr,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    print('Generated ${dailyChallenges.length} daily challenges for $todayStr');
  }

  // Generate seasonal challenges
  static Future<void> generateSeasonalChallenges() async {
    final now = DateTime.now();
    final season = _getCurrentSeason();
    final year = now.year;

    // Check if this season's challenge exists
    final existingChallenges =
        await _firestore
            .collection('challenges')
            .where('type', isEqualTo: 'seasonal')
            .where('seasonalTheme', isEqualTo: season)
            .where('year', isEqualTo: year)
            .get();

    if (existingChallenges.docs.isNotEmpty) {
      print('Seasonal challenge already exists for $season $year');
      return;
    }

    // Seasonal challenge templates
    final seasonalTemplates = {
      'winter': {
        'title': 'Winter Focus Marathon',
        'description': 'Complete 1000 minutes of focus this winter season',
        'targetMinutes': 1000,
        'rewardPoints': 500,
        'emoji': '❄️',
      },
      'spring': {
        'title': 'Spring Productivity Bloom',
        'description': 'Grow your focus to 1200 minutes this spring',
        'targetMinutes': 1200,
        'rewardPoints': 600,
        'emoji': '🌸',
      },
      'summer': {
        'title': 'Summer Focus Challenge',
        'description': 'Stay productive with 1500 minutes of focus this summer',
        'targetMinutes': 1500,
        'rewardPoints': 750,
        'emoji': '☀️',
      },
      'fall': {
        'title': 'Fall Harvest Focus',
        'description': 'Harvest 1000 minutes of productive time this fall',
        'targetMinutes': 1000,
        'rewardPoints': 500,
        'emoji': '🍂',
      },
    };

    final template = seasonalTemplates[season]!;
    final seasonDates = _getSeasonDates(season, year);

    await _firestore.collection('challenges').add({
      'title': '${template['emoji']} ${template['title']}',
      'description': template['description'],
      'type': 'seasonal',
      'status': 'active',
      'targetMinutes': template['targetMinutes'],
      'currentMinutes': 0,
      'startDate': Timestamp.fromDate(seasonDates['start']!),
      'endDate': Timestamp.fromDate(seasonDates['end']!),
      'participants': [],
      'createdBy': 'system',
      'participantProgress': {},
      'rewardPoints': template['rewardPoints'],
      'seasonalTheme': season,
      'year': year,
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('Generated seasonal challenge for $season $year');
  }

  static String _getCurrentSeason() {
    final month = DateTime.now().month;

    if (month >= 12 || month <= 2) return 'winter';
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    return 'fall';
  }

  static Map<String, DateTime> _getSeasonDates(String season, int year) {
    switch (season) {
      case 'winter':
        // Winter spans across years
        final currentMonth = DateTime.now().month;
        if (currentMonth == 12) {
          return {
            'start': DateTime(year, 12, 1),
            'end': DateTime(year + 1, 2, 28),
          };
        } else {
          return {
            'start': DateTime(year - 1, 12, 1),
            'end': DateTime(year, 2, 28),
          };
        }
      case 'spring':
        return {'start': DateTime(year, 3, 1), 'end': DateTime(year, 5, 31)};
      case 'summer':
        return {'start': DateTime(year, 6, 1), 'end': DateTime(year, 8, 31)};
      case 'fall':
        return {'start': DateTime(year, 9, 1), 'end': DateTime(year, 11, 30)};
      default:
        return {
          'start': DateTime.now(),
          'end': DateTime.now().add(const Duration(days: 90)),
        };
    }
  }

  // Clean up expired challenges
  static Future<void> cleanupExpiredChallenges() async {
    final now = DateTime.now();

    final expiredChallenges =
        await _firestore
            .collection('challenges')
            .where('status', isEqualTo: 'active')
            .where('endDate', isLessThan: Timestamp.fromDate(now))
            .get();

    final batch = _firestore.batch();

    for (final doc in expiredChallenges.docs) {
      batch.update(doc.reference, {'status': 'completed'});
    }

    await batch.commit();
    print('Marked ${expiredChallenges.docs.length} challenges as completed');
  }
}
