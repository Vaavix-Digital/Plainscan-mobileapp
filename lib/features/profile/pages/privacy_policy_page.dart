import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Privacy Policy'.tr,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.text,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Privacy Policy and Secure Document Processing'),
            _buildParagraph('Files temporarily stored and deleted within 24 hours.'),
            
            _buildSectionHeader('File Storage and Deletion'),
            _buildParagraph(
              'At Plainscan, we are committed to your privacy. While document and image processing requires files to be uploaded to our secure servers, we ensure they are not kept longer than necessary.\n\n'
              'Files are temporarily stored and deleted within 24 hours. We do not permanently store or share your sensitive files.'
            ),

            _buildSectionHeader('Device Permissions (Camera & Photos)'),
            _buildParagraph(
              'To provide core scanning functionality, our App requests access to your device\'s Camera and Photo Gallery. This access is strictly used to capture or import documents for processing. We do not access or collect any photos other than the ones you explicitly select for processing.'
            ),

            _buildSectionHeader('What Data We Collect'),
            _buildParagraph(
              'We do not collect or store the contents of your documents or images. We only collect minimal information for basic app functionality and performance monitoring:\n\n'
              '• Technical Data: Anonymised usage statistics such as app interactions, device models, and crash reports, collected only to improve our tool performance.\n'
              '• Subscription Data: If you choose to subscribe to our Pro features, we securely manage your account and billing information via trusted partners like Apple (In-App Purchases), Razorpay, and Stripe.\n'
              '• Third-Party Data: We use services like Google AdMob and Google Analytics which may collect data (such as device identifiers) to provide analytics and serve relevant advertisements.'
            ),

            _buildSectionHeader('Account Deletion'),
            _buildParagraph(
              'You have full control over your data. You can permanently delete your account and all associated data at any time directly within the app.\n\n'
              'How to delete your account:\n'
              '1. Go to the "Profile" tab.\n'
              '2. Scroll to the bottom and tap "Delete Account".\n'
              '3. Confirm your choice.\n\n'
              'Upon deletion, your user record, processing history, and local data are wiped immediately. Please note that active Apple Subscriptions must be cancelled separately in your device\'s Apple ID settings.'
            ),

            _buildSectionHeader('App Data & Local Storage'),
            _buildParagraph(
              'Plainscan uses local device storage and secure tokens to maintain your session and preferences. We also use advertising and analytics identifiers to support our free services and improve user experience.'
            ),

            _buildSectionHeader('Your Rights & Regional Compliance'),
            _buildParagraph(
              'Since your processing files are only stored temporarily and deleted within 24 hours, there is no permanent document data on our servers for you to request access to or deletion of. However, if you have a registered account, you have full control over your profile data.\n\n'
              'We strive to comply with global privacy standards, including:\n\n'
              '• GDPR (Europe): We process data based on your consent and for the performance of our services.\n'
              '• CCPA/CPRA (California): We do not "sell" your personal information. You have the right to request disclosure or deletion of your account data.\n'
              '• DPDP Act (India): We handle your personal data in accordance with the Digital Personal Data Protection Act of India.'
            ),

            _buildSectionHeader('Advertising'),
            _buildParagraph(
              'This App uses third-party advertising networks, such as Google AdMob and Monumetric, to place advertisements. These networks may collect and use device identifiers and usage data to serve personalized ads.'
            ),

            _buildSectionHeader('Contact Us'),
            _buildParagraph(
              'Vaavix Technologies\n\n'
              'Email: contact@plainscan.com\n'
              'Pallath Building, Building No. 7/96, Mulayankavu Mappattukara Road, Near Sajan Hotel, Mappattukara, Kulukkallur, Palakkad (Dist), Kerala, India 679337'
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        height: 1.5,
        color: AppColors.text,
      ),
    );
  }
}
