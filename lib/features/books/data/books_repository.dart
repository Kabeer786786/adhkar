import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/book_content_block.dart';
import '../domain/book_model.dart';

class BooksRepository {
  static const String _boxName = 'user_books_box';

  /// Pre-built library of exactly 4 comprehensive, deeply detailed Islamic books
  static final List<BookModel> prebuiltLibrary = [
    // -------------------------------------------------------------
    // BOOK 1: What is Islam
    // -------------------------------------------------------------
    BookModel(
      id: 'what_is_islam',
      title: 'What is Islam: Complete Guide',
      author: 'Adhkar Islamic Research & Scholars',
      category: 'Islamic Fundamentals',
      description:
          'A deeply comprehensive guide exploring the divine foundations of Islam, Tawheed, the Six Pillars of Iman, the Five Pillars of Islam, Noble Character, and daily spiritual life.',
      coverUrl: '',
      coverGradient: [const Color(0xFF1E3A8A), const Color(0xFF0F766E)],
      fileUrl: '',
      openMode: 'in_app',
      totalPages: 8,
      chapters: [
        BookChapter(
          title: 'The Core Foundation: Tawheed & Shahadah',
          subtitle: 'Pure Monotheism and the Declaration of Faith',
          blocks: [
            BookContentBlock.heading('1. The Meaning and Essence of Tawheed', level: 1),
            BookContentBlock.paragraph(
              'Tawheed (the Oneness of Allah) is the foundation upon which the entire universe and every act of worship in Islam is built. It declares that Allah alone is the Creator, Sustainer, and Absolute Master of all existence, possessing no partners, equals, or children.',
            ),
            BookContentBlock.verse(
              arabicText: 'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
              transliteration: 'Qul Huwallahu Ahad. Allahus-Samad. Lam yalid wa lam yoolad. Wa lam yakul-lahu kufuwan ahad.',
              translation: 'Say, "He is Allah, [who is] One. Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent."',
              reference: 'Surah Al-Ikhlas (112:1-4)',
            ),
            BookContentBlock.box(
              text: 'The Shahadah (La ilaha illallah, Muhammadur Rasulullah) is the golden gateway to Islam. Affirming it with sincerity purifies the soul, liberates the mind from superstition, and establishes direct, uninterrupted communication between the servant and the Creator.',
              title: 'Spiritual Essence',
              boxType: BookBoxType.islamic,
            ),
            BookContentBlock.heading('The Three Categories of Tawheed', level: 2),
            BookContentBlock.bulletPoints([
              'Tawheed ar-Ruboobiyyah: Affirming that Allah alone created, controls, and sustains everything in existence.',
              'Tawheed al-Uloohiyyah: Directing all acts of worship (prayer, dua, sacrifice, hope, and reliance) exclusively to Allah.',
              'Tawheed al-Asma\' was-Sifat: Believing in all of Allah\'s Divine Names and Attributes without distortion, negation, or human comparison.',
            ], isOrdered: true),
            BookContentBlock.box(
              text: '[Screenshot Placeholder: Home Screen & Daily Adhkar Highlights in Adhkar App]',
              title: '📸 App Feature Screenshot',
              boxType: BookBoxType.highlight,
            ),
          ],
        ),
        BookChapter(
          title: 'The Six Pillars of Iman (Faith)',
          subtitle: 'The Architecture of Islamic Creed and Belief',
          blocks: [
            BookContentBlock.heading('2. The Six Articles of Faith', level: 1),
            BookContentBlock.paragraph(
              'Iman is not merely passive sentiment; it is conviction rooted deeply in the heart, proclaimed clearly with the tongue, and proven through righteous actions in daily life.',
            ),
            BookContentBlock.verse(
              arabicText: 'آمَنَ الرَّسُولُ بِمَا أُنزِلَ إِلَيْهِ مِن رَّبِّهِ وَالْمُؤْمِنُونَ ۚ كُلٌّ آمَنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ',
              transliteration: 'Aamanar-Rasoolu bimaa unzila ilayhi mir-Rabbihee wal-Mu\'minoon...',
              translation: 'The Messenger has believed in what was revealed to him from his Lord, and [so have] the believers. All of them have believed in Allah and His angels and His books and His messengers.',
              reference: 'Surah Al-Baqarah (2:285)',
            ),
            BookContentBlock.bulletPoints([
              'Belief in Allah: His Sole Divinity, Lordship, and Supreme Perfection.',
              'Belief in the Angels: Pure spiritual beings created from light who carry out divine commands.',
              'Belief in the Divine Scriptures: The Torah of Musa, the Psalms of Dawud, the Gospel of Isa, and the preserved Quran.',
              'Belief in the Prophets: From Adam (AS) to the seal of all Messengers, Prophet Muhammad (ﷺ).',
              'Belief in the Day of Judgment: The universal resurrection, accountability (Hisab), and eternal life in Paradise.',
              'Belief in Divine Decree (Al-Qadr): Accepting that everything occurs under Allah\'s eternal knowledge and wisdom.',
            ], isOrdered: true),
            BookContentBlock.box(
              text: 'Belief in Al-Qadr frees a human being from paralyzing regret over the past and anxiety about the unknown future.',
              title: 'Inner Peace through Qadr',
              boxType: BookBoxType.info,
            ),
          ],
        ),
        BookChapter(
          title: 'The Five Pillars of Islam',
          subtitle: 'The Core Practices of Worship and Devotion',
          blocks: [
            BookContentBlock.heading('3. The Practical Framework of a Muslim Life', level: 1),
            BookContentBlock.paragraph(
              'Islam provides a holistic balance between inward faith and outward religious practice. The Five Pillars structure the daily, weekly, and yearly life of a believer.',
            ),
            BookContentBlock.bulletPoints([
              'Shahadah (Declaration): Proclaiming faith in Allah and His final Messenger.',
              'Salah (Prayer): Five daily obligatory prayers connecting the believer directly with Allah.',
              'Zakat (Obligatory Charity): Annual 2.5% contribution from surplus wealth to support the needy.',
              'Sawm (Fasting): Fasting from dawn to sunset throughout the sacred month of Ramadan.',
              'Hajj (Pilgrimage): Journey to the Kaaba in Makkah once in a lifetime for those with the physical and financial means.',
            ], isOrdered: true),
            BookContentBlock.box(
              text: '[Screenshot Placeholder: Main Navigation & Islamic Companion Features in Adhkar App]',
              title: '📸 App Feature Screenshot',
              boxType: BookBoxType.highlight,
            ),
          ],
        ),
        BookChapter(
          title: 'Noble Character & Universal Mercy',
          subtitle: 'The Moral Legacy of Prophet Muhammad (ﷺ)',
          blocks: [
            BookContentBlock.heading('4. Excellence in Conduct (Akhlaq & Ihsan)', level: 1),
            BookContentBlock.paragraph(
              'Prophet Muhammad (ﷺ) was sent as a mercy to all creation. True Islamic religiosity is demonstrated through kindness, honesty, fulfilling covenants, and honoring parents and neighbors.',
            ),
            BookContentBlock.verse(
              arabicText: 'وَإِنَّكَ لَعَلَىٰ خُلُقٍ عَظِيمٍ',
              translation: 'And indeed, you are of a great moral character.',
              reference: 'Surah Al-Qalam (68:4)',
            ),
            BookContentBlock.bulletPoints([
              'Sidq: Absolute truthfulness in words, trade, and promises.',
              'Birr al-Walidayn: Honoring, serving, and showing compassion to mother and father.',
              'Silat ar-Rahim: Upholding bonds of family kinship and helping relatives in need.',
              'Hilim & Sabr: Remaining patient during hardship and controlling anger with forgiveness.',
            ]),
          ],
        ),
      ],
    ),

    // -------------------------------------------------------------
    // BOOK 2: About Namaz & App Features
    // -------------------------------------------------------------
    BookModel(
      id: 'namaz_guide',
      title: 'Namaz Guide: Prayer & App Tools',
      author: 'Adhkar Islamic Worship & Fiqh Team',
      category: 'Namaz & Prayer',
      description:
          'A comprehensive guide to Salah (prayer), purification (Wudu), step-by-step prayer etiquette, and how to utilize the Adhkar app prayer times, Qibla compass, and Adhkar counters.',
      coverUrl: '',
      coverGradient: [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
      fileUrl: '',
      openMode: 'in_app',
      totalPages: 6,
      chapters: [
        BookChapter(
          title: 'The Station of Salah in Islam',
          subtitle: 'The Pillar of Religion and Divine Conversation',
          blocks: [
            BookContentBlock.heading('1. The Significance and Blessings of Prayer', level: 1),
            BookContentBlock.paragraph(
              'Salah is the second pillar of Islam and the first deed a servant will be held accountable for on the Day of Judgment. It is an intimate audience with Allah that brings serenity, washes away minor sins, and keeps the soul shielded from wrongdoing.',
            ),
            BookContentBlock.verse(
              arabicText: 'إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا',
              translation: 'Indeed, prayer has been decreed upon the believers a decree of specified times.',
              reference: 'Surah An-Nisa (4:103)',
            ),
            BookContentBlock.heading('The Five Daily Obligatory Prayers', level: 2),
            BookContentBlock.bulletPoints([
              'Fajr (Dawn): 2 Sunnah + 2 Fardh prayed before sunrise.',
              'Dhuhr (Midday): 4 Sunnah + 4 Fardh + 2 Sunnah + 2 Nafl after sun crosses zenith.',
              'Asr (Afternoon): 4 Sunnah (Ghair Muakkadah) + 4 Fardh in the late afternoon.',
              'Maghrib (Sunset): 3 Fardh + 2 Sunnah + 2 Nafl immediately after sunset.',
              'Isha (Night): 4 Sunnah + 4 Fardh + 2 Sunnah + 2 Nafl + 3 Witr + 2 Nafl at nightfall.',
            ], isOrdered: true),
          ],
        ),
        BookChapter(
          title: 'Step-by-Step Wudu & Prayer Rules',
          subtitle: 'Purification and Performing Prayer with Khushu',
          blocks: [
            BookContentBlock.heading('2. Purification and Concentration (Khushu)', level: 1),
            BookContentBlock.paragraph(
              'Purity is half of faith. Before standing for prayer, ensure bodily purity, clean garments, and perform a mindful Wudu following the Sunnah.',
            ),
            BookContentBlock.bulletPoints([
              'Make sincere intention in the heart and say "Bismillah".',
              'Wash hands up to the wrists three times.',
              'Rinse mouth and nose three times with fresh water.',
              'Wash entire face from forehead hairline to chin and ear to ear three times.',
              'Wash arms up to and including the elbows three times starting with right arm.',
              'Wipe head (Masah) with wet hands from front to back, and wipe ears.',
              'Wash both feet up to and including ankles three times, washing right foot first.',
            ], isOrdered: true),
            BookContentBlock.box(
              text: 'The Prophet (ﷺ) said: "When any of you stands in prayer, he is in intimate dialogue with his Lord." Free your mind from worldly distractions before uttering Takbeer.',
              title: 'Developing Khushu',
              boxType: BookBoxType.hadith,
            ),
          ],
        ),
        BookChapter(
          title: 'How to Use Namaz & Qibla in Adhkar App',
          subtitle: 'Prayer Times, Qibla Compass, and Tracking Tools',
          blocks: [
            BookContentBlock.heading('3. App Tools for Your Daily Prayers', level: 1),
            BookContentBlock.paragraph(
              'The Adhkar app is designed with high-precision calculation methods, GPS-based location detection, and real-time prayer countdowns to ensure you never miss a prayer.',
            ),
            BookContentBlock.box(
              text: '[Screenshot Placeholder: Namaz Prayer Times Screen & Next Prayer Countdown in Adhkar App]',
              title: '📸 Namaz Screen Screenshot',
              boxType: BookBoxType.highlight,
            ),
            BookContentBlock.heading('Key Features in the Adhkar App Namaz Module:', level: 2),
            BookContentBlock.bulletPoints([
              'Accurate Prayer Timings: Calculates accurate Fajr, Sunrise, Dhuhr, Asr (Hanafi/Shafi), Maghrib, and Isha times automatically based on your GPS coordinates.',
              'Custom Azan & Notification Alerts: Set custom reminders for each prayer with beautiful Azan audios.',
              'Precision Qibla Compass: Sensor-assisted 3D compass pointing you directly toward the Kaaba in Makkah with magnetic declination correction.',
              'Daily Prayer Tracker: Check off completed prayers and track your weekly consistency and prayer habits.',
            ]),
            BookContentBlock.box(
              text: '[Screenshot Placeholder: 3D Qibla Compass Finder in Adhkar App]',
              title: '📸 Qibla Finder Screenshot',
              boxType: BookBoxType.highlight,
            ),
          ],
        ),
      ],
    ),

    // -------------------------------------------------------------
    // BOOK 3: About Roza (Fasting) & App Features
    // -------------------------------------------------------------
    BookModel(
      id: 'roza_guide',
      title: 'Roza Guide: Fasting & App Tools',
      author: 'Adhkar Fasting & Ramadan Research Team',
      category: 'Roza & Fasting',
      description:
          'An authoritative guide on Islamic Fasting (Sawm), Ramadan spirituality, voluntary fasts, Fiqh rules, and utilizing the Adhkar app Fasting tracker, Sehri/Iftar timers, and Ramadan calendar.',
      coverUrl: '',
      coverGradient: [const Color(0xFF7C2D12), const Color(0xFFC2410C)],
      fileUrl: '',
      openMode: 'in_app',
      totalPages: 6,
      chapters: [
        BookChapter(
          title: 'The Philosophy & Blessings of Fasting',
          subtitle: 'Taqwa, Physical Purification, and Spiritual Station',
          blocks: [
            BookContentBlock.heading('1. The Spiritual Station of Fasting (Sawm)', level: 1),
            BookContentBlock.paragraph(
              'Fasting is an act of pure devotion with no room for ostentation. Abstaining from food, drink, and intimate relations from true dawn until sunset disciplines the ego and awakens compassion for the less fortunate.',
            ),
            BookContentBlock.verse(
              arabicText: 'يَا أَيُّهَا الَّذِينَ آمَنُوا كُتِبَ عَلَيْكُمُ الصِّيَامُ كَمَا كُتِبَ عَلَى الَّذِينَ مِن قَبْلِكُمْ لَعَلَّكُمْ تَتَّقُونَ',
              translation: 'O you who have believed, decreed upon you is fasting as it was decreed upon those before you that you may become righteous.',
              reference: 'Surah Al-Baqarah (2:183)',
            ),
            BookContentBlock.box(
              text: 'In a Hadith Qudsi, Allah says: "Every deed of the son of Adam is for him, except fasting; it is for Me, and I shall reward for it."',
              title: 'Hadith on Fasting',
              boxType: BookBoxType.hadith,
            ),
          ],
        ),
        BookChapter(
          title: 'Fiqh Rules, Suhoor, and Iftar Etiquette',
          subtitle: 'Sunnah Practices, Invocations, and Validating the Fast',
          blocks: [
            BookContentBlock.heading('2. Rules and Sunnahs of Sawm', level: 1),
            BookContentBlock.paragraph(
              'The Prophet (ﷺ) encouraged taking Suhoor (pre-dawn meal) for its blessings, delaying it until shortly before Fajr, and hastening Iftar upon hearing the Maghrib Azan.',
            ),
            BookContentBlock.verse(
              arabicText: 'ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الأَجْرُ إِنْ شَاءَ اللَّهُ',
              transliteration: 'Dhahabadh-dhama\'u wabtallatil-\'urooqu wa thabatal-ajru in sha Allah.',
              translation: 'The thirst has gone, the veins are moistened, and the reward is confirmed, if Allah wills.',
              reference: 'Sunan Abi Dawud 2357',
            ),
            BookContentBlock.bulletPoints([
              'Eat dates or drink water to break the fast as taught in the Sunnah.',
              'Avoid backbiting, anger, and fruitless speech which diminish the fast\'s reward.',
              'Increase charity and Quran recitation throughout the fasting period.',
            ]),
          ],
        ),
        BookChapter(
          title: 'How to Use Roza & Fasting Tools in Adhkar App',
          subtitle: 'Sehri/Iftar Countdowns, Fast Tracker, and Ramadan Duas',
          blocks: [
            BookContentBlock.heading('3. Fasting Companion in the Adhkar App', level: 1),
            BookContentBlock.paragraph(
              'The Adhkar app provides a dedicated Fasting & Roza management hub designed to support both obligatory Ramadan fasts and voluntary Sunnah fasts (Mondays, Thursdays, and White Days).',
            ),
            BookContentBlock.box(
              text: '[Screenshot Placeholder: Roza Fasting Hub, Sehri/Iftar Times & Progress Wheel in Adhkar App]',
              title: '📸 Fasting Hub Screenshot',
              boxType: BookBoxType.highlight,
            ),
            BookContentBlock.heading('Key Features in the Adhkar App Fasting Module:', level: 2),
            BookContentBlock.bulletPoints([
              'Live Suhoor & Iftar Countdowns: Real-time dynamic timer showing exact minutes remaining until Iftar and Suhoor.',
              'Fasting Log & Missed Fast Counter (Qadha): Record your completed fasts, track voluntary fasts, and manage make-up fasts with notes.',
              'Ramadan Daily Duas: Authentic supplications for opening the fast, Laylatul Qadr, and Ashra invocations.',
              'Fasting Calendar: Visual monthly view highlighting Sunnah fasting days (Ayyam al-Beed 13th, 14th, 15th of Hijri month).',
            ]),
          ],
        ),
      ],
    ),

    // -------------------------------------------------------------
    // BOOK 4: About Zakat & Sadaqah with App Calculator
    // -------------------------------------------------------------
    BookModel(
      id: 'zakat_guide',
      title: 'Zakat & Sadaqah: Wealth Purification',
      author: 'Adhkar Islamic Financial & Charity Team',
      category: 'Zakat & Charity',
      description:
          'A complete handbook on Zakat calculation, Nisab criteria, eligible assets, voluntary Sadaqah, and step-by-step instructions on utilizing the Adhkar app Zakat Calculator & Charity Manager.',
      coverUrl: '',
      coverGradient: [const Color(0xFF14532D), const Color(0xFF15803D)],
      fileUrl: '',
      openMode: 'in_app',
      totalPages: 6,
      chapters: [
        BookChapter(
          title: 'The Purpose & Pillars of Zakat',
          subtitle: 'Purification of Wealth and Social Justice',
          blocks: [
            BookContentBlock.heading('1. The Divine Obligation of Zakat', level: 1),
            BookContentBlock.paragraph(
              'Zakat is the third pillar of Islam and an obligatory financial contribution for eligible Muslims. The word Zakat means both purification and growth. Giving Zakat purifies the remaining wealth and increases divine blessings.',
            ),
            BookContentBlock.verse(
              arabicText: 'خُذْ مِنْ أَمْوَالِهِمْ صَدَقَةً تُطَهِّرُهُمْ وَتُزَكِّيهِم بِهَا وَصَلِّ عَلَيْهِمْ',
              translation: 'Take from their wealth a charity by which you purify them and cause them increase, and invoke [Allah\'s blessings] upon them.',
              reference: 'Surah At-Tawbah (9:103)',
            ),
            BookContentBlock.box(
              text: 'Zakat is obligatory at the rate of 2.5% (1/40th) on surplus wealth that exceeds the Nisab threshold (equivalent to 87.48 grams of gold or 612.36 grams of silver) held for one complete lunar year (Hawl).',
              title: 'Zakat Rule Summary',
              boxType: BookBoxType.info,
            ),
          ],
        ),
        BookChapter(
          title: 'Eligible Assets & The 8 Recipients',
          subtitle: 'Gold, Silver, Cash, Investments, and Quranic Beneficiaries',
          blocks: [
            BookContentBlock.heading('2. Eligible Assets & Who Receives Zakat', level: 1),
            BookContentBlock.paragraph(
              'Zakat applies to savings, cash, gold, silver, tradable business inventory, stocks, and investment properties (on rental income or capital growth intended for sale).',
            ),
            BookContentBlock.heading('The 8 Quranic Categories of Zakat Recipients:', level: 2),
            BookContentBlock.bulletPoints([
              'Al-Fuqara: The destitute poor who have no source of livelihood.',
              'Al-Masakeen: The needy whose income does not cover basic necessities.',
              'Al-Amileena Alayha: Authorized administrators and collectors of Zakat.',
              'Al-Mu\'allafati Quloobuhum: Those whose hearts are being reconciled to Islam.',
              'Fir-Riqaab: Freeing individuals from bondage or human exploitation.',
              'Al-Gharimeen: Debtors burdened with overwhelming, honest debts.',
              'Fee Sabeelillah: Striving in the path of Allah and supporting Islamic education.',
              'Ibn as-Sabeel: The stranded traveler cut off from resources.',
            ], isOrdered: true),
          ],
        ),
        BookChapter(
          title: 'How to Use Zakat Tools in Adhkar App',
          subtitle: 'Smart Zakat Calculator, Asset Breakdown, and Charity Tracker',
          blocks: [
            BookContentBlock.heading('3. App Tools for Calculating and Managing Zakat', level: 1),
            BookContentBlock.paragraph(
              'The Adhkar app includes an intuitive, comprehensive Zakat Calculator tailored to modern financial assets, currencies, and real-time live Nisab calculations.',
            ),
            BookContentBlock.box(
              text: '[Screenshot Placeholder: Zakat Calculator Screen with Asset Fields & Summary in Adhkar App]',
              title: '📸 Zakat Calculator Screenshot',
              boxType: BookBoxType.highlight,
            ),
            BookContentBlock.heading('Key Features in the Adhkar App Zakat Module:', level: 2),
            BookContentBlock.bulletPoints([
              'Smart Multi-Asset Calculator: Enter cash balances, bank accounts, gold weight, silver weight, investments, and business stock with automatic deduction of immediate liabilities.',
              'Live Gold/Silver Nisab Selection: Switch between Gold Nisab (87.48g) and Silver Nisab (612.36g) based on your local scholar preference.',
              'Charity & Sadaqah Manager: Record given contributions, track recurring charity goals, and keep receipts organized.',
              'Annual Hawl Reminder: Set a calendar date notification when your lunar year of holding wealth completes.',
            ]),
            BookContentBlock.box(
              text: '[Screenshot Placeholder: Charity History & Distribution Breakdown in Adhkar App]',
              title: '📸 Charity Tracker Screenshot',
              boxType: BookBoxType.highlight,
            ),
          ],
        ),
      ],
    ),
  ];

  /// Get user's saved books from Hive storage
  static Future<List<BookModel>> getUserBooks() async {
    final box = await Hive.openBox(_boxName);
    final String? rawJson = box.get('user_books_list');
    if (rawJson == null || rawJson.isEmpty) {
      final defaultUserBooks = List<BookModel>.from(prebuiltLibrary);
      await saveUserBooks(defaultUserBooks);
      return defaultUserBooks;
    }

    try {
      final List<dynamic> list = jsonDecode(rawJson);
      final loaded = list
          .map((item) => BookModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // Ensure user books list strictly reflects the 4 official prebuilt books + user custom uploaded books
      final synced = prebuiltLibrary.map((prebuilt) {
        final existing = loaded.firstWhere(
          (b) => b.id == prebuilt.id,
          orElse: () => prebuilt,
        );
        return prebuilt.copyWith(
          readProgress: existing.readProgress,
          currentPage: existing.currentPage,
          isAdded: existing.isAdded,
        );
      }).toList();

      // Include custom user uploaded books if any
      final customBooks = loaded.where((b) => b.isCustom).toList();
      final allBooks = [...synced, ...customBooks];

      await saveUserBooks(allBooks);
      return allBooks;
    } catch (_) {
      return prebuiltLibrary;
    }
  }

  /// Save user's book list to Hive
  static Future<void> saveUserBooks(List<BookModel> books) async {
    final box = await Hive.openBox(_boxName);
    final rawJson = jsonEncode(books.map((b) => b.toJson()).toList());
    await box.put('user_books_list', rawJson);
  }

  /// Add a new book (from library or custom upload)
  static Future<List<BookModel>> addBook(BookModel book) async {
    final current = await getUserBooks();
    if (!current.any((b) => b.id == book.id)) {
      final updated = [...current, book.copyWith(isAdded: true)];
      await saveUserBooks(updated);
      return updated;
    }
    return current;
  }

  /// Remove a book from user's shelf
  static Future<List<BookModel>> removeBook(String bookId) async {
    final current = await getUserBooks();
    final updated = current.where((b) => b.id != bookId).toList();
    await saveUserBooks(updated);
    return updated;
  }

  /// Update reading progress for a book
  static Future<List<BookModel>> updateProgress({
    required String bookId,
    required double progress,
    required int currentPage,
  }) async {
    final current = await getUserBooks();
    final updated = current.map((b) {
      if (b.id == bookId) {
        return b.copyWith(
          readProgress: progress.clamp(0.0, 1.0),
          currentPage: currentPage,
        );
      }
      return b;
    }).toList();
    await saveUserBooks(updated);
    return updated;
  }
}
