import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/loading_indicator.dart';
import '../services/social_service.dart';
import '../models/blog_post_model.dart';
import '../widgets/blog_post_card.dart';
import '../widgets/create_post_dialog.dart';

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BlogScreenContent();
  }
}

class _BlogScreenContent extends StatefulWidget {
  const _BlogScreenContent();

  @override
  State<_BlogScreenContent> createState() => _BlogScreenContentState();
}

class _BlogScreenContentState extends State<_BlogScreenContent> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Community Blog', style: AppTextStyles.heading3),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            color: AppColors.primary,
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const CreatePostDialog(),
              );
            },
          )
        ]
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
