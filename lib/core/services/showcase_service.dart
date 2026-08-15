import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class ShowcaseService {
  static const String _keyHasSeenHomeShowcase = 'has_seen_home_showcase_v2';

  // GlobalKeys for Showcase targets
  static final GlobalKey keyNamazStartEnd = GlobalKey();
  static final GlobalKey keyRemainingTime = GlobalKey();
  static final GlobalKey keyHijriLocation = GlobalKey();

  // 9 Quick Link Tiles
  static final GlobalKey keyTileNamaz = GlobalKey();
  static final GlobalKey keyTileRoza = GlobalKey();
  static final GlobalKey keyTileSadqa = GlobalKey();
  static final GlobalKey keyTileTasbeeh = GlobalKey();
  static final GlobalKey keyTileAsmaUlHusna = GlobalKey();
  static final GlobalKey keyTileDua = GlobalKey();
  static final GlobalKey keyTileBooks = GlobalKey();
  static final GlobalKey keyTileSciIslam = GlobalKey();
  static final GlobalKey keyTileReminder = GlobalKey();

  // Bottom Tabs
  static final GlobalKey keyQuranTab = GlobalKey();
  static final GlobalKey keyAdhkarTab = GlobalKey();
  static final GlobalKey keyQiblaTab = GlobalKey();

  static Future<bool> hasSeenHomeShowcase() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenHomeShowcase) ?? false;
  }

  static Future<void> markHomeShowcaseAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenHomeShowcase, true);
  }

  static Future<void> resetHomeShowcase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenHomeShowcase, false);
  }

  static Future<void> stopShowcase(BuildContext context) async {
    await markHomeShowcaseAsSeen();
    try {
      ShowcaseView.get().startShowCase([]);
    } catch (_) {
      try {
        ShowCaseWidget.of(context).startShowCase([]);
      } catch (_) {}
    }
  }

  static void startHomeShowcase(BuildContext context) {
    ShowcaseView.get().startShowCase([
      keyNamazStartEnd,
      keyRemainingTime,
      keyHijriLocation,
      keyTileNamaz,
      keyTileRoza,
      keyTileSadqa,
      keyTileTasbeeh,
      keyTileAsmaUlHusna,
      keyTileDua,
      keyTileBooks,
      keyTileSciIslam,
      keyTileReminder,
      keyQuranTab,
      keyAdhkarTab,
      keyQiblaTab,
    ]);
  }
}
