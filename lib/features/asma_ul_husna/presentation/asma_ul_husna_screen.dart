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
    final activeIndex = _audioController.currentIndex;
    if (activeIndex >= 0) {
      _scrollToIndex(activeIndex);
    }
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;

    // Estimate target offset for smooth scrolling to middle of screen
    double targetOffset = 0;
    if (_isGridView) {
      final screenWidth = MediaQuery.of(context).size.width;
      final crossAxisCount = screenWidth > 600 ? 5 : 3;
      final rowIndex = index ~/ crossAxisCount;
      final itemHeight = (screenWidth / crossAxisCount);
      targetOffset = (rowIndex * itemHeight);
    } else {
      const itemHeight = 100.0;
      targetOffset = (index * itemHeight);
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedOffset = targetOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 600),
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
        // Smooth transition AppBar title beside back arrow (Requirement 1 & 2)
        title: ValueListenableBuilder<double>(
          valueListenable: _titleOpacity,
          builder: (context, opacity, child) {
            return Opacity(
              opacity: opacity,
              child: const Text(
                'Asma Ul Husna',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A531D),
                ),
              ),
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
                // Header section that scrolls beneath the AppBar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 4,
                      bottom: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Asma Ul Husna',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2A531D),
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
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 32,
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
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 4,
                      bottom: 32,
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
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const RadialGradient(
                  center: Alignment(0.1, -0.2),
                  radius: 1.1,
                  colors: [
                    Color(0xFFDCFCE7),
                    Color(0xFFFEF3C7),
                    Color(0xFFF3E8FF),
                    Color(0xFFE8F4E5),
                  ],
                  stops: [0.0, 0.45, 0.75, 1.0],
                )
              : null,
          color: isSelected ? null : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2A531D) : Colors.transparent,
            width: isSelected ? 2 : 0.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Stack(
          children: [
            // Top Right Badge Number
            Positioned(
              top: 0,
              right: 0,
              child: Text(
                '${item.number}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? const Color(0xFF2A531D)
                      : Colors.grey.shade500,
                ),
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
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A3512),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
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
                          ? const Color(0xFF2A531D)
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
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [
                      Color(0xFFDCFCE7),
                      Color(0xFFFEF3C7),
                      Color(0xFFF3E8FF),
                      Color(0xFFE8F4E5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF2A531D) : Colors.transparent,
              width: isSelected ? 2 : 0.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            children: [
              // Number Badge + Volume icon column
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2A531D)
                          : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.number}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF2A531D),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Transliteration & Meaning
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.transliteration,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2A531D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.shortMeaning,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Arabic Name on right side
              Text(
                item.name,
                textAlign: TextAlign.right,
                style: GoogleFonts.amiri(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A3512),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sticky Bottom Player Bar
  Widget _buildBottomAudioPlayerBar() {
    final currentItem = _audioController.currentName;
    if (currentItem == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3512),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress Bar / Step indicator
            StreamBuilder<Duration>(
              stream: _audioController.player.positionStream,
              builder: (context, snapshot) {
                final pos = snapshot.data ?? Duration.zero;
                final dur =
                    _audioController.player.duration ??
                    const Duration(seconds: 3);
                final progress = dur.inMilliseconds > 0
                    ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                    : 0.0;

                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF86EFAC),
                        ),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                );
              },
            ),

            // Active Name Info & Media Controls
            Row(
              children: [
                // Active Name Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF86EFAC),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${currentItem.number}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A3512),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              currentItem.transliteration,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 0),
                      Text(
                        currentItem.meaning,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 0),

                // Audio Speed Control Toggle Button
                PopupMenuButton<double>(
                  initialValue: _audioController.speed,
                  tooltip: 'Playback Speed',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_audioController.speed}x',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  onSelected: (speed) => _audioController.setSpeed(speed),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 0.75, child: Text('0.75x Slow')),
                    const PopupMenuItem(value: 1.0, child: Text('1.0x Normal')),
                    const PopupMenuItem(value: 1.25, child: Text('1.25x Fast')),
                    const PopupMenuItem(value: 1.5, child: Text('1.5x Rapid')),
                  ],
                ),

                // Compact Player Controls (Prev, Play/Pause, Next, Stop)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: const Icon(
                        Icons.skip_previous_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: _audioController.playPrevious,
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      icon: Icon(
                        _audioController.isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        color: const Color(0xFF86EFAC),
                        size: 34,
                      ),
                      onPressed: _audioController.togglePlayPause,
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: _audioController.playNext,
                    ),
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
                      onPressed: _audioController.stop,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
