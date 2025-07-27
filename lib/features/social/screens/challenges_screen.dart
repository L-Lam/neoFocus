import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/firebase_service.dart';
import '../../../widgets/loading_indicator.dart';
import '../services/challenge_generation.dart';
import '../services/social_service.dart';
import '../models/challenge_model.dart';
import '../widgets/challenge_card.dart';
import '../widgets/create_challenge_dialog.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeChallenges();
  }

  Future<void> _initializeChallenges() async {
    // Generate challenges on first load
    await ChallengeGenerationService.generateDailyChallenges();
    await ChallengeGenerationService.generateSeasonalChallenges();
    await ChallengeGenerationService.cleanupExpiredChallenges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Challenges', style: AppTextStyles.heading3),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            color: AppColors.primary,
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const CreateChallengeDialog(),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Daily'),
            Tab(text: 'Seasonal'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveChallengesTab(),
          _DailyChallengesTab(),
          _SeasonalChallengesTab(),
        ],
      ),
    );
  }
}

class _ActiveChallengesTab extends StatefulWidget {
  @override
  State<_ActiveChallengesTab> createState() => _ActiveChallengesTabState();
}

class _ActiveChallengesTabState extends State<_ActiveChallengesTab> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: StreamBuilder<List<Challenge>>(
        stream: SocialService.getActiveChallenges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          final challenges = snapshot.data ?? [];

          if (challenges.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 80.sp,
                        color: AppColors.textHint,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No active challenges',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Join or create a challenge to get started!',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.w),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: ChallengeCard(challenge: challenges[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class _DailyChallengesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseService.firestore
              .collection('challenges')
              .where('type', isEqualTo: 'daily')
              .where('dateStr', isEqualTo: todayStr)
              .where('status', isEqualTo: 'active')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        final challenges = snapshot.data?.docs ?? [];

        if (challenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.today_outlined,
                  size: 80.sp,
                  color: AppColors.textHint,
                ),
                SizedBox(height: 16.h),
                Text(
                  'No daily challenges',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text('Check back tomorrow!', style: AppTextStyles.bodySmall),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final data = challenges[index].data() as Map<String, dynamic>;
            final challenge = Challenge.fromMap(data, challenges[index].id);

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: ChallengeCard(challenge: challenge),
            );
          },
        );
      },
    );
  }
}

class _SeasonalChallengesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final season = _getCurrentSeason();
    final year = DateTime.now().year;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseService.firestore
              .collection('challenges')
              .where('type', isEqualTo: 'seasonal')
              .where('seasonalTheme', isEqualTo: season)
              .where('year', isEqualTo: year)
              .where('status', isEqualTo: 'active')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        final challenges = snapshot.data?.docs ?? [];

        if (challenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.ac_unit, size: 80.sp, color: AppColors.textHint),
                SizedBox(height: 16.h),
                Text(
                  'No seasonal challenges',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text('Check back next season!', style: AppTextStyles.bodySmall),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final data = challenges[index].data() as Map<String, dynamic>;
            final challenge = Challenge.fromMap(data, challenges[index].id);

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: ChallengeCard(
                challenge: challenge,
                isSeasonalThemed: true,
              ),
            );
          },
        );
      },
    );
  }

  String _getCurrentSeason() {
    final month = DateTime.now().month;

    if (month >= 12 || month <= 2) return 'winter';
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    return 'fall';
  }
}
