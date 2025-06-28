import 'package:flutter/material.dart';
import '../models/section.dart';
import '../models/user_progress.dart';
import '../models/chapter_status.dart';
import '../utils/theme_manager.dart';
import '../utils/constants.dart';

class StudyChapterCard extends StatelessWidget {
  final Section section;
  final ChapterProgress? progress;
  final ChapterStatus? status;
  final VoidCallback? onTap;
  final VoidCallback? onGenerateContent;

  const StudyChapterCard({
    super.key,
    required this.section,
    this.progress,
    this.status,
    this.onTap,
    this.onGenerateContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Determine chapter state
    final chapterState = _getChapterState();
    final stateConfig = _getStateConfig(chapterState, colorScheme, isDark);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: stateConfig.borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: stateConfig.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: chapterState == ChapterState.ready ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with subtle background
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: stateConfig.headerBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge and progress indicator
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: stateConfig.badgeBackgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: stateConfig.badgeBorderColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                stateConfig.icon,
                                size: 16,
                                color: stateConfig.badgeTextColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                stateConfig.statusText,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: stateConfig.badgeTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (chapterState == ChapterState.generating)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: stateConfig.badgeBackgroundColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  stateConfig.badgeTextColor,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Chapter title
                    Text(
                      section.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: stateConfig.titleColor,
                        height: 1.2,
                      ),
                    ),
                    
                    if (section.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        section.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: stateConfig.descriptionColor,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Content section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content availability indicators
                    _buildContentIndicators(theme, stateConfig),
                    
                    const SizedBox(height: 20),
                    
                    // Progress section (only for ready chapters)
                    if (chapterState == ChapterState.ready) ...[
                      _buildProgressSection(theme, stateConfig),
                      const SizedBox(height: 20),
                    ],
                    
                    // Generation status (only for generating chapters)
                    if (chapterState == ChapterState.generating) ...[
                      _buildGenerationStatus(theme, stateConfig),
                      const SizedBox(height: 20),
                    ],
                    
                    // Action button
                    _buildActionButton(theme, stateConfig, chapterState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ChapterState _getChapterState() {
    final hasContent = status?.hasContent ?? false;
    final isGenerating = status?.isGenerating ?? false;
    final hasFailed = status?.hasFailed ?? false;
    
    if (hasFailed) return ChapterState.failed;
    if (isGenerating) return ChapterState.generating;
    if (hasContent) return ChapterState.ready;
    return ChapterState.locked;
  }

  StateConfig _getStateConfig(ChapterState state, ColorScheme colorScheme, bool isDark) {
    // Check if chapter is completed
    final totalLessons = section.lessons.length;
    final completedLessons = progress?.completedLessons.length ?? 0;
    final isCompleted = totalLessons > 0 && completedLessons >= totalLessons;
    
    switch (state) {
      case ChapterState.ready:
        return StateConfig(
          accentColor: isDark ? AppConstants.paletteSuccessMedium : AppConstants.paletteSuccessDark,
          borderColor: (isDark ? AppConstants.paletteSuccessMedium : AppConstants.paletteSuccessDark).withValues(alpha: 0.3),
          shadowColor: (isDark ? AppConstants.paletteSuccessMedium : AppConstants.paletteSuccessDark).withValues(alpha: 0.1),
          headerBackgroundColor: (isDark ? AppConstants.paletteSuccessDark : AppConstants.paletteSuccessLight).withValues(alpha: 0.1),
          badgeBackgroundColor: isDark ? AppConstants.paletteSuccessMedium : AppConstants.paletteSuccessDark,
          badgeTextColor: Colors.white,
          badgeBorderColor: Colors.transparent,
          titleColor: colorScheme.onSurface,
          descriptionColor: colorScheme.onSurface.withValues(alpha: 0.7),
          statusText: isCompleted ? 'Completed' : 'Ready to Study',
          icon: isCompleted ? Icons.check_circle_rounded : Icons.play_circle_fill_rounded,
          buttonText: isCompleted ? 'Review Content' : (completedLessons > 0 ? 'Continue Studying' : 'Start Studying'),
          buttonIcon: isCompleted ? Icons.refresh_rounded : Icons.arrow_forward_rounded,
        );
      
      case ChapterState.generating:
        return StateConfig(
          accentColor: colorScheme.primary,
          borderColor: colorScheme.primary.withValues(alpha: 0.3),
          shadowColor: colorScheme.primary.withValues(alpha: 0.1),
          headerBackgroundColor: colorScheme.primary.withValues(alpha: 0.08),
          badgeBackgroundColor: colorScheme.primary,
          badgeTextColor: Colors.white,
          badgeBorderColor: Colors.transparent,
          titleColor: colorScheme.onSurface,
          descriptionColor: colorScheme.onSurface.withValues(alpha: 0.7),
          statusText: 'Preparing Content',
          icon: Icons.auto_awesome_rounded,
          buttonText: 'Please wait...',
          buttonIcon: Icons.hourglass_empty_rounded,
        );
      
      case ChapterState.failed:
        return StateConfig(
          accentColor: isDark ? AppConstants.paletteErrorLight : AppConstants.paletteErrorMain,
          borderColor: (isDark ? AppConstants.paletteErrorLight : AppConstants.paletteErrorMain).withValues(alpha: 0.3),
          shadowColor: (isDark ? AppConstants.paletteErrorLight : AppConstants.paletteErrorMain).withValues(alpha: 0.1),
          headerBackgroundColor: (isDark ? AppConstants.paletteErrorMain : AppConstants.paletteErrorLight).withValues(alpha: 0.1),
          badgeBackgroundColor: isDark ? AppConstants.paletteErrorLight : AppConstants.paletteErrorMain,
          badgeTextColor: Colors.white,
          badgeBorderColor: Colors.transparent,
          titleColor: colorScheme.onSurface,
          descriptionColor: colorScheme.onSurface.withValues(alpha: 0.7),
          statusText: 'Generation Failed',
          icon: Icons.error_rounded,
          buttonText: 'Try Again',
          buttonIcon: Icons.refresh_rounded,
        );
      
      case ChapterState.locked:
      default:
        return StateConfig(
          accentColor: isDark ? AppConstants.paletteTertiary : AppConstants.paletteAction,
          borderColor: (isDark ? AppConstants.paletteTertiary : AppConstants.paletteAction).withValues(alpha: 0.3),
          shadowColor: (isDark ? AppConstants.paletteTertiary : AppConstants.paletteAction).withValues(alpha: 0.1),
          headerBackgroundColor: (isDark ? AppConstants.paletteTertiary : AppConstants.paletteAction).withValues(alpha: 0.08),
          badgeBackgroundColor: isDark ? AppConstants.paletteTertiary : AppConstants.paletteAction,
          badgeTextColor: Colors.white,
          badgeBorderColor: Colors.transparent,
          titleColor: colorScheme.onSurface,
          descriptionColor: colorScheme.onSurface.withValues(alpha: 0.7),
          statusText: 'Ready to Create',
          icon: Icons.lock_open_rounded,
          buttonText: 'Prepare Content',
          buttonIcon: Icons.auto_fix_high_rounded,
        );
    }
  }

  Widget _buildContentIndicators(ThemeData theme, StateConfig stateConfig) {
    final hasLessons = status?.hasContent ?? false;
    final hasFlashcards = status?.hasFlashcards ?? false;
    final hasQuizzes = status?.hasMcqs ?? false;
    
    // Only build indicators for available content
    List<Widget> availableIndicators = [];
    
    if (hasLessons) {
      availableIndicators.add(
        _buildContentIndicator(
          theme,
          stateConfig,
          Icons.book_rounded,
          'Lessons',
          section.lessons.length,
          theme.colorScheme.primary,
        ),
      );
    }
    
    if (hasFlashcards) {
      availableIndicators.add(
        _buildContentIndicator(
          theme,
          stateConfig,
          Icons.style_rounded,
          'Flashcards',
          null,
          theme.colorScheme.tertiary,
        ),
      );
    }
    
    if (hasQuizzes) {
      availableIndicators.add(
        _buildContentIndicator(
          theme,
          stateConfig,
          Icons.quiz_rounded,
          'Quiz',
          null,
          theme.colorScheme.secondary,
        ),
      );
    }
    
    // If no content is available, show a placeholder message
    if (availableIndicators.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.outline.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 16,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Text(
              'Content will appear here once ready',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }
    
    // Add spacing between indicators
    List<Widget> indicatorsWithSpacing = [];
    for (int i = 0; i < availableIndicators.length; i++) {
      indicatorsWithSpacing.add(Expanded(child: availableIndicators[i]));
      if (i < availableIndicators.length - 1) {
        indicatorsWithSpacing.add(const SizedBox(width: 12));
      }
    }
    
    return Row(children: indicatorsWithSpacing);
  }

  Widget _buildContentIndicator(
    ThemeData theme,
    StateConfig stateConfig,
    IconData icon,
    String label,
    int? count,
    Color indicatorColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: indicatorColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: indicatorColor,
          ),
          const SizedBox(height: 4),
          Text(
            count != null ? '$count $label' : label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: indicatorColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(ThemeData theme, StateConfig stateConfig) {
    final totalLessons = section.lessons.length;
    final completedLessons = progress?.completedLessons.length ?? 0;
    final progressPercent = totalLessons > 0 ? (completedLessons / totalLessons) : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: stateConfig.accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stateConfig.accentColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 18,
                color: stateConfig.accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Progress',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: stateConfig.accentColor,
                ),
              ),
              const Spacer(),
              Text(
                '${(progressPercent * 100).round()}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: stateConfig.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 6,
              backgroundColor: stateConfig.accentColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(stateConfig.accentColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completedLessons of $totalLessons lessons completed',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerationStatus(ThemeData theme, StateConfig stateConfig) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: stateConfig.accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stateConfig.accentColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_rounded,
                size: 18,
                color: stateConfig.accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                'AI is Creating Your Content',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: stateConfig.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Lessons, quizzes, and flashcards are being prepared for you. This usually takes 5-10 minutes.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme, StateConfig stateConfig, ChapterState state) {
    final isEnabled = state == ChapterState.ready || state == ChapterState.locked || state == ChapterState.failed;
    
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isEnabled ? (state == ChapterState.ready ? onTap : onGenerateContent) : null,
        style: FilledButton.styleFrom(
          backgroundColor: isEnabled ? stateConfig.accentColor : theme.colorScheme.outline.withValues(alpha: 0.3),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isEnabled ? 2 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              stateConfig.buttonText,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              stateConfig.buttonIcon,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

enum ChapterState {
  ready,
  generating,
  locked,
  failed,
}

class StateConfig {
  final Color accentColor;
  final Color borderColor;
  final Color shadowColor;
  final Color headerBackgroundColor;
  final Color badgeBackgroundColor;
  final Color badgeTextColor;
  final Color badgeBorderColor;
  final Color titleColor;
  final Color descriptionColor;
  final String statusText;
  final IconData icon;
  final String buttonText;
  final IconData buttonIcon;

  StateConfig({
    required this.accentColor,
    required this.borderColor,
    required this.shadowColor,
    required this.headerBackgroundColor,
    required this.badgeBackgroundColor,
    required this.badgeTextColor,
    required this.badgeBorderColor,
    required this.titleColor,
    required this.descriptionColor,
    required this.statusText,
    required this.icon,
    required this.buttonText,
    required this.buttonIcon,
  });
}
