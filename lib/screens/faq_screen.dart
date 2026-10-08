// lib/screens/faq_screen.dart
import 'package:flutter/material.dart';

import 'app_locale.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  String _t(bool isArabic, String ar, String en) => isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFF020617);

    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final isArabic = locale.languageCode == 'ar';

        final List<Map<String, String>> faqs = [
          {
            'question': _t(isArabic, 'ما هو الأمن السيبراني؟', 'What is cybersecurity?'),
            'answer': _t(
              isArabic,
              'الأمن السيبراني هو مجموعة ممارسات وتقنيات تهدف لحماية الأجهزة، الشبكات، والبيانات من الهجمات أو الوصول غير المصرح به أو التدمير.',
              'Cybersecurity is a set of practices and technologies used to protect devices, networks, and data from attacks, unauthorized access, or damage.',
            ),
          },
          {
            'question': _t(isArabic, 'لماذا الأمن السيبراني مهم؟', 'Why is cybersecurity important?'),
            'answer': _t(
              isArabic,
              'لأنه يحمي بياناتك الشخصية والمالية وحساباتك من السرقة أو الابتزاز، ويقلل من احتمالية اختراق أجهزتك أو استغلالها في هجمات أخرى.',
              'It protects your personal data, financial information, and accounts from theft or blackmail, and reduces the chance of your devices being hacked or misused.',
            ),
          },
          {
            'question': _t(isArabic, 'ما هي كلمة المرور القوية؟', 'What is a strong password?'),
            'answer': _t(
              isArabic,
              'كلمة المرور القوية لا تقل عن 12 حرفًا، وتحتوي على حروف كبيرة وصغيرة وأرقام ورموز، ولا تكون مرتبطة بمعلوماتك الشخصية مثل اسمك أو تاريخ ميلادك.',
              'A strong password is at least 12 characters long and includes uppercase letters, lowercase letters, numbers, and symbols. It should not be based on personal information such as your name or birthday.',
            ),
          },
          {
            'question': _t(isArabic, 'هل يمكنني استخدام نفس كلمة المرور لكل الحسابات؟', 'Can I use the same password for all accounts?'),
            'answer': _t(
              isArabic,
              'لا، استخدام نفس كلمة المرور لكل الحسابات خطير جدًا. إذا تم اختراق حساب واحد، يمكن للمهاجم تجربة نفس الكلمة على باقي حساباتك.',
              'No. Using the same password for every account is very risky. If one account is hacked, an attacker may try the same password on your other accounts.',
            ),
          },
          {
            'question': _t(isArabic, 'ما هو التحقق بخطوتين (2FA)؟', 'What is two-factor authentication (2FA)?'),
            'answer': _t(
              isArabic,
              'التحقق بخطوتين هو طبقة أمان إضافية تطلب منك إدخال رمز يُرسل إلى هاتفك أو تطبيق مخصص بعد كتابة كلمة المرور، مما يصعّب اختراق حسابك حتى لو عرف أحد كلمة المرور.',
              'Two-factor authentication is an extra security layer that asks for a code from your phone or an authenticator app after entering your password. It makes account takeover much harder.',
            ),
          },
          {
            'question': _t(isArabic, 'ما هو التصيد الاحتيالي (Phishing)؟', 'What is phishing?'),
            'answer': _t(
              isArabic,
              'التصيد الاحتيالي هو رسائل أو روابط مزيفة تبدو من جهات موثوقة (مثل بنك أو منصة معروفة) تهدف لخداعك كي تعطي بياناتك أو تضغط على روابط خبيثة.',
              'Phishing is when fake messages or links pretend to come from trusted sources, such as a bank or a known platform, to trick you into sharing data or opening malicious links.',
            ),
          },
          {
            'question': _t(isArabic, 'كيف أتعرف على رسالة تصيد احتيالي؟', 'How can I recognize a phishing message?'),
            'answer': _t(
              isArabic,
              'انتبه للأخطاء الإملائية، والروابط الغريبة، وطلبات المعلومات الحساسة، ورسائل الاستعجال مثل "حسابك سيتوقف الآن". تحقق دائمًا من عنوان المرسل والرابط قبل الضغط.',
              'Look for spelling mistakes, strange links, requests for sensitive information, and urgent messages such as “your account will be suspended now.” Always check the sender and link before clicking.',
            ),
          },
          {
            'question': _t(isArabic, 'هل الضغط على رابط مجهول دائمًا خطر؟', 'Is clicking an unknown link always dangerous?'),
            'answer': _t(
              isArabic,
              'ليس دائمًا، لكن يُعتبر مخاطرة عالية. تجنب الضغط على الروابط من مصادر غير موثوقة أو غير متوقعة، وافتح المواقع يدويًا بكتابة العنوان في المتصفح.',
              'Not always, but it is risky. Avoid links from unknown or unexpected sources, and open important websites manually by typing the address in your browser.',
            ),
          },
          {
            'question': _t(isArabic, 'كيف أحمي بريدي الإلكتروني من الاختراق؟', 'How can I protect my email from being hacked?'),
            'answer': _t(
              isArabic,
              'استخدم كلمة مرور قوية وفريدة، فعّل التحقق بخطوتين، تجنب فتح المرفقات المشبوهة، ولا تشارك كلمة المرور مع أي شخص.',
              'Use a strong and unique password, enable 2FA, avoid suspicious attachments, and never share your password with anyone.',
            ),
          },
          {
            'question': _t(isArabic, 'ما هو برنامج إدارة كلمات المرور؟', 'What is a password manager?'),
            'answer': _t(
              isArabic,
              'هو تطبيق يقوم بتخزين كلمات مرورك بشكل مشفر وآمن، ويساعدك على إنشاء كلمات مرور قوية واستخدام كلمة رئيسية واحدة فقط للوصول إليها.',
              'A password manager stores your passwords securely with encryption, helps you create strong passwords, and lets you access them using one main password.',
            ),
          },
          {
            'question': _t(isArabic, 'هل استخدام شبكة Wi-Fi عامة آمن؟', 'Is public Wi-Fi safe?'),
            'answer': _t(
              isArabic,
              'الشبكات العامة غالبًا غير آمنة. تجنب تسجيل الدخول إلى حسابات حساسة أو إجراء عمليات بنكية عليها، ويفضل استخدام VPN عند الضرورة.',
              'Public Wi-Fi is often unsafe. Avoid logging into sensitive accounts or doing banking on it. Use a trusted VPN when needed.',
            ),
          },
          {
            'question': _t(isArabic, 'كيف أحمي شبكة الـ Wi-Fi المنزلية؟', 'How can I secure my home Wi‑Fi?'),
            'answer': _t(
              isArabic,
              'غيّر اسم الشبكة الافتراضي، استخدم كلمة مرور قوية، فعّل تشفير WPA2 أو WPA3، وحدث برنامج الراوتر بانتظام.',
              'Change the default network name, use a strong password, enable WPA2 or WPA3 encryption, and update your router firmware regularly.',
            ),
          },
          {
            'question': _t(isArabic, 'ما هو الـ VPN؟', 'What is a VPN?'),
            'answer': _t(
              isArabic,
              'VPN هو شبكة خاصة افتراضية تقوم بتشفير اتصالك بالإنترنت وإخفاء عنوان IP الحقيقي، مما يزيد من الخصوصية ويصعّب التجسس على اتصالك.',
              'A VPN is a virtual private network that encrypts your internet connection and hides your real IP address, improving privacy and making spying on your connection harder.',
            ),
          },
          {
            'question': _t(isArabic, 'ما هو جدار الحماية (Firewall)؟', 'What is a firewall?'),
            'answer': _t(
              isArabic,
              'جدار الحماية هو نظام يراقب حركة البيانات الواردة والصادرة من جهازك أو شبكتك ويمنع الاتصالات غير المصرح بها أو المشبوهة.',
              'A firewall monitors incoming and outgoing network traffic and blocks unauthorized or suspicious connections.',
            ),
          },
          {
            'question': _t(isArabic, 'لماذا تحديث النظام والتطبيقات مهم؟', 'Why are system and app updates important?'),
            'answer': _t(
              isArabic,
              'التحديثات غالبًا تحتوي على إصلاحات لثغرات أمنية مكتشفة. تأجيل التحديثات يترك جهازك معرضًا للاستغلال بواسطة هذه الثغرات.',
              'Updates often include fixes for known security vulnerabilities. Delaying updates can leave your device exposed to attacks.',
            ),
          },
          {
            'question': _t(isArabic, 'ما هي البرمجيات الخبيثة (Malware)؟', 'What is malware?'),
            'answer': _t(
              isArabic,
              'البرمجيات الخبيثة هي برامج تم تصميمها لإلحاق الضرر أو سرقة البيانات مثل الفيروسات، أحصنة طروادة، برامج التجسس، وبرامج الفدية.',
              'Malware is software designed to cause damage or steal data, such as viruses, trojans, spyware, and ransomware.',
            ),
          },
          {
            'question': _t(isArabic, 'ما هو برنامج الفدية (Ransomware)؟', 'What is ransomware?'),
            'answer': _t(
              isArabic,
              'هو نوع من البرمجيات الخبيثة يقوم بتشفير ملفاتك أو قفل جهازك ثم يطالبك بدفع فدية مقابل استعادة الوصول إلى بياناتك.',
              'Ransomware is a type of malware that encrypts your files or locks your device, then demands payment to restore access.',
            ),
          },
          {
            'question': _t(isArabic, 'كيف أحمي هاتفي الذكي؟', 'How can I protect my smartphone?'),
            'answer': _t(
              isArabic,
              'استخدم قفل شاشة قوي، ثبّت التطبيقات من المتاجر الرسمية فقط، حدّث النظام بانتظام، فعّل العثور على الجهاز، وتجنب إعطاء الأذونات غير الضرورية للتطبيقات.',
              'Use a strong screen lock, install apps only from official stores, update your system regularly, enable Find My Device, and avoid giving apps unnecessary permissions.',
            ),
          },
          {
            'question': _t(isArabic, 'ما هي الهندسة الاجتماعية؟', 'What is social engineering?'),
            'answer': _t(
              isArabic,
              'الهندسة الاجتماعية هي استغلال المهاجم لعلم النفس البشري وخداع الأشخاص للحصول على معلومات أو القيام بأفعال تخدم الهجوم، بدلاً من مهاجمة الأنظمة مباشرة.',
              'Social engineering is when attackers manipulate people into sharing information or taking actions that help an attack, instead of attacking systems directly.',
            ),
          },
          {
            'question': _t(isArabic, 'ما أهمية النسخ الاحتياطي للبيانات؟', 'Why are backups important?'),
            'answer': _t(
              isArabic,
              'النسخ الاحتياطي يحميك من فقدان البيانات بسبب اختراق، أو خطأ بشري، أو عطل في الجهاز. يفضل حفظ نسخة في مكان آخر أو على سحابة موثوقة.',
              'Backups protect you from losing data because of hacking, human error, or device failure. Keep a copy in another safe place or on a trusted cloud service.',
            ),
          },
          {
            'question': _t(isArabic, 'ماذا أفعل إذا شعرت أن جهازي مخترق؟', 'What should I do if I think my device is hacked?'),
            'answer': _t(
              isArabic,
              'افصل الجهاز عن الإنترنت، افحصه ببرنامج مضاد للبرمجيات الخبيثة، غيّر كلمات المرور من جهاز آمن، وراجع التطبيقات والبرامج المثبتة واحذف المشبوه منها.',
              'Disconnect it from the internet, scan it with anti-malware software, change your passwords from a safe device, and review installed apps or programs for anything suspicious.',
            ),
          },
          {
            'question': _t(isArabic, 'ماذا أفعل إذا تم اختراق حسابي؟', 'What should I do if my account is hacked?'),
            'answer': _t(
              isArabic,
              'غيّر كلمة المرور فورًا، فعّل التحقق بخطوتين، راجع جلسات الدخول والأجهزة المتصلة، أبلغ المنصة بالاختراق، وأخبر جهات الاتصال إذا تم استغلال حسابك لإرسال رسائل احتيالية.',
              'Change the password immediately, enable 2FA, review login sessions and connected devices, report the hack to the platform, and warn your contacts if your account was used for scams.',
            ),
          },
          {
            'question': _t(isArabic, 'كيف أحمي أطفالي على الإنترنت؟', 'How can I protect my children online?'),
            'answer': _t(
              isArabic,
              'استخدم أدوات الرقابة الأبوية، تحدث معهم عن المخاطر، راقب وقت الاستخدام والمحتوى، وعلّمهم عدم مشاركة المعلومات الشخصية أو الصور مع الغرباء.',
              'Use parental controls, talk with them about risks, monitor screen time and content, and teach them not to share personal information or photos with strangers.',
            ),
          },
          {
            'question': _t(isArabic, 'هل تحميل البرامج المقرصنة خطر؟', 'Is downloading pirated software dangerous?'),
            'answer': _t(
              isArabic,
              'نعم، البرامج المقرصنة غالبًا تحتوي على برمجيات خبيثة، بالإضافة إلى أنها مخالفة للقانون وشروط الاستخدام، وقد تؤدي لاختراق جهازك أو سرقة بياناتك.',
              'Yes. Pirated software often contains malware. It may also violate laws and terms of service, and can lead to device hacking or data theft.',
            ),
          },
          {
            'question': _t(isArabic, 'ما هي أفضل نصيحة سريعة للأمن الرقمي اليومي؟', 'What is the best quick tip for daily digital safety?'),
            'answer': _t(
              isArabic,
              'فكر قبل أن تضغط، لا تشارك معلوماتك الحساسة، استخدم كلمات مرور قوية وفريدة مع 2FA، وحدّث أجهزتك وتطبيقاتك بانتظام.',
              'Think before you click. Do not share sensitive information. Use strong, unique passwords with 2FA, and keep your devices and apps updated.',
            ),
          },
        ];

        final List<String> cyberTips = [
          _t(
            isArabic,
            'استخدم كلمة مرور قوية (12-16 حرفًا على الأقل) وتحتوي على: حرف كبير + حرف صغير + رقم + رمز مثل ! @ #.',
            'Use a strong password with at least 12–16 characters, including uppercase letters, lowercase letters, numbers, and symbols like ! @ #.',
          ),
          _t(
            isArabic,
            'لا تستخدم نفس كلمة المرور لأكثر من حساب، واستعمل مدير كلمات مرور إذا أمكن.',
            'Do not reuse the same password across accounts. Use a password manager if possible.',
          ),
          _t(
            isArabic,
            'فعّل التحقق بخطوتين (2FA) لكل الحسابات المهمة (البريد، السوشال، البنوك).',
            'Enable two-factor authentication (2FA) for important accounts such as email, social media, and banking.',
          ),
          _t(
            isArabic,
            'لا تضغط على الروابط المشبوهة أو غير المتوقعة حتى لو وصلت من صديق—قد يكون حسابه مخترق.',
            'Do not click suspicious or unexpected links, even if they came from a friend. Their account may be hacked.',
          ),
          _t(
            isArabic,
            'تحقق من الرابط قبل فتحه: انتبه للأحرف المتشابهة مثل (0 بدل O) أو نطاقات غريبة.',
            'Check links before opening them. Watch for lookalike characters such as 0 instead of O, or unusual domains.',
          ),
          _t(
            isArabic,
            'لا تفتح مرفقات مجهولة (خصوصًا ملفات .exe أو روابط داخل ملفات PDF/Word).',
            'Do not open unknown attachments, especially .exe files or links inside PDF/Word files.',
          ),
          _t(
            isArabic,
            'حدّث نظام التشغيل والتطبيقات أولًا بأول لتسكير الثغرات الأمنية.',
            'Keep your operating system and apps updated to patch security vulnerabilities.',
          ),
          _t(
            isArabic,
            'حمّل التطبيقات من المتاجر الرسمية فقط وتجنب ملفات APK من مصادر مجهولة.',
            'Download apps only from official stores and avoid APK files from unknown sources.',
          ),
          _t(
            isArabic,
            'لا تشارك رموز التحقق أو كلمات المرور مع أي شخص—even لو ادّعى أنه دعم فني.',
            'Never share verification codes or passwords with anyone, even if they claim to be technical support.',
          ),
          _t(
            isArabic,
            'استخدم قفل شاشة قوي وبصمة/Face ID، وفعّل “العثور على الجهاز” في هاتفك.',
            'Use a strong screen lock with fingerprint or Face ID, and enable Find My Device on your phone.',
          ),
          _t(
            isArabic,
            'تجنب Wi-Fi العام للحسابات الحساسة، وإذا اضطررت استخدم VPN موثوق.',
            'Avoid public Wi‑Fi for sensitive accounts. If you must use it, use a trusted VPN.',
          ),
          _t(
            isArabic,
            'اعمِل نسخ احتياطي دوري لملفاتك (سحابة موثوقة + نسخة خارجية إن أمكن).',
            'Back up your files regularly using a trusted cloud service plus an external copy if possible.',
          ),
        ];

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: background,
            appBar: AppBar(
              backgroundColor: background,
              title: Text(_t(isArabic, 'الأسئلة الشائعة', 'FAQ')),
              centerTitle: true,
              elevation: 0,
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: const Color(0xFF020617),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.cyanAccent.withOpacity(0.25),
                    ),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      iconColor: Colors.white,
                      collapsedIconColor: Colors.white,
                      title: Text(
                        _t(isArabic, 'نصائح سيبرانية سريعة', 'Quick Cyber Tips'),
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        _t(
                          isArabic,
                          'إرشادات بسيطة لحماية حساباتك وأجهزتك',
                          'Simple guidance to protect your accounts and devices',
                        ),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final tip in cyberTips)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          tip,
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            height: 1.4,
                                            color: Colors.white.withOpacity(0.85),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ...List.generate(faqs.length, (index) {
                  final item = faqs[index];

                  return Card(
                    color: const Color(0xFF020617),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.cyanAccent.withOpacity(0.25),
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        iconColor: Colors.white,
                        collapsedIconColor: Colors.white,
                        title: Text(
                          item['question'] ?? '',
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              item['answer'] ?? '',
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                height: 1.4,
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
