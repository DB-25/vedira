import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.secondary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Privacy Matters',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We are committed to protecting your personal information and being transparent about how we use it.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Last updated: June 9, 2025',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '1. Information We Collect',
              content: '''**Personal Information:**
• Email address (required for account creation and sign-in)
• Phone number (required for account verification and recovery)
• User ID (automatically generated unique identifier)

**Learning Content Data:**
• Course topics and preferences you specify
• Course plans and lesson content you generate
• Multiple choice questions and quiz responses
• Learning progress and course completion status

**Technical Information:**
• Device information and app usage analytics
• API request logs for troubleshooting and performance optimization
• Authentication tokens for secure access''',
              theme: theme,
              colorScheme: colorScheme,
            ),

            _buildSection(
              title: '2. How We Use Your Information',
              content: '''**Account Management:**
• Create and maintain your user account
• Authenticate your identity and secure account access
• Send verification codes via email and SMS
• Enable password recovery through email and phone

**Educational Services:**
• Generate personalized course plans based on your topics and preferences
• Create lesson content and learning materials
• Generate practice questions and assessments
• Track your learning progress across courses

**Service Operations:**
• Store your course data and learning materials
• Process AI-generated content using third-party services
• Maintain system performance and security
• Provide customer support''',
              theme: theme,
              colorScheme: colorScheme,
            ),

            _buildSection(
              title: '3. Data Storage and Processing',
              content: '''**Our Infrastructure:**
• User account data stored in Amazon DynamoDB (encrypted at rest)
• Course plans and user progress stored in secure cloud databases
• Lesson content and learning materials stored in Amazon S3 buckets
• All data hosted on Amazon Web Services (AWS) infrastructure in the United States

**Third-Party AI Services:**
• Course content generated using Google Gemini AI (generativelanguage.googleapis.com)
• Advanced content generated using Anthropic Claude AI via AWS Bedrock
• Learning content sent to these services is processed but not permanently stored by the AI providers''',
              theme: theme,
              colorScheme: colorScheme,
            ),

            _buildSection(
              title: '4. Data Sharing',
              content: '''We **DO NOT** sell your personal information.

We share data only in these limited circumstances:
• With AI service providers (Google, Anthropic) solely for content generation
• With AWS services for hosting and infrastructure
• When required by law or to protect our legal rights
• With your explicit consent''',
              theme: theme,
              colorScheme: colorScheme,
            ),

            _buildSection(
              title: '5. Data Security',
              content: '''**Security Measures:**
• Industry-standard encryption for data transmission and storage
• Secure authentication using AWS Cognito
• Regular security audits and monitoring
• Access controls limiting employee access to user data

**Password Requirements:**
• Minimum 8 characters
• Must include uppercase and lowercase letters
• Must include numbers and special characters''',
              theme: theme,
              colorScheme: colorScheme,
            ),

            _buildSection(
              title: '6. Data Retention',
              content: '''• Account data retained while your account is active
• Course content and learning progress retained to provide continuous service
• Account data deleted within 30 days of account deletion request
• Backups may retain data for up to 90 days for disaster recovery''',
              theme: theme,
              colorScheme: colorScheme,
            ),

            _buildSection(
              title: '7. Your Rights',
              content: '''You have the right to:
• Access your personal data
• Correct inaccurate information
• Delete your account and associated data
• Export your course content and learning data
• Opt out of non-essential communications

**To exercise these rights:**
• Contact us at dhruvbaradiya@gmail.com
• Use in-app settings to manage your preferences
• Request account deletion through app settings''',
              theme: theme,
              colorScheme: colorScheme,
            ),

            _buildSection(
              title: '8. Children\'s Privacy',
              content:
                  '''This service is not intended for children under 13. We do not knowingly collect personal information from children under 13. If we discover we have collected such information, we will delete it immediately.''',
              theme: theme,
              colorScheme: colorScheme,
            ),

            _buildSection(
              title: '9. International Users',
              content:
                  '''Our services are hosted in the United States. By using the app, you consent to the transfer of your data to the US, where privacy laws may differ from your country.''',
              theme: theme,
              colorScheme: colorScheme,
            ),

            _buildSection(
              title: '10. Changes to Privacy Policy',
              content:
                  '''We may update this policy periodically. We will notify you of significant changes through the app or email. Continued use after changes constitutes acceptance of the updated policy.''',
              theme: theme,
              colorScheme: colorScheme,
            ),

            _buildSection(
              title: '11. Contact Information',
              content: '''For privacy-related questions or requests:
• **Email**: dhruvbaradiya@gmail.com
• **In-app contact form**: Available through app settings
• **Response Time**: We aim to respond within 48 hours''',
              theme: theme,
              colorScheme: colorScheme,
            ),

            _buildSection(
              title: '12. Data Processing Legal Basis (for EU users)',
              content: '''We process your data based on:
• **Contract performance** (providing educational services)
• **Legitimate interests** (improving our services)
• **Consent** (for marketing communications)''',
              theme: theme,
              colorScheme: colorScheme,
            ),

            const SizedBox(height: 32),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.verified_user,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Privacy Commitment',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We are committed to maintaining the highest standards of privacy protection and data security for all our users.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
            ),
            child: _buildRichText(content, theme, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildRichText(
    String content,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final List<TextSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');

    int lastIndex = 0;
    for (final match in boldPattern.allMatches(content)) {
      // Add text before the bold part
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: content.substring(lastIndex, match.start),
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
        );
      }

      // Add the bold text
      spans.add(
        TextSpan(
          text: match.group(1),
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: colorScheme.onSurface.withOpacity(0.9),
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < content.length) {
      spans.add(
        TextSpan(
          text: content.substring(lastIndex),
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: colorScheme.onSurface.withOpacity(0.9),
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}
