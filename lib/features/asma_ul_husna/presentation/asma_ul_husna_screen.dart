import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/media_download_provider.dart';
import '../../../core/services/media_download_service.dart';
import '../../../shared/widgets/floating_download_bar.dart';
import '../data/asma_ul_husna_data.dart';
import '../data/asma_ul_husna_model.dart';
import '../services/asma_audio_service.dart';
import 'widgets/asma_detail_modal.dart';
import 'widgets/asma_download_dialog.dart';

class AsmaUlHusnaScreen extends ConsumerStatefulWidget {
  const AsmaUlHusnaScreen({super.key});

  @override
  ConsumerState<AsmaUlHusnaScreen> createState() => _AsmaUlHusnaScreenState();
}

class _AsmaUlHusnaScreenState extends ConsumerState<AsmaUlHusnaScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _titleOpacity = ValueNotifier<double>(0.0);
  bool _isGridView = true; // True for boxes/grid, False for list view
  bool _isAllDownloaded = false; 
  bool _hasCheckedDownloadStatus = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AsmaDownloadDialog.showIfFirstTime(context, ref);
        _checkDownloadStatus();
      }
    });
  }

  Future<void> _checkDownloadStatus() async {
    final paths = asmaUlHusnaList.map((e) => e.localRelativePath).toList();
    final downloaded = await MediaDownloadService.instance.isBatchDownloaded(paths);
    if (mounted) {
      setState(() {
        _isAllDownloaded = downloaded;
        _hasCheckedDownloadStatus = true;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final opacity = ((offset - 60) / 30.0).clamp(0.0, 1.0);
    if ((opacity - _titleOpacity.value).abs() > 0.01) {
      _titleOpacity.value = opacity;
    }
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _titleOpacity.dispose();
    super.dispose();
  }

  AsmaAudioController get _audioController => ref.read(asmaAudioProvider);

  @override
  Widget build(BuildContext context) {
    final audioController = ref.watch(asmaAudioProvider);

    ref.listen(asmaAudioProvider, (prev, next) {
      if (next.currentIndex >= 0 && next.currentIndex != prev?.currentIndex) {
        _scrollToIndex(next.currentIndex);
      }
    });

    ref.listen(mediaDownloadProvider, (prev, next) {
      if (next.isCompleted) {
        _checkDownloadStatus();
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 5 : 3;
    final isPlayerActive = audioController.currentIndex >= 0;

    return Stack(
      children: [
        Scaffold(
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
                      child: Text(
                        'Asma Ul Husna',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A3512),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            actions: [
              if (_hasCheckedDownloadStatus && !_isAllDownloaded)
                IconButton(
                  icon: const Icon(
                    Icons.download_for_offline_rounded,
                    color: Color(0xFF1A3512),
                    size: 22,
                  ),
                  onPressed: () => AsmaDownloadDialog.show(context, ref),
                  tooltip: 'Download 99 Names Audio',
                ),
              IconButton(
                icon: Icon(
                  _isGridView
                      ? Icons.view_headline_rounded
                      : Icons.grid_view_rounded,
                  color: const Color(0xFF1A3512),
                  size: 22,
                ),
                onPressed: () => setState(() => _isGridView = !_isGridView),
                tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: _buildHeaderCard(), 
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: _isGridView
                          ? SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.92,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = asmaUlHusnaList[index];
                                  final isSelected =
                                      _audioController.currentIndex == index;
                                  return _buildGridCard(item, index, isSelected);
                                },
                                childCount: asmaUlHusnaList.length,
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = asmaUlHusnaList[index];
                                  final isSelected =
                                      _audioController.currentIndex == index;
                                  return _buildListCard(item, index, isSelected);
                                },
                                childCount: asmaUlHusnaList.length,
                              ),
                            ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: isPlayerActive ? 120 : 40,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomSheet: isPlayerActive ? _buildBottomAudioPlayerBar() : null,
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: FloatingDownloadBar(),
        ),
      ],
    );
  }

  Widget _buildHeaderCard() {
    final isPlayingAny = _audioController.isPlaying;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      ),
      child: Stack(
        children: [
          Column(
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
                      color: const Color(0xFF2A531D).withValues(alpha: 0.8),
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
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A3512),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 44),
                child: Text(
                  'Discover and memorize the 99 Beautiful Names of Almighty Allah.',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF1A3512).withValues(alpha: 0.8),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (_audioController.currentIndex >= 0) {
                    _audioController.togglePlayPause(context: context, ref: ref);
                  } else {
                    _audioController.playIndex(0, context: context, ref: ref);
                  }
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3512),
                    shape: BoxShape.circle,
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: const Color(0xFF1A3512).withValues(alpha: 0.3),
                    //     blurRadius: 8,
                    //     offset: const Offset(0, 3),
                    //   ),
                    // ],
                  ),
                  child: Icon(
                    isPlayingAny ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: const Color(0xFFD4AF37),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(AsmaUlHusna item, int index, bool isSelected) {
    return GestureDetector(
      onTap: () {
        AsmaDetailModal.show(
          context,
          item: item,
          onPlayContinuous: () =>
              _audioController.playIndex(index, context: context, ref: ref),
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
        ),
        child: Stack(
          children: [
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
                        fontSize: isSelected ? 32 : 26,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? const Color(0xFF15803D)
                            : const Color(0xFF1A3512),
                        height: 1.6,
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
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
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

  Widget _buildListCard(AsmaUlHusna item, int index, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          AsmaDetailModal.show(
            context,
            item: item,
            onPlayContinuous: () =>
                _audioController.playIndex(index, context: context, ref: ref),
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
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF2A531D).withValues(alpha: 0.1),
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
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A3512),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 1),
                    Text(
                      item.shortMeaning,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 4, 4),
              child: Row(
                children: [
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
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentItem.transliteration,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentItem.shortMeaning,
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currentItem.name,
                    style: GoogleFonts.amiri(
                      color: const Color(0xFF4ADE80),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    onPressed: _audioController.stop,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ], 
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 5,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: const Color(0xFF4ADE80),
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: (currentItem.number).toDouble().clamp(1.0, 99.0),
                        min: 1.0,
                        max: 99.0,
                        divisions: 98,
                        onChanged: (val) {
                          final targetIndex = val.toInt() - 1;
                          if (targetIndex != _audioController.currentIndex) {
                            _audioController.playIndex(targetIndex,
                                context: context, ref: ref);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded,
                        color: Colors.white, size: 28),
                    onPressed: () =>
                        _audioController.playPrevious(context: context, ref: ref),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          _audioController.togglePlayPause(context: context, ref: ref),
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          _audioController.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: const Color(0xFF4ADE80),
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded,
                        color: Colors.white, size: 28),
                    onPressed: () =>
                        _audioController.playNext(context: context, ref: ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
