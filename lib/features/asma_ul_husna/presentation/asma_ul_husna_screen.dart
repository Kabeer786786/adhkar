import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/asma_ul_husna_data.dart';
import '../data/asma_ul_husna_model.dart';
import '../services/asma_audio_service.dart';
import 'widgets/asma_detail_modal.dart';

class AsmaUlHusnaScreen extends StatefulWidget {
  const AsmaUlHusnaScreen({super.key});

  @override
  State<AsmaUlHusnaScreen> createState() => _AsmaUlHusnaScreenState();
}

class _AsmaUlHusnaScreenState extends State<AsmaUlHusnaScreen> {
  final AsmaAudioController _audioController = AsmaAudioController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _titleOpacity = ValueNotifier<double>(0.0);
  bool _isGridView = true; // True for boxes/grid, False for list view

  @override
  void initState() {
    super.initState();
    _audioController.addListener(_onAudioStateChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    // Title appears ONLY after the main header scrolls past beneath the AppBar (after 60px offset)
    final opacity = ((offset - 60) / 30.0).clamp(0.0, 1.0);
    if ((opacity - _titleOpacity.value).abs() > 0.01) {
      _titleOpacity.value = opacity;
    }
  }

  void _onAudioStateChanged() {
    if (!mounted) return;
    final activeIndex = _audioController.currentIndex;
    if (activeIndex >= 0) {
      _scrollToIndex(activeIndex);
    }
    setState(() {});
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;

    double targetOffset = 0;
    if (_isGridView) {
      final screenWidth = MediaQuery.of(context).size.width;
      final crossAxisCount = screenWidth > 600 ? 5 : 3;
      final rowIndex = index ~/ crossAxisCount;
      final itemWidth =
          (screenWidth - 32 - ((crossAxisCount - 1) * 10)) / crossAxisCount;
      final itemHeight = (itemWidth / 0.92) + 10;
      targetOffset = (rowIndex * itemHeight) + 110.0;
    } else {
      const itemHeight = 86.0;
      targetOffset = (index * itemHeight) + 110.0;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedOffset = targetOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      clampedOffset, 
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _audioController.removeListener(_onAudioStateChanged);
    _scrollController.removeListener(_onScroll);
    _audioController.dispose();
    _scrollController.dispose();
    _titleOpacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 5 : 3;
    final isPlayerActive = _audioController.currentIndex >= 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A3512)),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        // Smooth transition AppBar title: Bismillah when not scrolling, Asma Ul Husna when scrolling
        title: ValueListenableBuilder<double>(
          valueListenable: _titleOpacity,
          builder: (context, opacity, child) {
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                Opacity(
                  opacity: (1.0 - opacity).clamp(0.0, 1.0),
                  child: Text(
                    'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                    style: GoogleFonts.amiri(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2A531D),
                    ),
                  ),
                ),
                Opacity(
                  opacity: opacity,
                  child: const Text(
                    'Asma Ul Husna',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A531D),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          // Action 1: Play button for continuous recitation mode
          IconButton(
            icon: Icon(
              _audioController.isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              color: const Color(0xFF2A531D),
              size: 28,
            ),
            tooltip: _audioController.isPlaying
                ? 'Pause Recitation'
                : 'Play All Names',
            onPressed: () {
              if (isPlayerActive) {
                _audioController.togglePlayPause();
              } else {
                _audioController.playIndex(0);
              }
            },
          ),
          // Action 2: View mode toggle button (List / Boxes)
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: const Color(0xFF2A531D),
              size: 26,
            ),
            tooltip: _isGridView
                ? 'Switch to List View'
                : 'Switch to Grid View',
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
              final activeIndex = _audioController.currentIndex;
              if (activeIndex >= 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToIndex(activeIndex);
                });
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: Column(
        children: [
          // Main Scrollable Area with Header and Content
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header Banner Box
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: 4,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFDCFCE7),
                          const Color(0xFFFEF3C7).withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      // border: Border.all(
                      //   color: const Color(0xFF2A531D).withValues(alpha: 0.2),
                      // ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFF2A531D),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '99 Names of Allah',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(
                                  0xFF2A531D,
                                ).withValues(alpha: 0.8),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Asma Ul Husna',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2A531D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'And whoever knows them will go to Paradise.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B533E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Grid or List Slivers
                if (_isGridView)
                  SliverPadding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: isPlayerActive ? 150 : 32,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.92,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = asmaUlHusnaList[index];
                        final isSelected =
                            _audioController.currentIndex == index;
                        return _buildGridCard(item, index, isSelected);
                      }, childCount: asmaUlHusnaList.length),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 4,
                      bottom: isPlayerActive ? 150 : 32,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = asmaUlHusnaList[index];
                        final isSelected =
                            _audioController.currentIndex == index;
                        return _buildListCard(item, index, isSelected);
                      }, childCount: asmaUlHusnaList.length),
                    ),
                  ),
              ],
            ),
          ),

          // Sticky Bottom Audio Player Bar for Continuous Recitation
          if (isPlayerActive) _buildBottomAudioPlayerBar(),
        ],
      ),
    );
  }

  // Grid/Boxes Mode Card
  Widget _buildGridCard(AsmaUlHusna item, int index, bool isSelected) {
    return GestureDetector(
      onTap: () {
        AsmaDetailModal.show(
          context,
          item: item,
          onPlayContinuous: () => _audioController.playIndex(index),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFFDCFCE7),
                    Color(0xFFFEF3C7),
                    Color(0xFFE8F4E5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF16A34A) : Colors.transparent,
            width: isSelected ? 2.5 : 0.0,
          ),
          boxShadow: const [],
        ),
        child: Stack(
          children: [
            // Top Right Badge Number / Playing Indicator
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(
                      Icons.graphic_eq_rounded,
                      size: 14,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '${item.number}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? const Color(0xFF16A34A)
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            // Centered Arabic Name & Transliteration
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: isSelected ? 32 : 25,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? const Color(0xFF15803D)
                            : const Color(0xFF1A3512),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.transliteration,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF15803D)
                          : const Color(0xFF6B533E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // List Mode Card
  Widget _buildListCard(AsmaUlHusna item, int index, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          AsmaDetailModal.show(
            context,
            item: item,
            onPlayContinuous: () => _audioController.playIndex(index),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [
                      Color(0xFFDCFCE7),
                      Color(0xFFFEF3C7),
                      Color(0xFFE8F4E5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? const Color(0xFF16A34A) : Colors.transparent,
              width: isSelected ? 2.5 : 0.0,
            ),
            boxShadow: const [],
          ),
          child: Row(
            children: [
              // Number Badge + Playing indicator
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF16A34A) : Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: isSelected
                    ? const Icon(
                        Icons.graphic_eq_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : Text(
                        '${item.number}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A531D),
                        ),
                      ),
              ),
              const SizedBox(width: 14),

              // Transliteration & Meaning
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.transliteration,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? const Color(0xFF15803D)
                            : const Color(0xFF2A531D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.shortMeaning,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF15803D).withValues(alpha: 0.85)
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Arabic Name on right side
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.amiri(
                    fontSize: isSelected ? 32 : 26,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? const Color(0xFF15803D)
                        : const Color(0xFF1A3512),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Floating Bottom Player Bar (Music Player Style)
  Widget _buildBottomAudioPlayerBar() {
    final currentItem = _audioController.currentName;
    if (currentItem == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A1A), Color(0xFF0F230D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF4ADE80).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Left side Name & Transliteration + Right side Media Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 4, 4),
              child: Row(
                children: [
                  // Left side Artwork/Number Badge
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${currentItem.number}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Left side Text: Arabic Name & Transliteration
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentItem.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.amiri(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.6,
                          ),
                        ),
                        Text(
                          currentItem.transliteration,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFA7F3D0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Right side Media Controls Row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Backward 1 Name
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: const Icon(
                          Icons.skip_previous_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        tooltip: 'Previous Name',
                        onPressed: _audioController.playPrevious,
                      ),

                      // Play / Pause Toggle Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _audioController.togglePlayPause,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 42,
                            height: 42,
                            // decoration: const BoxDecoration(
                            //   color: Color(0xFF4ADE80),
                            // ),
                            child: Icon(
                              _audioController.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: const Color(0xFFFFFFFF),
                              size: 42,
                            ),
                          ),
                        ),
                      ),

                      // Forward 1 Name
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: const Icon(
                          Icons.skip_next_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        tooltip: 'Next Name',
                        onPressed: _audioController.playNext,
                      ),

                      // Stop / Close Player
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white54,
                          size: 18,
                        ),
                        tooltip: 'Close Player',
                        onPressed: _audioController.stop,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              // Bottom Progress Bar across all 99 names with track and head thumb
              child: StreamBuilder<Duration>(
                stream: _audioController.player.positionStream,
                builder: (context, snapshot) {
                  final pos = snapshot.data ?? Duration.zero;
                  final dur =
                      _audioController.player.duration ??
                      const Duration(seconds: 3);
                  final itemProgress = dur.inMilliseconds > 0
                      ? (pos.inMilliseconds / dur.inMilliseconds).clamp(
                          0.0,
                          1.0,
                        )
                      : 0.0;
                  final currentIndex = _audioController.currentIndex.clamp(
                    0,
                    98,
                  );
                  final totalItems = asmaUlHusnaList.length; // 99 items
                  final overallProgress =
                      ((currentIndex + itemProgress) / totalItems).clamp(
                        0.0,
                        1.0,
                      );

                  return SizedBox(
                    height: 20,
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 6,
                        activeTrackColor: const Color(0xFF4ADE80),
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                        thumbColor: const Color(0xFF4ADE80),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8.0,
                          elevation: 3,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 10,
                        ),
                      ),
                      child: Slider(
                        value: overallProgress,
                        onChanged: (val) {
                          final targetIndex = (val * totalItems).floor().clamp(
                            0,
                            totalItems - 1,
                          );
                          if (targetIndex != _audioController.currentIndex) {
                            _audioController.playIndex(targetIndex);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
