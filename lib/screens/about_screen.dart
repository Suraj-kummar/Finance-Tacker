import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Icon & Name
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Finance Tracker Pro',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version 2.0.0',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Description
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      const Text(
                        'About This App',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Finance Tracker Pro helps you manage your daily expenses and income with ease. Track transactions, create groups for shared expenses, generate reports, and gain insights into your spending habits.',
                    style: TextStyle(
                      height: 1.6,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Features
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      const Text(
                        'Key Features',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(context, Icons.add_circle_outline, 'Track income and expenses'),
                  _buildFeatureItem(context, Icons.filter_list_rounded, 'Advanced filtering by date and category'),
                  _buildFeatureItem(context, Icons.picture_as_pdf_rounded, 'Export to PDF reports'),
                  _buildFeatureItem(context, Icons.group_rounded, 'Group expenses with friends'),
                  _buildFeatureItem(context, Icons.pie_chart_rounded, 'Visual statistics and insights'),
                  _buildFeatureItem(context, Icons.dark_mode_rounded, 'Dark mode support'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Developer Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.code_rounded, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      const Text(
                        'Developer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Developed with ❤️ by Abhishek & Team',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2024 Finance Tracker Pro. All rights reserved.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Links
          _buildLinkButton(context, Icons.privacy_tip_rounded, 'Privacy Policy', colorScheme),
          const SizedBox(height: 12),
          _buildLinkButton(context, Icons.description_rounded, 'Terms of Service', colorScheme),
          const SizedBox(height: 12),
          _buildLinkButton(context, Icons.open_in_new_rounded, 'Visit Website', colorScheme),
        ],
      ),
    );
  }
  
  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.privacy_tip_rounded, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      "Privacy Policy", 
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildPolicySection(
                      context, 
                      "1. Introduction", 
                      "Finance Tracker PRO (“the App”) is developed and maintained by Abhishek Patel. This Privacy Policy explains how the App handles user information and device permissions. By using the App, you agree to the terms described in this Privacy Policy."
                    ),
                    _buildPolicySection(
                      context, 
                      "2. Information We Collect", 
                      "Finance Tracker PRO is an offline personal finance application.\n\nThe App does not collect, store, or transmit any personal information to external servers. All your financial data (transactions, notes, categories, and imports) remains locally stored on your device.\n\nThe App does not:\n• Collect personal or financial data\n• Upload files to any server\n• Use third-party tracking or analytics\n• Share any information with advertisers"
                    ),
                    _buildPolicySection(
                      context, 
                      "3. Use of Storage Permissions", 
                      "Finance Tracker PRO requires Read/Write Storage Access solely for the following purposes:\n• Importing statements (PDF, CSV, Excel)\n• Exporting reports (PDF or Excel)\n• Saving files locally on the device\n\nNo imported or exported data is uploaded, shared, or transmitted online."
                    ),
                    _buildPolicySection(
                      context, 
                      "4. No Advertisements", 
                      "The App does not display ads and does not use any advertising SDKs or ad networks."
                    ),
                     _buildPolicySection(
                      context, 
                      "5. No Internet Data Collection", 
                      "The App may use internet access for checking versions or loading external libraries, but it does not send or store any user data online."
                    ),
                    _buildPolicySection(
                      context, 
                      "6. Security", 
                      "Your data remains entirely on your device. We do not collect or store passwords, banking details, or sensitive information on any external server. You are responsible for maintaining the security of your device (PIN, password, lock screen, etc.)."
                    ),
                    _buildPolicySection(
                      context, 
                      "7. Third-Party Services", 
                      "Finance Tracker PRO does not use:\n• Analytics services\n• Tracking tools\n• Cloud storage\n• External APIs that collect data"
                    ),
                    _buildPolicySection(
                      context, 
                      "8. Children’s Privacy", 
                      "The App does not target children under the age of 13 and does not knowingly collect any data from them."
                    ),
                    _buildPolicySection(
                      context, 
                      "9. Changes to This Policy", 
                      "We may update this Privacy Policy periodically. Users are advised to review this page regularly for updates."
                    ),
                    _buildPolicySection(
                      context, 
                      "10. Contact Information", 
                      "If you have any questions or concerns regarding this Privacy Policy, please contact:\n\nAbhishek Patel\nEmail: work8abhishek@gmail.com"
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        "Last updated: December 2025",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsAndConditions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.description_rounded, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      "Terms of Service", 
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildPolicySection(
                      context, 
                      "1. Acceptance of Terms", 
                      "By downloading and using Finance Tracker Pro, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application."
                    ),
                    _buildPolicySection(
                      context, 
                      "2. Use of the Application", 
                      "Finance Tracker Pro is a personal finance management tool. You agree to use the app only for lawful purposes and in a way that does not infringe the rights of, restrict or inhibit anyone else's use and enjoyment of the application."
                    ),
                    _buildPolicySection(
                      context, 
                      "3. No Financial Advice", 
                      "The content and tools provided in this app are for informational and planning purposes only. They do not constitute professional financial advice. Always consult with a qualified financial advisor for significant financial decisions."
                    ),
                    _buildPolicySection(
                      context, 
                      "4. User Responsibility", 
                      "You are solely responsible for the accuracy of the data you enter into the application. We are not responsible for any financial losses or damages arising from reliance on the calculations or data presented by the app."
                    ),
                    _buildPolicySection(
                      context, 
                      "5. Limitation of Liability", 
                      "To the maximum extent permitted by law, Finance Tracker Pro and its developers shall not be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of data or profits."
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        "Last updated: December 2024",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkButton(BuildContext context, IconData icon, String label, ColorScheme colorScheme) {
    return OutlinedButton(
      onPressed: () async {
        if (label == 'Privacy Policy') {
          _showPrivacyPolicy(context);
        } else if (label == 'Terms of Service') {
          _showTermsAndConditions(context);
        } else if (label == 'Visit Website') {
            final Uri url = Uri.parse('https://github.com/abhishek0112cs221008/Finance-Tracker');
            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch URL')));
                }
            }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label - Coming Soon')),
          );
        }
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
