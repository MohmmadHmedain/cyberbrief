// lib/screens/privacy_policy_screen.dart
import 'package:flutter/material.dart';

import 'app_locale.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  String _t(bool isArabic, String ar, String en) => isArabic ? ar : en;

  TextDirection _direction(bool isArabic) {
    return isArabic ? TextDirection.rtl : TextDirection.ltr;
  }

  @override
  Widget build(BuildContext context) {
    const background = Colors.black;
    const headingStyle = TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
    const bodyStyle = TextStyle(
      color: Colors.white70,
      fontSize: 13,
      height: 1.5,
    );

    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final isArabic = locale.languageCode == 'ar';

        return Directionality(
          textDirection: _direction(isArabic),
          child: Scaffold(
            backgroundColor: background,
            appBar: AppBar(
              backgroundColor: background,
              title: Text(_t(isArabic, 'سياسة الخصوصية', 'Privacy Policy')),
              centerTitle: true,
              elevation: 0,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(
                      isArabic,
                      'سياسة خصوصية CyberGuard',
                      'CyberGuard Privacy Policy',
                    ),
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _section(
                    title: _t(isArabic, 'نظرة عامة', 'Overview'),
                    body: _t(
                      isArabic,
                      'CyberGuard هو مساعد للأمن السيبراني يساعد غير المختصين على البقاء آمنين أثناء استخدام الإنترنت. يوفر التطبيق إرشادات عبر محادثة الذكاء الاصطناعي، وفحص الروابط والملفات والصور، وتقديم بلاغات أمنية، وأخبارًا سيبرانية مختارة، وقسم أسئلة شائعة داخل التطبيق. نركز على حماية بياناتك واستخدامها فقط لتقديم هذه الميزات.',
                      'CyberGuard is a cybersecurity assistant that helps non-experts stay safe online. The app offers AI chat guidance, URL/file/image scanning, security incident reports, curated cyber news, and an in-app FAQ. We focus on keeping your data private and using it only to deliver these features.',
                    ),
                    headingStyle: headingStyle,
                    bodyStyle: bodyStyle,
                  ),

                  _section(
                    title: _t(isArabic, '1. البيانات التي نجمعها', '1. Data We Collect'),
                    body: _t(
                      isArabic,
                      '- بيانات الفحص: الروابط التي ترسلها، والملفات أو الصور التي تختار فحصها، والتفاصيل التقنية اللازمة لتحليلها مثل بيانات الملف أو البصمات الرقمية.\n'
                          '- رسائل محادثة الذكاء الاصطناعي: الأسئلة التي تطرحها على بوت الأمن السيبراني ومحتوى المحادثة، بما في ذلك وصف النشاطات أو الحوادث المشبوهة.\n'
                          '- البلاغات الأمنية: المعلومات التي تدخلها في نموذج “تقديم بلاغ أمني”، مثل الاسم، البريد الإلكتروني، نوع الحادثة، درجة الخطورة، والوصف.\n'
                          '- إعدادات التطبيق والاستخدام: تفضيلات الخصوصية مثل حفظ سجل الفحص، ومعلومات أساسية عن مدى استخدام ميزات الفحص.\n'
                          '- نحن لا نقرأ ملفاتك أو صورك الشخصية تلقائيًا؛ نصل فقط إلى العناصر التي تختارها أنت للفحص.',
                      '- Scan data: URLs you submit, files or images you choose to scan, and technical details needed to analyze them (such as file metadata or hashes).\n'
                          '- AI chat messages: questions you ask the cybersecurity bot and your conversation content, including descriptions of suspicious activity or incidents.\n'
                          '- Incident reports: information you enter in the “Security Report” form (for example: name, email, type of incident, severity, and description).\n'
                          '- App settings and usage: your privacy preferences (such as Save Scan History) and basic information about how often scanning features are used.\n'
                          '- We do not read your personal files or photos automatically; we only access items that you explicitly select for scanning.',
                    ),
                    headingStyle: headingStyle,
                    bodyStyle: bodyStyle,
                  ),

                  _section(
                    title: _t(isArabic, '2. كيف نستخدم بياناتك', '2. How We Use Your Data'),
                    body: _t(
                      isArabic,
                      'نستخدم البيانات التي تقدمها من أجل:\n'
                          '- تحليل الروابط والملفات والصور للكشف عن التهديدات المحتملة وعرض النتائج لك.\n'
                          '- تقديم إرشادات أمن سيبراني مناسبة من خلال محادثة الذكاء الاصطناعي.\n'
                          '- إنشاء البلاغات الأمنية وتتبعها حتى يمكن مراجعة المشاكل والتعامل معها.\n'
                          '- تحسين استقرار وجودة التطبيق، مثل فهم الميزات الأكثر استخدامًا.',
                      'We use the data you provide to:\n'
                          '- Analyze URLs, files, and images for potential threats and show you results.\n'
                          '- Provide tailored cybersecurity guidance via the AI chat.\n'
                          '- Generate and track security reports so that issues can be reviewed and handled.\n'
                          '- Improve stability and quality of the app (for example, understanding which features are used most).',
                    ),
                    headingStyle: headingStyle,
                    bodyStyle: bodyStyle,
                  ),

                  _section(
                    title: _t(isArabic, '3. تخزين البيانات والاحتفاظ بها', '3. Data Storage & Retention'),
                    body: _t(
                      isArabic,
                      '- سجل الفحص: عند تفعيل خيار حفظ سجل الفحص، يتم حفظ ملخصات فحص الروابط أو الملفات السابقة محليًا على جهازك. يمكنك تعطيل هذا الخيار في أي وقت من صفحة الخصوصية والأمان أو مسح السجل بالكامل باستخدام “مسح سجل الفحص”.\n'
                          '- بيانات المحادثة والبلاغات: إذا كان التطبيق متصلًا بخدمة خلفية أو مزود ذكاء اصطناعي، فقد تتم معالجة رسائلك وبلاغاتك هناك لتوليد الردود والاحتفاظ بسجلات الحوادث.\n'
                          '- أخبار الأمن السيبراني ومحتوى الأسئلة الشائعة هي معلومات توعوية فقط ولا تتطلب جمع بيانات شخصية إضافية منك.',
                      '- Scan History: when Save Scan History is enabled, previous URL/file scan summaries are stored locally on your device. You can disable this at any time from the Privacy & Security page or clear all history using “Clear Scan History”.\n'
                          '- Chat and report data: if the app is connected to a backend service or AI provider, your messages and reports may be processed there to generate responses and maintain incident records.\n'
                          '- Cyber news and FAQ content are informational only and do not require collecting additional personal data from you.',
                    ),
                    headingStyle: headingStyle,
                    bodyStyle: bodyStyle,
                  ),

                  _section(
                    title: _t(isArabic, '4. خدمات الطرف الثالث', '4. Third-Party Services'),
                    body: _t(
                      isArabic,
                      'لتقديم تحليل أمني دقيق وردود ذكاء اصطناعي، قد يستخدم CyberGuard خدمات موثوقة من طرف ثالث، مثل:\n'
                          '- واجهات فحص السمعة والأمان للتحقق من الروابط والملفات.\n'
                          '- مزودي نماذج الذكاء الاصطناعي لمعالجة رسائل المحادثة وتوليد الإجابات.\n\n'
                          'يتم إرسال الحد الأدنى اللازم فقط من البيانات إلى هذه الخدمات، ويتم استخدامها فقط لأغراض التحليل وتوليد الردود.',
                      'To provide accurate security analysis and AI responses, CyberGuard may use trusted third-party services, for example:\n'
                          '- Security scanning and reputation APIs to check URLs and files.\n'
                          '- AI model providers to process your chat messages and generate answers.\n\n'
                          'Only the minimum necessary data is sent to these services, and it is used solely for analysis and response generation.',
                    ),
                    headingStyle: headingStyle,
                    bodyStyle: bodyStyle,
                  ),

                  _section(
                    title: _t(isArabic, '5. خياراتك وأدوات التحكم', '5. Your Choices & Controls'),
                    body: _t(
                      isArabic,
                      '- يمكنك تشغيل أو إيقاف سجل الفحص باستخدام خيار “حفظ سجل الفحص”.\n'
                          '- يمكنك مسح ملخصات الفحص المخزنة في أي وقت باستخدام “مسح سجل الفحص”.\n'
                          '- أنت تختار الروابط أو الملفات أو الصور التي تريد فحصها؛ لا يتم فحص أي شيء بدون إجراء منك.\n'
                          '- يمكنك التوقف عن استخدام التطبيق وحذفه في أي وقت لإزالة البيانات المحلية المخزنة على جهازك.',
                      '- You can turn scan history on or off using the “Save Scan History” switch.\n'
                          '- You can erase stored scan summaries at any time using “Clear Scan History”.\n'
                          '- You can choose which URLs, files, or images to scan; nothing is scanned without your action.\n'
                          '- You may stop using the app and uninstall it at any time to remove local data stored on your device.',
                    ),
                    headingStyle: headingStyle,
                    bodyStyle: bodyStyle,
                  ),

                  _section(
                    title: _t(isArabic, '6. التواصل', '6. Contact'),
                    body: _t(
                      isArabic,
                      'إذا كانت لديك أسئلة حول سياسة الخصوصية هذه أو طريقة تعامل CyberGuard مع بياناتك، يرجى التواصل مع مطور التطبيق أو قناة الدعم الخاصة بجهتك.',
                      'If you have questions about this Privacy Policy or how CyberGuard handles your data, please contact the app developer or your organization\'s support channel.',
                    ),
                    headingStyle: headingStyle,
                    bodyStyle: bodyStyle,
                    bottomPadding: 0,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _section({
    required String title,
    required String body,
    required TextStyle headingStyle,
    required TextStyle bodyStyle,
    double bottomPadding = 16,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: headingStyle),
          const SizedBox(height: 6),
          Text(body, style: bodyStyle),
        ],
      ),
    );
  }
}
