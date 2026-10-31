import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_floating_toast.dart';
import '../../../widgets/app_header_bar.dart';
import '../domain/dua_item.dart';
import 'widgets/add_dua_modal.dart';

class DuaDetailScreen extends ConsumerStatefulWidget {
  final DuaItem dua;
  final String selectedLanguage;
  final VoidCallback? onDelete;
  final Function(DuaItem updatedDua)? onSave;

  const DuaDetailScreen({
    super.key,
    required this.dua,
    this.selectedLanguage = 'en',
    this.onDelete,
    this.onSave,
  });

  @override
  ConsumerState<DuaDetailScreen> createState() => _DuaDetailScreenState();
}

class _DuaDetailScreenState extends ConsumerState<DuaDetailScreen>
    with SingleTickerProviderStateMixin {
  late DuaItem _dua;
  late String _currentLang;
  bool _isPlaying = false;
  bool _isBuffering = false;
  StreamSubscription<AudioPlaybackState>? _playerStateSub;
  AppAudioService? _audioService;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _dua = widget.dua;
    _currentLang = widget.selectedLanguage;
    _loadPersistedLanguage();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _audioService = ref.read(audioServiceProvider);
      _playerStateSub = _audioService?.playbackStateStream.listen((state) {
        if (!mounted) return;
        final playing = state.isPlaying;
        setState(() {
          _isPlaying = playing;
          _isBuffering = state.isBuffering;
        });
        if (playing) {
          if (!_waveController.isAnimating)
            _waveController.repeat(reverse: true);
        } else {
          if (_waveController.isAnimating) _waveController.stop();
        }
      });
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _playerStateSub?.cancel();
    _audioService?.stop();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    final audioService = _audioService;
    if (audioService == null) return;

    if (_isPlaying) {
      await audioService.stop();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      if (_dua.audioUrl == null || _dua.audioUrl!.isEmpty) {
        AppFloatingToast.showAdded(
          context,
          message: 'Audio recitation not available for this Dua',
        );
        return;
      }

      setState(() => _isBuffering = true);
      try {
        final mediaItem = MediaItem(
          id: 'dua_${_dua.id}',
          album: 'Duaeen • Hisn al-Muslim',
          title: _dua.title,
          artist: 'Dua Recitation',
          extras: {
            'type': 'dua',
            'duaId': _dua.id,
            'route': '/dua/detail?id=${_dua.id}&lang=$_currentLang',
          },
        );
        await audioService.playUrl(_dua.audioUrl!, mediaItem: mediaItem);
      } catch (_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isBuffering = false;
          });
          AppFloatingToast.showAdded(
            context,
            message: 'Could not stream audio recitation',
          );
        }
      }
    }
  }

  void _confirmDelete(BuildContext context, [bool isDark = false]) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isDark
              ? const BorderSide(color: Color(0xFF27272A))
              : BorderSide.none,
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              _dua.isCustom ? 'Delete Dua?' : 'Remove Dua?',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
        content: Text(
          _dua.isCustom
              ? 'Are you sure you want to delete "${_dua.title}" permanently?'
              : 'Are you sure you want to remove "${_dua.title}"? You can re-add it anytime from the Dua Library.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              widget.onDelete?.call();
              Navigator.pop(context);
              AppFloatingToast.showRemoved(context, message: 'Removed');
            },
            child: Text(_dua.isCustom ? 'Delete' : 'Remove'),
          ),
        ],
      ),
    );
  }

  void _openEditModal() {
    AddDuaModal.show(
      context,
      initialDua: _dua,
      onSave: (updatedDua) {
        setState(() {
          _dua = updatedDua;
        });
        widget.onSave?.call(updatedDua);
        AppFloatingToast.showAdded(context, message: 'Updated');
      },
    );
  }

  static Color _getCategoryTextColor(String category, [bool isDark = false]) {
    if (isDark) {
      switch (category.trim().toLowerCase()) {
        case 'morning':
        case 'food':
          return const Color(0xFFFDE68A);
        case 'sleep':
          return const Color(0xFFBAE6FD);
        case 'hygiene':
          return const Color(0xFFFBCFE8);
        case 'travel':
          return const Color(0xFF86EFAC);
        case 'protection':
          return const Color(0xFFE9D5FF);
        case 'prayer':
        case 'adhan':
        case 'mosque':
          return const Color(0xFF86EFAC);
        case 'forgiveness':
          return const Color(0xFF99F6E4);
        default:
          return const Color(0xFF86EFAC);
      }
    }
    switch (category.trim().toLowerCase()) {
      case 'morning':
      case 'food':
        return const Color(0xFFB45309);
      case 'sleep':
        return const Color(0xFF1E3A8A);
      case 'hygiene':
        return const Color(0xFFDB2777);
      case 'travel':
        return const Color(0xFF047857);
      case 'protection':
        return const Color(0xFF7E22CE);
      case 'prayer':
      case 'adhan':
      case 'mosque':
        return const Color(0xFF1B5E20);
      case 'forgiveness':
        return const Color(0xFF0F766E);
      default:
        return const Color(0xFF1B5E20);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = _getCategoryTextColor(_dua.category, isDark);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F12) : Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppHeaderBar(
          title: _dua.getTitle(_currentLang),
          showBackButton: true,
          centerTitle: true,
          titleSpacing: 0,
          backgroundColor: isDark ? const Color(0xFF0F0F12) : Colors.white,
          actions: [
            // Edit Dua
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: isDark
                    ? const Color(0xFF18A74C)
                    : const Color(0xFF2A531D),
              ),
              tooltip: 'Edit Dua',
              onPressed: _openEditModal,
            ),

            // Delete / Remove Dua
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
              tooltip: _dua.isCustom ? 'Delete Custom Dua' : 'Remove Dua',
              onPressed: () => _confirmDelete(context, isDark),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Decorative Image at Bottom-Right Corner
            Positioned(
              bottom: 40,
              right: 12,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.2,
                  child: Image.asset(
                    _dua.imagePath,
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                    cacheWidth: 480,
                    cacheHeight: 480,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // Main Content
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Tags Row: Category Chip + Optional Repeat Count + Language Pills
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(
                                  alpha: isDark ? 0.2 : 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: isDark
                                    ? Border.all(
                                        color: themeColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Text(
                                _dua.category.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                  color: themeColor,
                                ),
                              ),
                            ),
                            if (_dua.repeatCount > 1) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97724),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Recite ${_dua.repeatCount}x',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Language Switcher Chips
                        Row(
                          children: [
                            _buildLangChip('en', 'EN', isDark),
                            const SizedBox(width: 4),
                            _buildLangChip('ur', 'UR', isDark),
                            const SizedBox(width: 4),
                            _buildLangChip('hi', 'HI', isDark),
                            const SizedBox(width: 4),
                            _buildLangChip('te', 'TE', isDark),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Main Title in Selected Language
                    Text(
                      _dua.getTitle(_currentLang),
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0,
                        color: isDark ? Colors.white : themeColor,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Large Arabic Text
                    SelectableText(
                      _dua.arabic,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: AppTypography.arabicHeader(
                        fontSize: 27,
                        height: 1.8,
                        color: isDark ? Colors.white : const Color(0xFF1A3512),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Divider(
                      color: isDark
                          ? const Color(0xFF27272A)
                          : const Color(0xFFE2E8F0),
                      thickness: 1.0,
                    ),
                    const SizedBox(height: 12),

                    // Transliteration in Selected Language
                    if (_dua.getTransliteration(_currentLang).isNotEmpty) ...[
                      SelectableText(
                        _dua.getTransliteration(_currentLang),
                        style: TextStyle(
                          fontSize: 15.5,
                          height: 1.45,
                          letterSpacing: 0,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Translation in Selected Language
                    SelectableText(
                      _dua.getTranslation(_currentLang),
                      style: GoogleFonts.lexend(
                        fontSize: 15,
                        height: 1.45,
                        letterSpacing: -0.4,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Reference Section
                    if (_dua.reference.isNotEmpty) ...[
                      Text(
                        'REFERENCE',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark
                              ? const Color(0xFFFDE68A)
                              : const Color(0xFFD97724),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _dua.reference,
                        style: TextStyle(
                          fontSize: 16.0,
                          height: 1.55,
                          letterSpacing: -0.1,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFF4A3728),
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],

                    // Spiritual Benefits Section
                    if (_dua.getBenefits(_currentLang).isNotEmpty) ...[
                      Text(
                        'SPIRITUAL & PRACTICAL BENEFITS',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark
                              ? const Color(0xFFE9D5FF)
                              : const Color(0xFF9333EA),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _dua.getBenefits(_currentLang),
                        style: TextStyle(
                          fontSize: 16.0,
                          height: 1.55,
                          letterSpacing: -0.1,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? const Color(0xFFF3E8FF)
                              : const Color(0xFF3B0764),
                        ),
                      ),
                      const SizedBox(height: 36),
                    ],
                  ],
                ),
              ),
            ),

            // Absolute Floating Audio Player at Left Bottom Corner
            if (_dua.audioUrl != null && _dua.audioUrl!.isNotEmpty)
              _buildFloatingAudioPlayer(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingAudioPlayer(bool isDark) {
    final hasAudio = _dua.audioUrl != null && _dua.audioUrl!.isNotEmpty;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 20,
      bottom: bottomInset + 18,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasAudio ? _toggleAudio : null,
          borderRadius: BorderRadius.circular(32),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? (_isPlaying
                          ? const [Color(0xFF143820), Color(0xFF0F0F12)]
                          : const [Color(0xFF142E18), Color(0xFF18181B)])
                    : (_isPlaying
                          ? const [Color(0xFF1F4A18), Color(0xFF13360E)]
                          : const [Color(0xFF2A531D), Color(0xFF1B3D14)]),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF27272A)
                    : Colors.white.withValues(alpha: _isPlaying ? 0.35 : 0.2),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular Play / Buffering / Stop Button
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _isBuffering
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isPlaying
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ),
                const SizedBox(width: 10),

                // Title & Subtitle Labels
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isPlaying
                          ? 'Reciting...'
                          : (_isBuffering ? 'Loading...' : 'Audio Recitation'),
                      style: GoogleFonts.lexend(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isPlaying ? 'Tap to pause' : 'Tap to listen',
                      style: GoogleFonts.lexend(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Sound Wave Bars
                _buildWaveBars(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaveBars() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final val = _waveController.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildBar((_isPlaying ? 6.0 + 12.0 * ((val + 0.1) % 1.0) : 6.0)),
            const SizedBox(width: 2.5),
            _buildBar((_isPlaying ? 8.0 + 14.0 * ((val + 0.4) % 1.0) : 10.0)),
            const SizedBox(width: 2.5),
            _buildBar((_isPlaying ? 5.0 + 16.0 * ((val + 0.7) % 1.0) : 14.0)),
            const SizedBox(width: 2.5),
            _buildBar((_isPlaying ? 7.0 + 10.0 * ((val + 0.2) % 1.0) : 8.0)),
          ],
        );
      },
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 3,
      height: height.clamp(4.0, 20.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: _isPlaying ? 0.95 : 0.45),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  void _loadPersistedLanguage() {
    try {
      final storage = ref.read(storageServiceProvider);
      final savedLangs = storage.getGenericData('dua_selected_languages');
      if (savedLangs is List && savedLangs.isNotEmpty) {
        final lang = savedLangs.first.toString();
        if (lang.isNotEmpty) {
          _currentLang = lang;
        }
      } else {
        final savedPrimary = storage.getGenericData('dua_primary_language');
        if (savedPrimary is String && savedPrimary.isNotEmpty) {
          _currentLang = savedPrimary;
        }
      }
    } catch (_) {}
  }

  Widget _buildLangChip(String langCode, String label, bool isDark) {
    final isSelected = _currentLang == langCode;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        setState(() {
          _currentLang = langCode;
        });
        try {
          final storage = ref.read(storageServiceProvider);
          await storage.saveGenericData('dua_selected_languages', [langCode]);
          await storage.saveGenericData('dua_primary_language', langCode);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('dua_primary_language', langCode);
        } catch (_) {}
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D))
              : (isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF18A74C) : const Color(0xFF2A531D))
                : (isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        (isDark
                                ? const Color(0xFF18A74C)
                                : const Color(0xFF2A531D))
                            .withValues(alpha: isDark ? 0.3 : 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
            color: isSelected
                ? (isDark ? const Color(0xFF0F0F12) : Colors.white)
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}
