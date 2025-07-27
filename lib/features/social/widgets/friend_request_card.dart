import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../widgets/app_button.dart';
import '../models/friend_model.dart';
import '../services/social_service.dart';

class FriendRequestCard extends StatefulWidget {
  final Friend friend;
  final String requestId;

  const FriendRequestCard({
    super.key,
    required this.friend,
    required this.requestId,
  });

  @override
  State<FriendRequestCard> createState() => _FriendRequestCardState();
}

class _FriendRequestCardState extends State<FriendRequestCard> {
  bool _isAccepting = false;
  bool _isDeclining = false;

  Future<void> _acceptRequest() async {
    setState(() => _isAccepting = true);

    try {
      await SocialService.acceptFriendRequest(widget.friend.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You are now friends with ${widget.friend.displayName}!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isAccepting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept friend request'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _declineRequest() async {
    setState(() => _isDeclining = true);

    try {
      await SocialService.declineFriendRequest(widget.friend.uid);
    } catch (e) {
      setState(() => _isDeclining = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to decline friend request'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.friend.displayName[0].toUpperCase(),
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.friend.displayName,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(widget.friend.email, style: AppTextStyles.caption),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.bolt, size: 16.sp, color: AppColors.warning),
                        SizedBox(width: 4.w),
                        Text(
                          'Level ${widget.friend.level}',
                          style: AppTextStyles.caption,
                        ),
                        SizedBox(width: 12.w),
                        Icon(
                          Icons.timer,
                          size: 16.sp,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${widget.friend.totalFocusMinutes} min',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Decline',
                  onPressed: _declineRequest,
                  isLoading: _isDeclining,
                  isOutlined: true,
                  color: AppColors.error,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: AppButton(
                  text: 'Accept',
                  onPressed: _acceptRequest,
                  isLoading: _isAccepting,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
