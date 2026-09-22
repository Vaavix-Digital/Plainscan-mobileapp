import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Terms of Service'.tr,
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
            _buildSectionHeader('Terms of Service and Usage Agreement for Plainscan'),
            _buildParagraph('Last updated: March 7, 2026'),
            
            _buildSectionHeader('1. Agreement to Terms'),
            _buildParagraph(
              'By accessing or using the Plainscan mobile app ("the Service"), you agree to be bound by these Terms of Service. If you disagree with any part of these terms, you may not access the Service. These terms apply to all visitors, users, and others who access or use the Service.'
            ),

            _buildSectionHeader('2. Use of Service & Uploaded Content'),
            _buildParagraph(
              'Plainscan provides document processing tools including OCR, PDF editing, and conversion.\n\n'
              'Uploaded Document Responsibility:\n'
              'Users are solely responsible for the documents they upload. Plainscan does not review or verify user-uploaded content. You represent that you have all necessary rights to the content you upload.'
            ),

            _buildSectionHeader('3. User Accounts'),
            _buildParagraph(
              'When you create an account, you must provide accurate and complete information. You are responsible for safeguarding the password that you use to access the Service and for any activities or actions under your password.'
            ),

            _buildSectionHeader('4. Subscription, Payments & Refunds'),
            _buildParagraph(
              'Certain parts of the Service are billed on a subscription basis. You will be billed in advance on a recurring and periodic basis.\n\n'
              'Apple App Store Subscriptions:\n'
              'If you purchase a subscription through the Apple App Store, payment will be charged to your Apple ID account at the confirmation of purchase. The subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions by going to your App Store account settings after purchase.\n\n'
              'Refund Policy:\n'
              'Subscription fees are non-refundable except where required by applicable law. For App Store purchases, refund requests must be handled directly through Apple. For more details, please see our Refund Policy.'
            ),

            _buildSectionHeader('5. Service Availability & Disclaimer'),
            _buildParagraph(
              'The Service is provided on an "AS IS" and "AS AVAILABLE" basis.\n\n'
              'Plainscan does not guarantee uninterrupted or error-free operation of the Service. We may suspend or terminate the Service for maintenance, updates, or at our sole discretion.'
            ),

            _buildSectionHeader('6. Intellectual Property'),
            _buildParagraph(
              'The Service and its original content (excluding content provided by users), features, and functionality are and will remain the exclusive property of Plainscan and its licensors. You retain all ownership rights to the documents you upload.'
            ),

            _buildSectionHeader('7. Limitation of Liability'),
            _buildParagraph(
              'In no event shall Plainscan, nor its directors, employees, or partners, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, or other intangible losses.'
            ),

            _buildSectionHeader('8. Governing Law'),
            _buildParagraph(
              'These Terms shall be governed and construed in accordance with the laws of India, specifically the state of Kerala, without regard to its conflict of law provisions. We operate in compliance with the Consumer Protection Act, 2019 (India). Any legal action or proceeding related to your access to, or use of, the Service shall be instituted in the courts located in Palakkad, Kerala, India.'
            ),

            _buildSectionHeader('9. Changes to Terms'),
            _buildParagraph(
              'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material, we will provide at least 30 days notice prior to any new terms taking effect.'
            ),

            _buildSectionHeader('10. Contact Us'),
            _buildParagraph(
              'If you have any questions about these Terms, please contact us at:\n'
              'Vaavix Technologies\n\n'
              'Email: contact@plainscan.com\n'
              'Phone: +91 79940 63319\n'
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
