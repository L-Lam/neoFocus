import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../models/blog_post_model.dart';
import '../services/social_service.dart';
import 'post_detail_dialog.dart';

class BlogPostCard extends StatelessWidget {
  final BlogPost post;

  const BlogPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthService>().user?.uid;
    final isLiked = post.likes.contains(currentUserId);

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => PostDetailDialog(post: post),
        );
      },
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author and time
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      post.authorName[0].toUpperCase(),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatTime(post.createdAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                if (post.isPinned)
                  Icon(Icons.push_pin, color: AppColors.primary, size: 20.sp),
              ],
            ),
            SizedBox(height: 16.h),
            // Title
            Text(
              post.title,
              style: AppTextStyles.heading3,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.h),
            // Content preview
            Text(
              post.content,
              style: AppTextStyles.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            // Tags
            if (post.tags.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                children:
                    post.tags.map((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
            SizedBox(height: 16.h),
            // Actions
            Row(
              children: [
                InkWell(
                  onTap: () async {
                    await SocialService.likeBlogPost(post.id);
                  },
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color:
                            isLiked ? AppColors.error : AppColors.textSecondary,
                        size: 20.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${post.likes.length}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Row(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      color: AppColors.textSecondary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text('${post.commentCount}', style: AppTextStyles.caption),
                  ],
                ),
                const Spacer(),
                Text(
                  'Read more',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
