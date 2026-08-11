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
  ];

  /// Get user's saved books from Hive storage
  static Future<List<BookModel>> getUserBooks() async {
    final box = await Hive.openBox(_boxName);
    final String? rawJson = box.get('user_books_list');
    if (rawJson == null || rawJson.isEmpty) {
      // Default initial books: Add Hisnul Muslim, Forty Hadith, Riyad as-Salihin, and Sealed Nectar
      final defaultUserBooks = [
        prebuiltLibrary[0], // Hisnul Muslim (in_app)
        prebuiltLibrary[1], // Forty Hadith (in_app)
        prebuiltLibrary[2], // Riyad as-Salihin (both)
        prebuiltLibrary[3], // Sealed Nectar (both)
        prebuiltLibrary[4], // Kitab at-Tawheed (external)
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
          return book.copyWith(openMode: match.openMode);
        }
        return book;
      }).toList();

      return synced;
    } catch (_) {
      return prebuiltLibrary.take(5).toList();
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
