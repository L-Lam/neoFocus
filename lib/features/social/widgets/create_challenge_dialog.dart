import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import '../../../widgets/app_button.dart';
import '../models/challenge_model.dart';
import '../services/social_service.dart';

class CreateChallengeDialog extends StatefulWidget {
  const CreateChallengeDialog({super.key});

  @override
  State<CreateChallengeDialog> createState() => _CreateChallengeDialogState();
}

class _CreateChallengeDialogState extends State<CreateChallengeDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetMinutesController = TextEditingController();
  ChallengeType _selectedType = ChallengeType.friend;
  int _durationDays = 7;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetMinutesController.dispose();
    super.dispose();
  }

  Future<void> _createChallenge() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _targetMinutesController.text.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = context.read<AuthService>().user!;
      final challenge = Challenge(
        id: '',
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
        status: ChallengeStatus.active,
        targetMinutes: int.parse(_targetMinutesController.text),
        currentMinutes: 0,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: _durationDays)),
        participants: [currentUser.uid],
        createdBy: currentUser.uid,
        participantProgress: {currentUser.uid: 0},
        rewardPoints: int.parse(_targetMinutesController.text) * 2,
      );

      await SocialService.createChallenge(challenge);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge created!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        constraints: BoxConstraints(maxWidth: 500.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Challenge', style: AppTextStyles.heading2),
              SizedBox(height: 24.h),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Challenge Title',
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
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
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
              Text(
                'Challenge Type',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                children:
                    [ChallengeType.friend, ChallengeType.group].map((type) {
                      return ChoiceChip(
                        label: Text(
                          type == ChallengeType.friend ? 'Friend' : 'Group',
                        ),
                        selected: _selectedType == type,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedType = type);
                          }
                        },
                      );
                    }).toList(),
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
                      text: 'Create',
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
