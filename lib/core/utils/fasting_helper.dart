import 'package:flutter/material.dart';
import 'hijri_date_helper.dart';

enum FastingType {
  fard, // Obligatory (Ramadan)
  sunnahMuakkadah, // Highly Recommended (Arafah, Ashura, 9th Dhul Hijjah)
  sunnah, // Recommended (Ayyam al-Beed, Shawwal 6 days, Mon/Thu, 9th/11th Muharram)
  prohibited, // Haram to fast (Eid al-Fitr, Eid al-Adha, Days of Tashreeq)
  none,
}

class FastingDayInfo {
  final String title;
  final String subtitle;
  final String description;
  final String hadith;
  final String? arabicHadith;
  final FastingType type;
  final Color primaryColor;
  final IconData icon;
  final String badgeText;

  const FastingDayInfo({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.hadith,
    this.arabicHadith,
    required this.type,
    required this.primaryColor,
    required this.icon,
    required this.badgeText,
  });
}

class FastingHelper {
  /// Returns detailed information about the fasting status & significance for a given date.
  static FastingDayInfo? getFastingInfo(DateTime date, HijriDate hijri) {
    final day = hijri.day;
    final month = hijri.month; // 1 = Muharram, 9 = Ramadan, 10 = Shawwal, 12 = Dhu al-Hijjah

    // 1. Prohibited Fasting Days (Haram)
    // Eid al-Fitr (1st Shawwal)
    if (month == 10 && day == 1) {
      return const FastingDayInfo(
        title: 'Eid al-Fitr (1st Shawwal)',
        subtitle: 'Fasting Prohibited (Haram)',
        description:
            'Fasting on the day of Eid al-Fitr is strictly prohibited in Islam, as it is a day of feast and celebration provided by Allah.',
        hadith:
            '"The Messenger of Allah (ﷺ) forbade fasting on two days: the day of Fitr and the day of Adha." (Sahih al-Bukhari 1991)',
        arabicHadith:
            'نَهَى رَسُولُ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ عَنْ صِيَامِ يَوْمَيْنِ: يَوْمِ الْفِطْرِ وَيَوْمِ الأَضْحَى',
        type: FastingType.prohibited,
        primaryColor: Color(0xFFDC2626),
        icon: Icons.block_rounded,
        badgeText: 'Prohibited Day',
      );
    }

    // Eid al-Adha & Days of Tashreeq (10th, 11th, 12th, 13th Dhu al-Hijjah)
    if (month == 12 && (day >= 10 && day <= 13)) {
      final isEid = day == 10;
      return FastingDayInfo(
        title: isEid
            ? 'Eid al-Adha (10th Dhu al-Hijjah)'
            : 'Day of Tashreeq (${day}th Dhu al-Hijjah)',
        subtitle: 'Fasting Prohibited (Haram)',
        description: isEid
            ? 'Fasting on Eid al-Adha is prohibited as it is a day of sacrifice, celebration, and gratitude.'
            : 'The Days of Tashreeq (11th, 12th, 13th Dhu al-Hijjah) are days of eating, drinking, and remembering Allah.',
        hadith:
            '"The days of Tashreeq are days of eating, drinking, and remembering Allah." (Sahih Muslim 1141)',
        arabicHadith: 'أَيَّامُ التَّشْرِيقِ أَيَّامُ أَكْلٍ وَشُرْبٍ وَذِكْرٍ لِلَّهِ',
        type: FastingType.prohibited,
        primaryColor: const Color(0xFFDC2626),
        icon: Icons.block_rounded,
        badgeText: 'Prohibited Day',
      );
    }

    // 2. Obligatory Fasting (Fard): Ramadan (Month 9)
    if (month == 9) {
      return FastingDayInfo(
        title: 'Month of Ramadan (Day $day)',
        subtitle: 'Obligatory Fasting (Fard)',
        description:
            'Fasting during the holy month of Ramadan is one of the Five Pillars of Islam. The gates of Paradise are opened and rewards are immensely multiplied.',
        hadith:
            '"Whoever fasts Ramadan out of faith and in the hope of reward, his previous sins will be forgiven." (Sahih al-Bukhari 38, Sahih Muslim 760)',
        arabicHadith:
            'مَنْ صَامَ رَمَضَانَ إِيمَانًا وَاحْتِسَابًا غُفِرَ لَهُ مَا تَقَدَّمَ مِنْ ذَنْبِهِ',
        type: FastingType.fard,
        primaryColor: const Color(0xFF15803D),
        icon: Icons.nightlight_round,
        badgeText: 'Ramadan Fasting',
      );
    }

    // 3. Highly Recommended: Day of Arafah (9th Dhu al-Hijjah)
    if (month == 12 && day == 9) {
      return const FastingDayInfo(
        title: 'Day of Arafah (9th Dhu al-Hijjah)',
        subtitle: 'Expiates Sins of 2 Years',
        description:
            'Fasting on the Day of Arafah is the most virtuous voluntary fast of the entire year for non-pilgrims.',
        hadith:
            '"Fasting on the day of Arafah expiates the sins of the preceding year and the coming year." (Sahih Muslim 1162)',
        arabicHadith:
            'صِيَامُ يَوْمِ عَرَفَةَ أَحْتَسِبُ عَلَى اللَّهِ أَنْ يُكَفِّرَ السَّنَةَ الَّتِي قَبْلَهُ وَالسَّنَةَ الَّتِي بَعْدَهُ',
        type: FastingType.sunnahMuakkadah,
        primaryColor: Color(0xFFB45309),
        icon: Icons.workspace_premium_rounded,
        badgeText: 'Day of Arafah',
      );
    }

    // 4. Highly Recommended: First 8 Days of Dhu al-Hijjah (1st - 8th Dhu al-Hijjah)
    if (month == 12 && (day >= 1 && day <= 8)) {
      return FastingDayInfo(
        title: '10 Days of Dhu al-Hijjah (Day $day)',
        subtitle: 'Blessed Days of Worship',
        description:
            'The first ten days of Dhu al-Hijjah are the most sacred days of the Islamic year. Voluntary fasting during these days carries immense rewards.',
        hadith:
            '"There are no days in which righteous deeds are more beloved to Allah than these ten days." (Sahih al-Bukhari 969)',
        arabicHadith:
            'مَا مِنْ أَيَّامٍ الْعَمَلُ الصَّالِحُ فِيهَا أَحَبُّ إِلَى اللَّهِ مِنْ هَذِهِ الأَيَّامِ',
        type: FastingType.sunnahMuakkadah,
        primaryColor: const Color(0xFFD97724),
        icon: Icons.auto_awesome_rounded,
        badgeText: '10 Days of Zul Hijjah',
      );
    }

    // 5. Highly Recommended: Day of Ashura (10th Muharram)
    if (month == 1 && day == 10) {
      return const FastingDayInfo(
        title: 'Day of Ashura (10th Muharram)',
        subtitle: 'Expiates Previous Year Sins',
        description:
            'Fasting on Ashura commemorates Allah saving Prophet Musa (AS) and the Children of Israel. It expiates the sins of the past year.',
        hadith:
            '"Fasting the day of Ashura, I hope that Allah will accept it as expiation for the year that went before it." (Sahih Muslim 1162)',
        arabicHadith:
            'صِيَامُ يَوْمِ عَاشُورَاءَ أَحْتَسِبُ عَلَى اللَّهِ أَنْ يُكَفِّرَ السَّنَةَ الَّتِي قَبْلَهُ',
        type: FastingType.sunnahMuakkadah,
        primaryColor: Color(0xFF0D9488),
        icon: Icons.star_rounded,
        badgeText: 'Day of Ashura',
      );
    }

    // 6. Recommended: Tasu'a or 11th Muharram (9th & 11th Muharram)
    if (month == 1 && (day == 9 || day == 11)) {
      final label = day == 9 ? 'Tasu\'a (9th Muharram)' : '11th Muharram';
      return FastingDayInfo(
        title: '$label Fasting',
        subtitle: 'Companion Fast of Ashura',
        description:
            'Fasting the 9th or 11th of Muharram alongside the 10th (Ashura) is a cherished Sunnah of the Prophet Muhammad (ﷺ).',
        hadith:
            '"If I remain alive until next year, I will certainly fast the ninth day [along with the tenth]." (Sahih Muslim 1134)',
        arabicHadith: 'لَئِنْ بَقِيتُ إِلَى قَابِلٍ لأَصُومَنَّ التَّاسِعَ',
        type: FastingType.sunnah,
        primaryColor: const Color(0xFF0D9488),
        icon: Icons.auto_awesome_rounded,
        badgeText: 'Sunnah Muharram',
      );
    }

    // 7. Recommended: 6 Days of Shawwal (Days 2 to 30 of Shawwal)
    if (month == 10 && (day >= 2 && day <= 30)) {
      return FastingDayInfo(
        title: '6 Days of Shawwal (Day $day Hijri)',
        subtitle: 'Reward of Fasting Entire Year',
        description:
            'Fasting any six voluntary days in Shawwal after completing Ramadan yields the spiritual reward of fasting an entire year.',
        hadith:
            '"Whoever fasts Ramadan and follows it with six days of Shawwal, it is as if he fasted for a lifetime." (Sahih Muslim 1164)',
        arabicHadith:
            'مَنْ صَامَ رَمَضَانَ ثُمَّ أَتْبَعَهُ سِتًّا مِنْ شَوَّالٍ كَانَ كَصِيَامِ الدَّهْرِ',
        type: FastingType.sunnah,
        primaryColor: const Color(0xFF7E22CE),
        icon: Icons.verified_rounded,
        badgeText: '6 Days of Shawwal',
      );
    }

    // 8. Recommended: Ayyam al-Beed (13th, 14th, 15th Hijri)
    if (day == 13 || day == 14 || day == 15) {
      return FastingDayInfo(
        title: 'Ayyam al-Beed (${day}th Hijri)',
        subtitle: 'The White Days (Full Moon)',
        description:
            'Fasting the 13th, 14th, and 15th of every lunar month is equivalent to fasting for a lifetime.',
        hadith:
            '"Fasting three days of each month is equivalent to fasting for a lifetime." (Sunan an-Nasa\'i 2420)',
        arabicHadith: 'صِيَامُ ثَلاَثَةِ أَيَّامٍ مِنْ كُلِّ شَهْرٍ صِيَامُ الدَّهْرِ',
        type: FastingType.sunnah,
        primaryColor: const Color(0xFFD97724),
        icon: Icons.brightness_2_rounded,
        badgeText: 'Ayyam al-Beed',
      );
    }

    // 9. Recommended: Monday & Thursday Weekly Sunnah Fasting
    if (date.weekday == DateTime.monday || date.weekday == DateTime.thursday) {
      final dayName = date.weekday == DateTime.monday ? 'Monday' : 'Thursday';
      return FastingDayInfo(
        title: 'Sunnah $dayName Fasting',
        subtitle: 'Weekly Sunnah Fasting',
        description:
            'Deeds are presented to Allah on Mondays and Thursdays. The Prophet (ﷺ) loved to be fasting when his deeds were presented.',
        hadith:
            '"Deeds are presented on Monday and Thursday, and I love that my deeds be presented while I am fasting." (Jami` at-Tirmidhi 747)',
        arabicHadith:
            'تُعْرَضُ الأَعْمَالُ يَوْمَ الاِثْنَيْنِ وَالْخَمِيسِ فَأُحِبُّ أَنْ يُعْرَضَ عَمَلِي وَأَنَا صَائِمٌ',
        type: FastingType.sunnah,
        primaryColor: const Color(0xFF059669),
        icon: Icons.event_repeat_rounded,
        badgeText: 'Sunnah $dayName',
      );
    }

    return null;
  }

  /// List of all major significant fasting occasions in Islam for educational & exploration UI.
  static List<FastingDayInfo> getSignificantOccasionsList() {
    return [
      const FastingDayInfo(
        title: 'Holy Month of Ramadan',
        subtitle: '30 Days Obligatory (Fard)',
        description:
            'Fasting during Ramadan is one of the Five Pillars of Islam. The Quran was revealed in this month, and sins are forgiven for sincere fasters.',
        hadith:
            '"Whoever fasts Ramadan out of faith and in the hope of reward, his previous sins will be forgiven." (Bukhari & Muslim)',
        arabicHadith:
            'مَنْ صَامَ رَمَضَانَ إِيمَانًا وَاحْتِسَابًا غُفِرَ لَهُ مَا تَقَدَّمَ مِنْ ذَنْبِهِ',
        type: FastingType.fard,
        primaryColor: Color(0xFF15803D),
        icon: Icons.nightlight_round,
        badgeText: '1st Pillar of Fasting',
      ),
      const FastingDayInfo(
        title: 'First 10 Days of Dhu al-Hijjah & Day of Arafah',
        subtitle: '1st - 9th Dhu al-Hijjah',
        description:
            'The first 9 days of Dhu al-Hijjah are the most sacred days of worship. Fasting on the 9th day (Day of Arafah) expiates 2 years of sins.',
        hadith:
            '"Fasting on the day of Arafah expiates the sins of the preceding year and the coming year." (Sahih Muslim 1162)',
        arabicHadith:
            'صِيَامُ يَوْمِ عَرَفَةَ أَحْتَسِبُ عَلَى اللَّهِ أَنْ يُكَفِّرَ السَّنَةَ الَّتِي قَبْلَهُ وَالسَّنَةَ الَّتِي بَعْدَهُ',
        type: FastingType.sunnahMuakkadah,
        primaryColor: Color(0xFFB45309),
        icon: Icons.workspace_premium_rounded,
        badgeText: 'Zul Hijjah Highlights',
      ),
      const FastingDayInfo(
        title: 'Day of Ashura & Tasu\'a (Muharram)',
        subtitle: '9th, 10th & 11th Muharram',
        description:
            'Fasting the 10th of Muharram (Ashura) along with the 9th (Tasu\'a) or 11th commemorates Prophet Musa (AS) and expiates the previous year\'s sins.',
        hadith:
            '"Fasting the day of Ashura, I hope that Allah will accept it as expiation for the year that went before it." (Sahih Muslim 1162)',
        arabicHadith:
            'صِيَامُ يَوْمِ عَاشُورَاءَ أَحْتَسِبُ عَلَى اللَّهِ أَنْ يُكَفِّرَ السَّنَةَ الَّتِي قَبْلَهُ',
        type: FastingType.sunnahMuakkadah,
        primaryColor: Color(0xFF0D9488),
        icon: Icons.star_rounded,
        badgeText: 'Muharram Highlights',
      ),
      const FastingDayInfo(
        title: '6 Days of Shawwal',
        subtitle: '2nd - 30th Shawwal',
        description:
            'Fasting 6 voluntary days in the month of Shawwal after Ramadan equals the reward of fasting an entire year continuous.',
        hadith:
            '"Whoever fasts Ramadan and follows it with six days of Shawwal, it is as if he fasted for a lifetime." (Sahih Muslim 1164)',
        arabicHadith:
            'مَنْ صَامَ رَمَضَانَ ثُمَّ أَتْبَعَهُ سِتًّا مِنْ شَوَّالٍ كَانَ كَصِيَامِ الدَّهْرِ',
        type: FastingType.sunnah,
        primaryColor: Color(0xFF7E22CE),
        icon: Icons.verified_rounded,
        badgeText: 'Full Year Reward',
      ),
      const FastingDayInfo(
        title: 'Ayyam al-Beed (The White Days)',
        subtitle: '13th, 14th & 15th of Every Hijri Month',
        description:
            'Fasting the three middle days of each Islamic lunar month when the moon is brightest carries perpetual blessings.',
        hadith:
            '"Fasting three days of each month is equivalent to fasting for a lifetime." (Sunan an-Nasa\'i 2420)',
        arabicHadith: 'صِيَامُ ثَلاَثَةِ أَيَّامٍ مِنْ كُلِّ شَهْرٍ صِيَامُ الدَّهْرِ',
        type: FastingType.sunnah,
        primaryColor: Color(0xFFD97724),
        icon: Icons.brightness_2_rounded,
        badgeText: 'Monthly Sunnah',
      ),
      const FastingDayInfo(
        title: 'Mondays & Thursdays Fasting',
        subtitle: 'Weekly Sunnah Fasting',
        description:
            'The Prophet Muhammad (ﷺ) regularly fasted on Mondays and Thursdays because human deeds are presented to Allah on these days.',
        hadith:
            '"Deeds are presented on Monday and Thursday, and I love that my deeds be presented while I am fasting." (Tirmidhi 747)',
        arabicHadith:
            'تُعْرَضُ الأَعْمَالُ يَوْمَ الاِثْنَيْنِ وَالْخَمِيسِ فَأُحِبُّ أَنْ يُعْرَضَ عَمَلِي وَأَنَا صَائِمٌ',
        type: FastingType.sunnah,
        primaryColor: Color(0xFF059669),
        icon: Icons.event_repeat_rounded,
        badgeText: 'Weekly Sunnah',
      ),
    ];
  }
}
