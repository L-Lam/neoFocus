import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import '../../../widgets/app_button.dart';
import '../models/challenge_model.dart';
import '../models/friend_model.dart';
import '../services/social_service.dart';

class CreateFriendChallengeDialog extends StatefulWidget {
  final Friend friend;

  const CreateFriendChallengeDialog({super.key, required this.friend});

  @override
  State<CreateFriendChallengeDialog> createState() =>
      _CreateFriendChallengeDialogState();
}

class _CreateFriendChallengeDialogState
    extends State<CreateFriendChallengeDialog> {
  final _titleController = TextEditingController();
  final _targetMinutesController = TextEditingController(text: '60');
  int _durationDays = 7;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _targetMinutesController.dispose();
    super.dispose();
  }

  Future<void> _createChallenge() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a challenge title'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = context.read<AuthService>().user!;
      final challenge = Challenge(
        id: '',
        title: _titleController.text,
        description:
            'A friendly competition between ${currentUser.displayName} and ${widget.friend.displayName}',
        type: ChallengeType.friend,
        status: ChallengeStatus.active,
        targetMinutes: int.parse(_targetMinutesController.text),
        currentMinutes: 0,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: _durationDays)),
        participants: [currentUser.uid, widget.friend.uid],
        createdBy: currentUser.uid,
        participantProgress: {currentUser.uid: 0, widget.friend.uid: 0},
        rewardPoints: int.parse(_targetMinutesController.text) * 2,
      );

      await SocialService.createChallenge(challenge);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Challenge sent to ${widget.friend.displayName}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create challenge'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        constraints: BoxConstraints(maxWidth: 400.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Challenge ${widget.friend.displayName}',
                style: AppTextStyles.heading2,
              ),
              SizedBox(height: 24.h),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Challenge Title',
                  hintText: 'e.g., Focus Marathon',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _targetMinutesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Target Minutes',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text('Duration: $_durationDays days', style: AppTextStyles.body),
              Slider(
                value: _durationDays.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                onChanged: (value) {
                  setState(() => _durationDays = value.toInt());
                },
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                      isOutlined: true,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppButton(
                      text: 'Send Challenge',
                      onPressed: _createChallenge,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
