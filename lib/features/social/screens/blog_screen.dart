import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/loading_indicator.dart';
import '../services/social_service.dart';
import '../services/blog_restriction_service.dart';
import '../models/blog_post_model.dart';
import '../widgets/blog_post_card.dart';
import '../widgets/create_post_dialog.dart';

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BlogRestrictionService(),
      child: const _BlogScreenContent(),
    );
  }
}

class _BlogScreenContent extends StatefulWidget {
  const _BlogScreenContent();

  @override
  State<_BlogScreenContent> createState() => _BlogScreenContentState();
}

class _BlogScreenContentState extends State<_BlogScreenContent>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<BlogRestrictionService>().startSession();
  }

  @override
  void dispose() {
    context.read<BlogRestrictionService>().endSession();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final restrictionService = context.read<BlogRestrictionService>();
    if (state == AppLifecycleState.paused) {
      restrictionService.endSession();
    } else if (state == AppLifecycleState.resumed) {
      restrictionService.startSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final restrictionService = context.watch<BlogRestrictionService>();

    if (!restrictionService.isAccessAllowed) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text('Community Blog', style: AppTextStyles.heading3),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_off, size: 80.sp, color: AppColors.textHint),
              SizedBox(height: 24.h),
              Text('Daily limit reached', style: AppTextStyles.heading2),
              SizedBox(height: 12.h),
              Text(
                'You\'ve used your 30 minutes for today.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Come back tomorrow to continue!',
                style: AppTextStyles.bodySmall,
              ),
              SizedBox(height: 32.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Time to focus on your goals!',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Community Blog', style: AppTextStyles.heading3),
        actions: [
          // Time remaining indicator
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, color: AppColors.warning, size: 16.sp),
                SizedBox(width: 4.w),
                Text(
                  restrictionService.getTimeRemaining(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle),
            color: AppColors.primary,
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const CreatePostDialog(),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<BlogPost>>(
        stream: SocialService.getBlogPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 80.sp,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No posts yet',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Be the first to share your thoughts!',
                    style: AppTextStyles.bodySmall,
                  ),
                  SizedBox(height: 24.h),
                  AppButton(
                    text: 'Create Post',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const CreatePostDialog(),
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
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: BlogPostCard(post: posts[index]),
              );
            },
          );
        },
      ),
    );
  }
}
