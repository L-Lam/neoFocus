import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../services/app_blocker_service.dart';

class BlockedAppsSelector extends StatefulWidget {
  final List<String> selectedApps;
  final Function(List<String>) onAppsChanged;

  const BlockedAppsSelector({
    super.key,
    required this.selectedApps,
    required this.onAppsChanged,
  });

  @override
  State<BlockedAppsSelector> createState() => _BlockedAppsSelectorState();
}

class _BlockedAppsSelectorState extends State<BlockedAppsSelector> {
  late AppBlockerService _blockerService;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _blockerService = AppBlockerService();
  }

  @override
  void dispose() {
    _blockerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _blockerService,
      child: Consumer<AppBlockerService>(
        builder: (context, blocker, child) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultRadius,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        Icon(Icons.block, color: AppColors.error, size: 24.sp),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Block Distracting Apps',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (widget.selectedApps.isNotEmpty) ...[
                                SizedBox(height: 4.h),
                                Text(
                                  '${widget.selectedApps.length} apps selected',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isExpanded) ...[
                  Divider(height: 1, color: AppColors.divider),
                  Container(
                    constraints: BoxConstraints(maxHeight: 300.h),
                    child:
                        blocker.installedApps.isEmpty
                            ? Padding(
                              padding: EdgeInsets.all(24.w),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16.h),
                                    Text(
                                      'Loading apps...',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            : ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              itemCount: blocker.installedApps.length,
                              itemBuilder: (context, index) {
                                final app = blocker.installedApps[index];
                                final isSelected = widget.selectedApps.contains(
                                  app.packageName,
                                );

                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (value) {
                                    final newList = List<String>.from(
                                      widget.selectedApps,
                                    );

                                    if (value == true) {
                                      newList.add(app.packageName);
                                    } else {
                                      newList.remove(app.packageName);
                                    }

                                    widget.onAppsChanged(newList);
                                  },
                                  title: Text(
                                    app.name, // Changed from app.appName
                                    style: AppTextStyles.body,
                                  ),
                                  subtitle: Text(
                                    app.packageName,
                                    style: AppTextStyles.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  secondary:
                                      app.icon != null
                                          ? Image.memory(
                                            app.icon!, // Changed to use null-aware operator
                                            width: 40.w,
                                            height: 40.w,
                                          )
                                          : Icon(
                                            Icons.android,
                                            size: 40.sp,
                                            color: AppColors.textHint,
                                          ),
                                  dense: true,
                                  controlAffinity:
                                      ListTileControlAffinity.trailing,
                                );
                              },
                            ),
                  ),
                  if (blocker.installedApps.isNotEmpty) ...[
                    Divider(height: 1, color: AppColors.divider),
                    Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              widget.onAppsChanged([]);
                            },
                            child: Text(
                              'Clear All',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Select common distracting apps
                              final commonApps = [
                                'com.facebook.katana',
                                'com.instagram.android',
                                'com.twitter.android',
                                'com.zhiliaoapp.musically', // TikTok
                                'com.reddit.frontpage',
                                'com.snapchat.android',
                                'com.whatsapp',
                                'com.discord',
                              ];

                              final availableApps =
                                  blocker.installedApps
                                      .where(
                                        (app) => commonApps.contains(
                                          app.packageName,
                                        ),
                                      )
                                      .map((app) => app.packageName)
                                      .toList();

                              widget.onAppsChanged(availableApps);
                            },
                            child: Text(
                              'Select Common',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
