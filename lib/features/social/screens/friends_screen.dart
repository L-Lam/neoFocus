import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/loading_indicator.dart';
import '../services/social_service.dart';
import '../models/friend_model.dart';
import '../widgets/friend_card.dart';
import '../widgets/add_friend_dialog.dart';
import '../widgets/friend_request_card.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: Text('Friends', style: AppTextStyles.heading3),
        actions: [
          // Friend requests badge
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseService.currentUserDoc
                    ?.collection('friendRequests')
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
            builder: (context, snapshot) {
              final requestCount = snapshot.data?.docs.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    color: AppColors.primary,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddFriendDialog(),
                      );
                    },
                  ),
                  if (requestCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          requestCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            const Tab(text: 'My Friends'),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseService.currentUserDoc
                      ?.collection('friendRequests')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
              builder: (context, snapshot) {
                final requestCount = snapshot.data?.docs.length ?? 0;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Requests'),
                      if (requestCount > 0) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            requestCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_FriendsListTab(), _FriendRequestsTab()],
      ),
    );
  }
}

class _FriendsListTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Friend>>(
      stream: SocialService.getFriends(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80.sp,
                  color: AppColors.textHint,
                ),
                SizedBox(height: 16.h),
                Text(
                  'No friends yet',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Add friends to challenge each other!',
                  style: AppTextStyles.bodySmall,
                ),
                SizedBox(height: 24.h),
                AppButton(
                  text: 'Add Friend',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AddFriendDialog(),
                    );
                  },
                  width: 200.w,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: FriendCard(friend: friends[index]),
            );
          },
        );
      },
    );
  }
}

class _FriendRequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthService>().user?.uid;
    if (currentUserId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseService.firestore
              .collection('users')
              .doc(currentUserId)
              .collection('friendRequests')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mail_outline,
                  size: 80.sp,
                  color: AppColors.textHint,
                ),
                SizedBox(height: 16.h),
                Text(
                  'No friend requests',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'When someone sends you a request, it will appear here',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final requestData = requests[index].data() as Map<String, dynamic>;
            final fromUserId = requestData['fromUserId'] as String;

            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseService.firestore
                      .collection('users')
                      .doc(fromUserId)
                      .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SizedBox();
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final friend = Friend.fromMap({...userData, 'uid': fromUserId});

                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: FriendRequestCard(
                    friend: friend,
                    requestId: requests[index].id,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
