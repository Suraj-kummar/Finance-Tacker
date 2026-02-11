import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.support_agent_rounded, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Find answers to common questions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // FAQ Section
          Text(
            'Frequently Asked Questions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildFAQItem(
            context,
            'How do I add a transaction?',
            'Tap the + button at the bottom right of the home screen. Fill in the transaction details and save.',
          ),
          _buildFAQItem(
            context,
            'How do I filter transactions?',
            'Tap the Filter button on the home screen. You can filter by date (Today, Week, Month, Year) and category.',
          ),
          _buildFAQItem(
            context,
            'How do I export my data?',
            'Tap the Export button on the home screen. A PDF report will be generated with all your transactions.',
          ),
          _buildFAQItem(
            context,
            'How do I delete a transaction?',
            'Swipe left on any transaction in the list and confirm the deletion.',
          ),
          _buildFAQItem(
            context,
            'Can I use groups for shared expenses?',
            'Yes! Go to the Groups tab to create groups and split expenses with friends or family.',
          ),
          
          const SizedBox(height: 24),
          
          // Contact Section
          Text(
            'Need More Help?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildContactCard(
            context,
            Icons.email_rounded,
            'Email Support',
            'work8abhishek@gmail.com',
            colorScheme,
          ),
          _buildContactCard(
            context,
            Icons.bug_report_rounded,
            'Report a Bug',
            'work8abhishek@gmail.com',
            colorScheme,
          ),
        ],
      ),
    );
  }
  
  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
