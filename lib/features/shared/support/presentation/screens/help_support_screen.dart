import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/models/user.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';

/// Help & Support screen following Apple HIG principles:
/// - Clarity: Clear information hierarchy and easy navigation
/// - Deference: Content-first design with helpful guidance
/// - Depth: Subtle visual hierarchy
class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitSupportRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // TODO: Implement actual support request submission
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support request submitted successfully! We\'ll get back to you soon.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _subjectController.clear();
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Help & Support'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'FAQ'),
              Tab(text: 'Contact'),
              Tab(text: 'Guides'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              // FAQ Tab
              _buildFAQTab(context, isDark, responsive),
              // Contact Tab
              _buildContactTab(context, isDark, responsive, user),
              // Guides Tab
              _buildGuidesTab(context, isDark, responsive),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQTab(BuildContext context, bool isDark, Responsive responsive) {
    final faqs = [
      {
        'question': 'How do I track my workouts?',
        'answer':
            'Navigate to the Workouts section from your dashboard. Select a workout assigned by your coach and tap "Start Workout" to begin tracking your exercises, sets, and reps.',
      },
      {
        'question': 'How do I log my water intake?',
        'answer':
            'Go to the Water Tracking section and tap the water drop buttons to quickly log your intake, or use the custom amount field for precise tracking.',
      },
      {
        'question': 'How do I view my progress?',
        'answer':
            'Visit the Progress section to see your body measurements, progress photos, and workout statistics over time.',
      },
      {
        'question': 'How do I message my coach?',
        'answer':
            'Go to the Messages section and select your coach\'s conversation to send messages, share progress updates, or ask questions.',
      },
      {
        'question': 'How do I update my profile?',
        'answer':
            'Navigate to your Profile, tap "Edit", make your changes, and tap "Save Changes".',
      },
      {
        'question': 'How do I reset my password?',
        'answer':
            'On the login screen, tap "Forgot Password?" and enter your email address. You\'ll receive instructions to reset your password.',
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.padding.left,
        vertical: responsive.padding.top,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
          child: Column(
            children: [
              const SizedBox(height: 16),
              ...faqs.map((faq) => _FAQItem(
                    question: faq['question']!,
                    answer: faq['answer']!,
                    isDark: isDark,
                  )),
              SizedBox(height: responsive.padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTab(
    BuildContext context,
    bool isDark,
    Responsive responsive,
    User? user,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.padding.left,
        vertical: responsive.padding.top,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Contact Support',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Have a question or need help? Send us a message and we\'ll get back to you as soon as possible.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    hintText: 'What can we help you with?',
                    prefixIcon: const Icon(Icons.subject_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a subject';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    hintText: 'Describe your issue or question...',
                    prefixIcon: const Icon(Icons.message_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 6,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a message';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitSupportRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Message'),
                ),
                const SizedBox(height: 24),
                // Quick Contact Options
                _ContactOptionTile(
                  icon: Icons.email_rounded,
                  title: 'Email Support',
                  subtitle: 'support@coachclientapp.com',
                  onTap: () async {
                    final email = Uri(
                      scheme: 'mailto',
                      path: 'support@coachclientapp.com',
                      query: user != null
                          ? 'subject=Support Request&body=User: ${user.email}'
                          : 'subject=Support Request',
                    );
                    if (await canLaunchUrl(email)) {
                      await launchUrl(email);
                    }
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _ContactOptionTile(
                  icon: Icons.phone_rounded,
                  title: 'Phone Support',
                  subtitle: '+1 (555) 123-4567',
                  onTap: () async {
                    final phone = Uri(scheme: 'tel', path: '+15551234567');
                    if (await canLaunchUrl(phone)) {
                      await launchUrl(phone);
                    }
                  },
                  isDark: isDark,
                ),
                SizedBox(height: responsive.padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuidesTab(BuildContext context, bool isDark, Responsive responsive) {
    final guides = [
      {
        'title': 'Getting Started',
        'description': 'Learn the basics of using the app',
        'icon': Icons.play_circle_outline_rounded,
      },
      {
        'title': 'Tracking Workouts',
        'description': 'How to log and track your workouts',
        'icon': Icons.fitness_center_rounded,
      },
      {
        'title': 'Managing Clients',
        'description': 'For coaches: How to manage your clients',
        'icon': Icons.people_rounded,
      },
      {
        'title': 'Meal Plans',
        'description': 'Creating and following meal plans',
        'icon': Icons.restaurant_rounded,
      },
      {
        'title': 'Progress Tracking',
        'description': 'How to track and view your progress',
        'icon': Icons.trending_up_rounded,
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.padding.left,
        vertical: responsive.padding.top,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
          child: Column(
            children: [
              const SizedBox(height: 16),
              ...guides.map((guide) => _GuideCard(
                    title: guide['title'] as String,
                    description: guide['description'] as String,
                    icon: guide['icon'] as IconData,
                    isDark: isDark,
                    onTap: () {
                      // TODO: Navigate to guide detail or open guide content
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${guide['title'] as String} guide coming soon'),
                        ),
                      );
                    },
                  )),
              SizedBox(height: responsive.padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

/// FAQ Item - Expandable question/answer
class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;
  final bool isDark;

  const _FAQItem({
    required this.question,
    required this.answer,
    required this.isDark,
  });

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDark
            ? AppTheme.darkSurfaceColor
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: widget.isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.question,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Icon(
              _isExpanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
            ),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.answer,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: widget.isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Contact Option Tile
class _ContactOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _ContactOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

/// Guide Card
class _GuideCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _GuideCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}


