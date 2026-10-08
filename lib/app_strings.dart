import 'package:flutter/material.dart';

class S {
  static const Map<String, Map<String, String>> _t = {
    'en': {
      // Settings screen
      'settings': 'Settings',
      'account': 'Account',
      'profile': 'Profile',
      'profile_sub': 'View & edit account info',
      'preferences': 'Preferences',
      'enable_notifications': 'Enable Notifications',
      'security_privacy': 'Security & Privacy',
      'privacy_security': 'Privacy & Security',
      'general': 'General',
      'language': 'Language',
      'about_app': 'About App',
      'about_sub': 'Overview & key features',

      // Language screen
      'english': 'English',
      'arabic': 'Arabic',
      'language_subtitle': 'Choose the language you want to use across the app.',

      // About App screen
      'app_brand_name': 'CyberGuard',
      'about_app_tagline': 'Cybersecurity Awareness & Protection',
      'about_app_intro':
          'A smart cybersecurity assistant designed to help non-expert users stay safer online through clear guidance, scanning tools, trusted news, and simplified security education.',
      'about_features_title': 'Core Features',
      'about_feature_ai_title': 'AI Guidance',
      'about_feature_ai_desc':
          'Get practical help for suspicious messages, unsafe links, and common cyber incidents in simple language.',
      'about_feature_scan_title': 'Threat Scanning',
      'about_feature_scan_desc':
          'Scan URLs and selected files to identify potential threats and get fast security feedback.',
      'about_feature_news_title': 'Cyber News Feed',
      'about_feature_news_desc':
          'Follow recent cybersecurity news from trusted sources to stay aware of important threats and updates.',
      'about_feature_faq_title': 'Simple FAQ',
      'about_feature_faq_desc':
          'Understand technical security topics through easy explanations built for everyday users.',
      'about_mission_title': 'Our Mission',
      'about_mission_body':
          'The app focuses on practical protection, clearer risk awareness, and a privacy-conscious experience so users can make safer decisions online with confidence.',
      'about_version': 'Version 1.0.0',

      // Bottom Navigation
      'nav_dashboard': 'Dashboard',
      'nav_scan': 'Scan',
      'nav_ai_chat': 'AI Chat',
      'nav_report': 'Report',
      'nav_settings': 'Settings',
    },
    'ar': {
      // Settings screen
      'settings': 'الإعدادات',
      'account': 'الحساب',
      'profile': 'الملف الشخصي',
      'profile_sub': 'عرض وتعديل معلومات الحساب',
      'preferences': 'التفضيلات',
      'enable_notifications': 'تفعيل الإشعارات',
      'security_privacy': 'الأمان والخصوصية',
      'privacy_security': 'الخصوصية والأمان',
      'general': 'عام',
      'language': 'اللغة',
      'about_app': 'حول التطبيق',
      'about_sub': 'نظرة عامة والميزات الأساسية',

      // Language screen
      'english': 'الإنجليزية',
      'arabic': 'العربية',
      'language_subtitle': 'اختر اللغة التي تريد استخدامها في جميع أجزاء التطبيق.',

      // About App screen
      'app_brand_name': 'CyberGuard',
      'about_app_tagline': 'التوعية والحماية في الأمن السيبراني',
      'about_app_intro':
          'مساعد ذكي في الأمن السيبراني صُمم لمساعدة المستخدمين غير المتخصصين على البقاء أكثر أمانًا عبر الإنترنت من خلال إرشادات واضحة، وأدوات فحص، وأخبار موثوقة، وتبسيط المفاهيم الأمنية.',
      'about_features_title': 'الميزات الأساسية',
      'about_feature_ai_title': 'إرشاد بالذكاء الاصطناعي',
      'about_feature_ai_desc':
          'احصل على مساعدة عملية بخصوص الرسائل المشبوهة والروابط غير الآمنة والحوادث السيبرانية الشائعة بلغة سهلة.',
      'about_feature_scan_title': 'فحص التهديدات',
      'about_feature_scan_desc':
          'افحص الروابط والملفات المختارة لاكتشاف التهديدات المحتملة والحصول على نتيجة أمنية سريعة.',
      'about_feature_news_title': 'أخبار الأمن السيبراني',
      'about_feature_news_desc':
          'تابع أحدث الأخبار السيبرانية من مصادر موثوقة للبقاء على اطلاع على التهديدات والتحديثات المهمة.',
      'about_feature_faq_title': 'الأسئلة الشائعة المبسطة',
      'about_feature_faq_desc':
          'افهم المفاهيم التقنية في الأمن السيبراني من خلال شروحات سهلة ومناسبة للمستخدم اليومي.',
      'about_mission_title': 'مهمتنا',
      'about_mission_body':
          'يركز التطبيق على الحماية العملية، وزيادة وعي المستخدم بالمخاطر، وتقديم تجربة تراعي الخصوصية لمساعدته على اتخاذ قرارات أكثر أمانًا بثقة.',
      'about_version': 'الإصدار 1.0.0',

      // Bottom Navigation
      'nav_dashboard': 'الرئيسية',
      'nav_scan': 'الفحص',
      'nav_ai_chat': 'محادثة الذكاء',
      'nav_report': 'التقارير',
      'nav_settings': 'الإعدادات',
    },
  };

  static String of(BuildContext context, String key) {
    final code = Localizations.localeOf(context).languageCode;
    return _t[code]?[key] ?? _t['en']?[key] ?? key;
  }
}
