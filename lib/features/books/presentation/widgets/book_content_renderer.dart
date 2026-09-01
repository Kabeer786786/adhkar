import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/book_content_block.dart';

class BookContentRenderer extends StatelessWidget {
  final BookContentBlock block;
  final double fontSize;
  final bool isDark;
  final Color textColor;
  final Color accentColor;
  final Color cardBgColor;

  const BookContentRenderer({
    super.key,
    required this.block,
    required this.fontSize,
    required this.isDark,
    required this.textColor,
    this.accentColor = const Color(0xFF2A531D),
    this.cardBgColor = const Color(0xFF18181B),
  });

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case BookBlockType.heading:
        return _buildHeading(fontSize * 1.35, FontWeight.w600);
      case BookBlockType.subheading:
        return _buildHeading(fontSize * 1.25, FontWeight.w600);
      case BookBlockType.title:
        return _buildHeading(fontSize * 1.15, FontWeight.w600);
      case BookBlockType.paragraph:
        return _buildParagraph();
      case BookBlockType.bulletPoints:
        return _buildBulletPoints();
      case BookBlockType.box:
        return _buildCalloutBox(context);
      case BookBlockType.verse:
        return _buildVerseCard(context);
      case BookBlockType.image:
        return _buildImage(context);
      case BookBlockType.audio:
        return BookInlineAudioCard(
          block: block,
          isDark: isDark,
          textColor: textColor,
          accentColor: accentColor,
        );
      case BookBlockType.video:
        return _buildVideoCard(context);
      case BookBlockType.divider:
        return _buildDivider();
    }
  }

  Widget _buildHeading(double size, FontWeight weight) {
    final isArabic = block.language == 'ar';
    final isUrdu = block.language == 'ur';

    TextStyle textStyle;
    if (isArabic) {
      textStyle = GoogleFonts.amiri(
        fontSize: size * 1.15,
        fontWeight: weight,
        color: textColor,
        height: 1.6,
      );
    } else if (isUrdu) {
      textStyle = GoogleFonts.notoNastaliqUrdu(
        fontSize: size * 1.1,
        fontWeight: weight,
        color: textColor,
        height: 1.8,
      );
    } else {
      textStyle = TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: textColor,
        height: 1.45,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Column(
        crossAxisAlignment: isArabic || isUrdu
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // if (!isArabic && !isUrdu)
              //   Container(
              //     width: 4,
              //     height: size * 1.5,
              //     margin: const EdgeInsets.only(right: 8),
              //     decoration: BoxDecoration(
              //       color: isDark ? const Color(0xFFA3E635) : accentColor,
              //       borderRadius: BorderRadius.circular(2),
              //     ),
              //   ),
              Flexible(
                child: Text(
                  block.text,
                  style: textStyle,
                  textAlign: isArabic || isUrdu ? TextAlign.right : TextAlign.left,
                  textDirection: isArabic || isUrdu
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                ),
              ),
              // if (isArabic || isUrdu)
              //   Container(
              //     width: 4,
              //     height: size * 0.9,
              //     margin: const EdgeInsets.only(left: 8),
              //     decoration: BoxDecoration(
              //       color: isDark ? const Color(0xFFA3E635) : accentColor,
              //       borderRadius: BorderRadius.circular(2),
              //     ),
              //   ),
            ],
          ),
          if (block.secondaryText != null && block.secondaryText!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              block.secondaryText!,
              style: TextStyle(
                fontSize: size * 0.75,
                color: textColor.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildParagraph() {
    final isArabic = block.language == 'ar';
    final isUrdu = block.language == 'ur';

    TextStyle style;
    if (isArabic) {
      style = GoogleFonts.amiri(
        fontSize: fontSize * 1.25,
        height: 1.8,
        color: textColor,
      );
    } else if (isUrdu) {
      style = GoogleFonts.notoNastaliqUrdu(
        fontSize: fontSize * 1.15,
        height: 2.0,
        color: textColor,
      );
    } else {
      style = GoogleFonts.lexend(
        fontSize: fontSize,
        height: 1.75,
        color: textColor,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        block.text,
        style: style,
        textAlign: isArabic || isUrdu ? TextAlign.right : TextAlign.justify,
        textDirection: isArabic || isUrdu ? TextDirection.rtl : TextDirection.ltr,
      ),
    );
  }

  Widget _buildBulletPoints() {
    final isArabic = block.language == 'ar';
    final isUrdu = block.language == 'ur';
    final lineLineHeight = fontSize * 1.65;
    const circleSize = 24.0;
    final circleTopMargin = ((lineLineHeight - circleSize) / 2).clamp(1.0, 8.0);
    final bulletTopMargin = ((lineLineHeight - 7.0) / 2).clamp(4.0, 12.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isArabic || isUrdu
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: List.generate(block.items.length, (index) {
          final rawItem = block.items[index];
          // Strip leading numbering from text (e.g. "1. ", "1) ", "(1) ", "1- ") if present
          final cleanItem = rawItem.replaceFirst(
            RegExp(r'^\s*(\d+[\.\-\)]|\(\d+\))\s*'),
            '',
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection:
                  isArabic || isUrdu ? TextDirection.rtl : TextDirection.ltr,
              children: [
                if (block.isOrdered)
                  Container(
                    width: circleSize,
                    height: circleSize,
                    margin: EdgeInsets.only(
                      right: isArabic || isUrdu ? 0 : 10,
                      left: isArabic || isUrdu ? 10 : 0,
                      top: circleTopMargin,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2822)
                          : const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFA3E635)
                            : const Color(0xFF2A531D),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFA3E635)
                              : const Color(0xFF2A531D),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    margin: EdgeInsets.only(
                      right: isArabic || isUrdu ? 0 : 10,
                      left: isArabic || isUrdu ? 10 : 0,
                      top: bulletTopMargin,
                    ),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFA3E635)
                          : const Color(0xFF2A531D),
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Text(
                    cleanItem,
                    style: (isArabic
                            ? GoogleFonts.amiri(
                                fontSize: fontSize * 1.15,
                                height: 1.7,
                              )
                            : (isUrdu
                                ? GoogleFonts.notoNastaliqUrdu(
                                    fontSize: fontSize * 1.05,
                                    height: 1.9,
                                  )
                                : TextStyle(
                                    fontSize: fontSize,
                                    height: 1.65,
                                  )))
                        .copyWith(color: textColor),
                    textAlign: isArabic || isUrdu
                        ? TextAlign.right
                        : TextAlign.justify,
                    textDirection: isArabic || isUrdu
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCalloutBox(BuildContext context) {
    Color boxAccent;
    IconData boxIcon;
    String defaultTitle;

    switch (block.boxType) {
      case BookBoxType.islamic:
        boxAccent = const Color(0xFF16A34A);
        boxIcon = FlutterIslamicIcons.solidLantern;
        defaultTitle = 'Spiritual Reflection';
        break;
      case BookBoxType.quote:
        boxAccent = const Color(0xFFD97724);
        boxIcon = Icons.format_quote_rounded;
        defaultTitle = 'Key Quote';
        break;
      case BookBoxType.info:
        boxAccent = const Color(0xFF0284C7);
        boxIcon = Icons.info_outline_rounded;
        defaultTitle = 'Important Note';
        break;
      case BookBoxType.warning:
        boxAccent = const Color(0xFFDC2626);
        boxIcon = Icons.warning_amber_rounded;
        defaultTitle = 'Caution';
        break;
      case BookBoxType.hadith:
        boxAccent = const Color(0xFF8B5CF6);
        boxIcon = FlutterIslamicIcons.quran2;
        defaultTitle = 'Hadith Extract';
        break;
      case BookBoxType.highlight:
        boxAccent = isDark ? const Color(0xFFA3E635) : accentColor;
        boxIcon = Icons.lightbulb_outline_rounded;
        defaultTitle = 'Key Takeaway';
        break;
    }

    final title = block.secondaryText?.isNotEmpty == true
        ? block.secondaryText!
        : defaultTitle;

    final isArabic = block.language == 'ar';
    final isUrdu = block.language == 'ur';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? boxAccent.withValues(alpha: 0.12)
            : boxAccent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: isArabic || isUrdu
              ? BorderSide.none
              : BorderSide(color: boxAccent, width: 4),
          right: isArabic || isUrdu
              ? BorderSide(color: boxAccent, width: 4)
              : BorderSide.none,
          top: BorderSide(color: boxAccent.withValues(alpha: 0.25), width: 1),
          bottom:
              BorderSide(color: boxAccent.withValues(alpha: 0.25), width: 1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: isArabic || isUrdu
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            textDirection:
                isArabic || isUrdu ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Icon(boxIcon, size: 18, color: boxAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize * 0.9,
                    fontWeight: FontWeight.bold,
                    color: boxAccent,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            block.text,
            style: (isArabic
                    ? GoogleFonts.amiri(
                        fontSize: fontSize * 1.15,
                        height: 1.8,
                      )
                    : (isUrdu
                        ? GoogleFonts.notoNastaliqUrdu(
                            fontSize: fontSize * 1.05,
                            height: 1.9,
                          )
                        : GoogleFonts.lexend(
                            fontSize: fontSize * 0.95,
                            height: 1.65,
                          )))
                .copyWith(
              color: textColor.withValues(alpha: 0.95),
            ),
            textAlign: isArabic || isUrdu ? TextAlign.right : TextAlign.justify,
            textDirection:
                isArabic || isUrdu ? TextDirection.rtl : TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  Widget _buildVerseCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white12
              : Colors.grey.shade300,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          // Header icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      FlutterIslamicIcons.solidQuran,
                      size: 14,
                      color: Color(0xFF16A34A),
                    ),
                    if (block.reference != null && block.reference!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        block.reference!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFA3E635)
                              : const Color(0xFF2A531D),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Arabic Verse Text
          Text(
            block.text,
            style: GoogleFonts.amiri(
              fontSize: fontSize * 1.5,
              fontWeight: FontWeight.bold,
              height: 2.0,
              color: isDark ? Colors.white : const Color(0xFF1A3512),
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),

          // Transliteration
          if (block.secondaryText != null && block.secondaryText!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              block.secondaryText!,
              style: TextStyle(
                fontSize: fontSize * 0.88,
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: textColor.withValues(alpha: 0.75),
              ),
              textAlign: TextAlign.center,
            ),
          ],

          // Translation
          if (block.tertiaryText != null && block.tertiaryText!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(
              color: isDark ? Colors.white12 : Colors.grey.shade300,
              height: 16,
            ),
            Text(
              '“${block.tertiaryText!}”',
              style: GoogleFonts.lexend(
                fontSize: fontSize * 0.95,
                height: 1.6,
                fontWeight: FontWeight.w500,
                color: textColor.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final imgUrl = block.url ?? '';
    if (imgUrl.isEmpty) return const SizedBox.shrink();

    final isLocal = !imgUrl.startsWith('http://') && !imgUrl.startsWith('https://');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => _openFullScreenImage(context, imgUrl, isLocal, block.caption),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [ 
                  AspectRatio(
                    aspectRatio: block.aspectRatio ?? 16 / 9,
                    child: isLocal
                        ? (imgUrl.startsWith('assets/')
                            ? Image.asset(imgUrl, fit: BoxFit.cover) 
                            : Image.file(File(imgUrl), fit: BoxFit.cover))
                        : CachedNetworkImage(
                            imageUrl: imgUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: isDark ? Colors.white10 : Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: isDark ? Colors.white10 : Colors.grey.shade200,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey),
                                  SizedBox(height: 6),
                                  Text('Image unavailable', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (block.caption != null && block.caption!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              block.caption!,
              style: TextStyle(
                fontSize: fontSize * 0.8,
                fontStyle: FontStyle.italic,
                color: textColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  void _openFullScreenImage(
    BuildContext context,
    String imgUrl,
    bool isLocal,
    String? caption,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (context) {
        return Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: isLocal
                    ? (imgUrl.startsWith('assets/')
                        ? Image.asset(imgUrl, fit: BoxFit.contain)
                        : Image.file(File(imgUrl), fit: BoxFit.contain))
                    : CachedNetworkImage(
                        imageUrl: imgUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                  ),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            if (caption != null && caption.isNotEmpty)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildVideoCard(BuildContext context) {
    final videoUrl = block.url ?? '';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (videoUrl.isNotEmpty) {
              final uri = Uri.parse(videoUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: block.thumbnailUrl?.isNotEmpty == true
                        ? CachedNetworkImage(
                            imageUrl: block.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFF334155),
                            ),
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2A531D),
                      border: Border.all(color: const Color(0xFFA3E635), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2A531D).withValues(alpha: 0.6),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  if (block.reference != null && block.reference!.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          block.reference!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.ondemand_video_rounded,
                      color: Color(0xFF16A34A),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        block.text.isNotEmpty ? block.text : 'Watch Video Lesson',
                        style: TextStyle(
                          fontSize: fontSize * 0.9,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 40, height: 1, color: textColor.withValues(alpha: 0.2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              FlutterIslamicIcons.quran2,
              size: 16,
              color: isDark ? const Color(0xFFA3E635) : accentColor,
            ),
          ),
          Container(width: 40, height: 1, color: textColor.withValues(alpha: 0.2)),
        ],
      ),
    );
  }
}

/// State-aware embedded inline audio player for books
class BookInlineAudioCard extends StatefulWidget {
  final BookContentBlock block;
  final bool isDark;
  final Color textColor;
  final Color accentColor;

  const BookInlineAudioCard({
    super.key,
    required this.block,
    required this.isDark,
    required this.textColor,
    required this.accentColor,
  });

  @override
  State<BookInlineAudioCard> createState() => _BookInlineAudioCardState();
}

class _BookInlineAudioCardState extends State<BookInlineAudioCard> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    final audioUrl = widget.block.url ?? '';
    if (audioUrl.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      _player ??= AudioPlayer();

      if (audioUrl.startsWith('http://') || audioUrl.startsWith('https://')) {
        await _player!.setUrl(audioUrl);
      } else if (audioUrl.startsWith('assets/')) {
        await _player!.setAsset(audioUrl);
      } else {
        await _player!.setFilePath(audioUrl);
      }

      _duration = _player!.duration ?? Duration.zero;

      _player!.positionStream.listen((pos) {
        if (mounted) {
          setState(() => _position = pos);
        }
      });

      _player!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            _isLoading = state.processingState == ProcessingState.loading ||
                state.processingState == ProcessingState.buffering;
          });
          if (state.processingState == ProcessingState.completed) {
            _player?.seek(Duration.zero);
            _player?.pause();
          }
        }
      });
    } catch (_) {
      // Handle audio init error gracefully
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _togglePlay() async {
    if (_player == null) {
      await _initPlayer();
    }
    if (_player == null) return;

    if (_isPlaying) {
      await _player!.pause();
    } else {
      await _player!.play();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final totalDurationStr = widget.block.reference?.isNotEmpty == true
        ? widget.block.reference!
        : (_duration.inSeconds > 0 ? _formatDuration(_duration) : 'Audio');

    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF18181B)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark
              ? Colors.white12
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: _isLoading ? null : _togglePlay,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and author
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.block.text.isNotEmpty
                          ? widget.block.text
                          : 'Audio Recitation / Commentary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.block.secondaryText != null)
                      Text(
                        widget.block.secondaryText!,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.textColor.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Duration badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isPlaying
                      ? '${_formatDuration(_position)} / $totalDurationStr'
                      : totalDurationStr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark
                        ? const Color(0xFFA3E635)
                        : widget.accentColor,
                  ),
                ),
              ),
            ],
          ),

          if (_isPlaying || _position.inSeconds > 0) ...[
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                activeTrackColor: widget.isDark
                    ? const Color(0xFFA3E635)
                    : widget.accentColor,
                inactiveTrackColor: widget.isDark
                    ? Colors.white12
                    : Colors.grey.shade300,
                thumbColor: widget.isDark
                    ? const Color(0xFFA3E635)
                    : widget.accentColor,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: progress,
                onChanged: (val) {
                  if (_duration.inMilliseconds > 0) {
                    final targetMs = (val * _duration.inMilliseconds).toInt();
                    _player?.seek(Duration(milliseconds: targetMs));
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
