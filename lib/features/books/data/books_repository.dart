import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/book_model.dart';

class BooksRepository {
  static const String _boxName = 'user_books_box';

  /// Pre-built library of essential Islamic books
  static final List<BookModel> prebuiltLibrary = [
    BookModel(
      id: 'hisnul_muslim',
      title: 'Hisnul Muslim',
      author: "Sa'id bin Ali bin Wahf Al-Qahtani",
      category: 'Dua & Adhkar',
      description:
          'Fortress of the Muslim: Invocations from the Quran and Sunnah. One of the most famous & authentic collections of daily supplications.',
      coverUrl: '',
      coverGradient: [const Color(0xFF1E3816), const Color(0xFF2A531D)],
      fileUrl: 'https://hisnulmuslim.com/',
      openMode: 'in_app', // In-App Reader Only
      totalPages: 120,
      chapters: [
        const BookChapter(
          title: 'Supplications for Waking Up',
          content:
              'الحَمْدُ للهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ\n\n"All praise is for Allah Who gave us life after having taken it from us and unto Him is the resurrection."',
        ),
        const BookChapter(
          title: 'Supplications Before Sleeping',
          content:
              'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ\n\n"In Your name my Lord I lie down and in Your name I rise. If You should take my soul, have mercy upon it, and if You should return my soul then protect it."',
        ),
        const BookChapter(
          title: 'Morning & Evening Remembrances',
          content:
              'أَصْبَحْنَا وَأَصْبَحَ المُلْكُ للَّهِ، وَالحَمْدُ للَّهِ\n\n"We have reached the morning and at this very time all sovereignty belongs to Allah, Lord of the Worlds."',
        ),
      ],
    ),
    BookModel(
      id: 'forty_hadith_nawawi',
      title: 'Forty Hadith Nawawi',
      author: 'Imam al-Nawawi',
      category: 'Hadith',
      description:
          'A selection of forty fundamental Hadiths covering the core foundational principles of Islamic belief, worship, and moral character.',
      coverUrl: '',
      coverGradient: [const Color(0xFF0F766E), const Color(0xFF134E4A)],
      fileUrl: 'https://40hadithnawawi.com/',
      openMode: 'in_app', // In-App Reader Only
      totalPages: 80,
      chapters: [
        const BookChapter(
          title: 'Hadith 1: Actions depend on Intentions',
          content:
              'On the authority of Umar (RA) who said: I heard the Messenger of Allah (ﷺ) say: "Actions are but by intentions and each person will have but what he intended."',
        ),
        const BookChapter(
          title: 'Hadith 2: Islam, Iman, and Ihsan (Jibreel Hadith)',
          content:
              'A man with exceedingly white clothes came and asked: "O Muhammad, tell me about Islam..." The Prophet answered describing the 5 pillars, the 6 pillars of Iman, and Ihsan.',
        ),
        const BookChapter(
          title: 'Hadith 3: The Five Pillars of Islam',
          content:
              'The Messenger of Allah (ﷺ) said: "Islam is built upon five: testifying that there is no god but Allah and Muhammad is His messenger, performing prayer, giving Zakat, Hajj, and fasting Ramadan."',
        ),
      ],
    ),
    BookModel(
      id: 'riyad_as_salihin',
      title: 'Riyad as-Salihin',
      author: 'Imam Yahya ibn Sharaf al-Nawawi',
      category: 'Hadith',
      description:
          'The Meadows of the Righteous is a compilation of verses from the Quran supplemented by hadith narratives on moral conduct, worship, and manners.',
      coverUrl: '',
      coverGradient: [const Color(0xFFC0392B), const Color(0xFF8E44AD)],
      fileUrl: 'https://archive.org/details/RiyadAsSalihinEnglishArabic',
      openMode: 'both', // Both In-App Reader & External App Link
      totalPages: 350,
      chapters: [
        const BookChapter(
          title: 'Chapter 1: Sincerity and Intention (Ikhlas)',
          content:
              'Actions are judged by intentions. Allah the Almighty says: "And they were commanded not except to worship Allah, [being] sincere to Him in religion..." (98:5)\n\nNarrated Umar bin Al-Khattab (RA): I heard the Messenger of Allah (ﷺ) say: "The reward of deeds depends upon the intentions and every person will get the reward according to what he has intended."',
        ),
        const BookChapter(
          title: 'Chapter 2: Repentance (Tawbah)',
          content:
              'Allah the Exalted says: "And turn to Allah in repentance, all of you, O believers, that you might succeed." (24:31)\n\nAbu Hurairah (RA) reported: I heard the Messenger of Allah (ﷺ) say: "By Allah, I seek Allah\'s forgiveness and turn to Him in repentance more than seventy times a day."',
        ),
        const BookChapter(
          title: 'Chapter 3: Patience (Sabr)',
          content:
              'Allah the Exalted says: "O you who have believed, seek help through patience and prayer. Indeed, Allah is with the patient." (2:153)\n\nAbu Malik Al-Ash\'ari (RA) reported: The Messenger of Allah (ﷺ) said: "Purity is half of faith... and patience is illumination."',
        ),
      ],
    ),
    BookModel(
      id: 'sealed_nectar',
      title: 'The Sealed Nectar',
      author: 'Safiur Rahman Mubarakpuri',
      category: 'Seerah',
      description:
          'Ar-Raheeq Al-Makhtum: A complete authoritative book on the life and biography of the Prophet Muhammad (ﷺ), awarded 1st prize by the Muslim World League.',
      coverUrl: '',
      coverGradient: [const Color(0xFFD97724), const Color(0xFF92400E)],
      fileUrl: 'https://archive.org/details/TheSealedNectar_201503',
      openMode: 'both', // Both In-App Reader & External App Link
      totalPages: 420,
      chapters: [
        const BookChapter(
          title: 'Chapter 1: Location and Tribes of the Arabs',
          content:
              'Arabia is bounded by the Mediterranean Sea and Sinai on the west, the Red Sea on the southwest, and the Indian Ocean on the south. In this historic peninsula, the final Prophet of Allah was born to guide mankind to the light of Islam.',
        ),
        const BookChapter(
          title: 'Chapter 2: The Birth and Forty Years of Noble Life',
          content:
              'Muhammad (ﷺ) was born in Makkah in the Year of the Elephant (570 CE). He grew up known among his people as Al-Amin (the Trustworthy) and As-Sadiq (the Truthful).',
        ),
        const BookChapter(
          title: 'Chapter 3: The First Revelation in Cave Hira',
          content:
              'In the month of Ramadan at age 40, Angel Jibreel descended upon Muhammad (ﷺ) in Cave Hira with the first verses of Surah Al-Alaq: "Recite in the name of your Lord who created..."',
        ),
      ],
    ),
    BookModel(
      id: 'kitab_at_tawheed',
      title: 'Kitab at-Tawheed',
      author: 'Muhammad ibn Abd al-Wahhab',
      category: 'Aqeedah',
      description:
          'The Book of Monotheism: A classic Islamic treatise detailing the true meaning of Tawheed, pure worship of Allah, and avoiding all forms of Shirk.',
      coverUrl: '',
      coverGradient: [const Color(0xFF1E3A8A), const Color(0xFF1D4ED8)],
      fileUrl: 'https://archive.org/details/KitabAtTawheedEnglish',
      openMode: 'external', // External App Only
      totalPages: 160,
      chapters: [
        const BookChapter(
          title: 'Chapter 1: The Virtue of Tawheed',
          content:
              'Allah the Almighty says: "And I did not create the jinn and mankind except to worship Me." (51:56)\n\nTawheed is the supreme right of Allah over His servants, guaranteeing safety in this life and the Hereafter.',
        ),
      ],
    ),
    BookModel(
      id: 'tafsir_ibn_kathir',
      title: 'Tafsir Ibn Kathir',
      author: 'Imam Hafiz Ibn Kathir',
      category: 'Tafsir',
      description:
          'One of the most respected and accepted explanations of the Quran in the Muslim world, explaining Quranic verses with Hadiths and Sahabah statements.',
      coverUrl: '',
      coverGradient: [const Color(0xFF7C2D12), const Color(0xFF451A03)],
      fileUrl: 'https://quran.com/',
      openMode: 'both',
      totalPages: 600,
      chapters: [
        const BookChapter(
          title: 'Exegesis of Surah Al-Fatiha',
          content:
              'Surah Al-Fatiha is called Umm al-Kitab (the Mother of the Book) and Sab\'an min al-Mathani (Seven Oft-Repeated Verses). It encapsulates the entirety of Quranic guidance.',
        ),
      ],
    ),
    BookModel(
      id: 'tazkiyah_al_nafs',
      title: 'Purification of the Soul',
      author: 'Ibn Rajab & Ibn al-Qayyim',
      category: 'Tazkiyah',
      description:
          'A spiritual guide on purifying the heart from spiritual diseases, envy, arrogance, and turning to Allah with humility and sincerity.',
      coverUrl: '',
      coverGradient: [const Color(0xFF047857), const Color(0xFF065F46)],
      fileUrl: 'https://archive.org/details/PurificationOfTheSoul',
      openMode: 'in_app',
      totalPages: 190,
      chapters: [
        const BookChapter(
          title: 'The Types of Hearts',
          content:
              'There are three types of hearts: The Healthy Heart (Qalb Saleem), The Dead Heart (Qalb Mayyit), and The Diseased Heart (Qalb Mareed). The successful soul strives for a healthy heart.',
        ),
      ],
    ),
    BookModel(
      id: 'qisas_al_anbiya',
      title: 'Stories of the Prophets', 
      author: 'Imam Hafiz Ibn Kathir',
      category: 'Seerah',
      description:
          'Comprehensive accounts of the lives, trials, miracles, and noble teachings of all Prophets mentioned in the Holy Quran.',
      coverUrl: '',
      coverGradient: [const Color(0xFFB45309), const Color(0xFF78350F)],
      fileUrl: 'https://archive.org/details/StoriesOfTheProphetsIbnKathir',
      openMode: 'both',
      totalPages: 380,
      chapters: [
        const BookChapter(
          title: 'Story of Prophet Adam (AS)',
          content:
              'Allah created Adam (AS) from clay and breathed into him his spirit, commanding the angels to prostrate to him in honor of knowledge.',
        ),
      ],
    ),
    BookModel(
      id: 'namaz_guide_book',
      title: 'The Ultimate Namaz & Salah Guide',
      author: 'Adhkar Islamic Library',
      category: 'Fiqh & Worship',
      description:
          'A comprehensive Islamic guide detailing the virtues of Namaz (Salah), conditions of prayer, step-by-step guidance, and using the Adhkar Namaz tracker.',
      coverUrl: '',
      coverGradient: [const Color(0xFF0891B2), const Color(0xFF0E7490)],
      fileUrl: '',
      openMode: 'in_app',
      totalPages: 25,
      chapters: [
        const BookChapter(
          title: 'Chapter 1: The Status & Importance of Namaz in Islam',
          content:
              'Salah (Namaz) is the second pillar of Islam and the first deed a servant will be questioned about on the Day of Resurrection. The Prophet (ﷺ) said: "The key to Paradise is Salah." It connects the soul directly to Allah five times daily.',
        ),
        const BookChapter(
          title: 'Chapter 2: Essential Prerequisites (Wudu & Qibla)',
          content:
              'Before performing Namaz, a Muslim must ensure ritual purity (Taharah) through Wudu (ablution), wear clean clothes, face the Qibla (Makkah), and make a sincere intention in the heart for the specific prayer.',
        ),
        const BookChapter(
          title: 'Chapter 3: How to Perform Namaz Step-by-Step',
          content:
              '1. Takbir al-Ihram: Stand facing Qibla, raise hands to ears, say "Allahu Akbar".\n2. Qiyam & Recitation: Recite Surah Al-Fatiha followed by another Quranic passage.\n3. Ruku (Bowing): Bow with hands on knees, say "Subhana Rabbiyal A\'dheem" 3 times.\n4. Sujud (Prostration): Prostrate with forehead, nose, palms, knees, and toes touching the ground, say "Subhana Rabbiyal A\'la" 3 times.\n5. Tashahhud & Salam: Sit for final Tashahhud, send blessings on the Prophet (ﷺ), and end with Salam to the right and left.',
        ),
        const BookChapter(
          title: 'Chapter 4: Using Adhkar App Namaz Tracker',
          content:
              'Adhkar App helps you stay consistent with your daily Namaz:\n- Accurate location-based prayer times & Qibla compass.\n- Tap prayer cards on the Home & Namaz screens to mark Farz, Sunnah, and Nafl prayers completed.\n- View daily, weekly, and monthly consistency streaks to build a lifelong habit of timely prayer.',
        ),
      ],
    ),
    BookModel(
      id: 'roza_guide_book',
      title: 'The Complete Roza & Fasting Guide',
      author: 'Adhkar Islamic Library',
      category: 'Fiqh & Worship',
      description:
          'An essential guide on Roza (Sawm): spiritual blessings of Ramadan, rules, intentions, voluntary fasts, and tracking fasts in Adhkar App.',
      coverUrl: '',
      coverGradient: [const Color(0xFFE11D48), const Color(0xFFBE123C)],
      fileUrl: '',
      openMode: 'in_app',
      totalPages: 20,
      chapters: [
        const BookChapter(
          title: 'Chapter 1: The Pillars & Virtues of Roza (Fasting)',
          content:
              'Roza (Sawm) during Ramadan is the fourth pillar of Islam. Allah says in Hadith Qudsi: "Fasting is for Me, and I shall reward for it." Fasting purifies the soul, cultivates Taqwa (God-consciousness), empathy for the needy, and self-discipline.',
        ),
        const BookChapter(
          title: 'Chapter 2: Rules of Fasting, Niyyah & Suhoor/Iftar',
          content:
              '1. Niyyah (Intention): Intend in the heart before Fajr to fast for Allah.\n2. Suhoor (Pre-dawn meal): A blessed Sunnah meal eaten before Fajr.\n3. Abstinence: Refrain from eating, drinking, and marital relations from dawn to sunset.\n4. Iftar (Breaking fast): Break the fast at Maghrib, preferably with dates or water, making dua.',
        ),
        const BookChapter(
          title: 'Chapter 3: Sunnah & Voluntary Fasts',
          content:
              'Beyond Ramadan, Islam highly recommends voluntary fasts:\n- Mondays & Thursdays.\n- The White Days (13th, 14th, 15th of each Hijri month).\n- Day of Arafah (9th Dhul Hijjah) & Day of Ashura (10th Muharram).\n- 6 days of Shawwal.',
        ),
        const BookChapter(
          title: 'Chapter 4: Using Adhkar App Roza Tracker',
          content:
              'With Adhkar App Roza feature:\n- Log daily fasts during Ramadan and voluntary Sunnah fasts throughout the year.\n- Track Suhoor & Iftar countdown timers tuned to your precise location.\n- Manage missed fasts (Qaza tracker) to ensure you complete obligations effortlessly.',
        ),
      ],
    ),
    BookModel(
      id: 'sadqa_zakat_guide_book',
      title: 'The Comprehensive Sadqa & Zakat Guide',
      author: 'Adhkar Islamic Library',
      category: 'Fiqh & Worship',
      description:
          'A detailed handbook on Sadaqah & Zakat: Nisab calculation rules, spiritual blessings of charity in Islam, and managing donations in Adhkar App.',
      coverUrl: '',
      coverGradient: [const Color(0xFF6366F1), const Color(0xFF7C3AED)],
      fileUrl: '',
      openMode: 'in_app',
      totalPages: 30,
      chapters: [
        const BookChapter(
          title: 'Chapter 1: Distinction Between Sadaqah & Obligatory Zakat',
          content:
              'Zakat is the third pillar of Islam—an obligatory annual 2.5% purity tax on wealth exceeding the Nisab threshold held for a full lunar year.\n\nSadaqah is voluntary charity given anytime out of love for Allah. The Prophet (ﷺ) said: "Charity does not decrease wealth."',
        ),
        const BookChapter(
          title: 'Chapter 2: Calculating Zakat (Nisab, Assets & Liabilities)',
          content:
              '1. Nisab Threshold: Equivalent to 87.48g of Gold or 612.36g of Silver.\n2. Eligible Assets: Cash, bank balances, gold, silver, investments, stocks, and trade merchandise.\n3. Deductions: Subtract short-term immediate debts/liabilities.\n4. Net Payable Zakat: 2.5% of total net zakat-eligible assets.',
        ),
        const BookChapter(
          title: 'Chapter 3: Sadaqah Jariyah & Spiritual Rewards',
          content:
              'Sadaqah Jariyah is continuous ongoing charity whose rewards continue even after death—such as building a mosque, digging a water well, planting trees, or sharing beneficial Islamic knowledge.',
        ),
        const BookChapter(
          title: 'Chapter 4: Using Adhkar App Sadaqah Log & Zakat Calculator',
          content:
              'Adhkar App empowers your charitable journey:\n- Instant Zakat Calculator: Calculate net Zakat by entering cash, gold, and liabilities.\n- Sadaqah Log: Record cash, food, or online donations and track monthly charity totals.\n- Online Donation: Make secure donations via Razorpay directly within the app and auto-log every transaction.',
        ),
      ],
    ),
  ];

  /// Get user's saved books from Hive storage
  static Future<List<BookModel>> getUserBooks() async {
    final box = await Hive.openBox(_boxName);
    final String? rawJson = box.get('user_books_list');
    if (rawJson == null || rawJson.isEmpty) {
      // Default initial books: Add Hisnul Muslim, Forty Hadith, Riyad as-Salihin, Sealed Nectar, and feature guide books
      final defaultUserBooks = [
        prebuiltLibrary[0], // Hisnul Muslim
        prebuiltLibrary[1], // Forty Hadith
        prebuiltLibrary[2], // Riyad as-Salihin
        prebuiltLibrary[3], // Sealed Nectar
        prebuiltLibrary[4], // Kitab at-Tawheed
        prebuiltLibrary.firstWhere((b) => b.id == 'namaz_guide_book'),
        prebuiltLibrary.firstWhere((b) => b.id == 'roza_guide_book'),
        prebuiltLibrary.firstWhere((b) => b.id == 'sadqa_zakat_guide_book'),
      ];
      await saveUserBooks(defaultUserBooks);
      return defaultUserBooks;
    }

    try {
      final List<dynamic> list = jsonDecode(rawJson);
      final loaded = list
          .map((item) => BookModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // Ensure prebuilt library items always reflect their updated openMode configuration
      final synced = loaded.map((book) {
        if (!book.isCustom) {
          final match = prebuiltLibrary.firstWhere(
            (p) => p.id == book.id,
            orElse: () => book,
          );
          return book.copyWith(
            openMode: match.openMode,
            chapters: match.chapters.isNotEmpty ? match.chapters : book.chapters,
          );
        }
        return book;
      }).toList();

      // Ensure guide books are present in user shelf
      for (final guideId in ['namaz_guide_book', 'roza_guide_book', 'sadqa_zakat_guide_book']) {
        if (!synced.any((b) => b.id == guideId)) {
          final guideBook = prebuiltLibrary.firstWhere((b) => b.id == guideId);
          synced.add(guideBook);
        }
      }

      return synced;
    } catch (_) {
      return prebuiltLibrary.take(8).toList();
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
