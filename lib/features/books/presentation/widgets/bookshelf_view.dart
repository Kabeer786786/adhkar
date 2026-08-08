import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/book_model.dart';

class BookshelfView extends StatelessWidget {
  final List<BookModel> books;
  final Function(BookModel book) onBookTap;
  final Function(BookModel book) onBookLongPress;

  const BookshelfView({
    super.key,
    required this.books,
    required this.onBookTap,
    required this.onBookLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_bookmark_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Your Bookshelf is Empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A531D),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Tap "+ Add Books" in the top header to add books from the Islamic Library or upload your own custom books.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      );
    } 

    // Group books into rows of 3 per shelf
    final List<List<BookModel>> shelves = [];
    for (int i = 0; i < books.length; i += 3) {
      shelves.add(
        books.sublist(i, (i + 3 < books.length) ? i + 3 : books.length),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 0, bottom: 24),
      itemCount: shelves.length,
      itemBuilder: (context, shelfIndex) {
        final shelfBooks = shelves[shelfIndex];
        return _buildSingleShelf(context, shelfBooks);
      },
    );
  }

  Widget _buildSingleShelf(BuildContext context, List<BookModel> shelfBooks) {
    const double shelfBoxHeight = 82.0;
    const double rimThickness = 10.0;

    return Container(
      height: 155.0,
      margin: const EdgeInsets.only(top: 12, bottom: 0),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Half-Height 3D Shelf Box Container (82px high, aligned at bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: shelfBoxHeight,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE4EAF4), // Cavity backdrop wall
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Stack(
                  children: [
                    // INSIDE Left Physical 3D Side Wall Depth Panel Box
                    Positioned(
                      top: 0,
                      bottom: rimThickness,
                      left: 0,
                      width: 12,
                      child: Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(5),
                            bottomLeft: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    // INSIDE Right Physical 3D Side Wall Depth Panel Box
                    Positioned(
                      top: 0,
                      bottom: rimThickness,
                      right: 0,
                      width: 12,
                      child: Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(5),
                            bottomRight: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    // Left Soft Inner Cavity Shadow
                    Positioned(
                      top: 0,
                      bottom: rimThickness,
                      left: 12,
                      width: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Right Soft Inner Cavity Shadow
                    Positioned(
                      top: 0,
                      bottom: rimThickness,
                      right: 12,
                      width: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom Soft Inset Shadow above bottom ledge
                    Positioned(
                      bottom: 11,
                      left: 0,
                      right: 0,
                      height: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Seamless U-Shaped Front Rim (wrapped in IgnorePointer so it never blocks gestures)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: shelfBoxHeight,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _UShelfRimPainter(
                  sideHeight: shelfBoxHeight,
                  rimWidth: 10.0,
                  ledgeHeight: 10.0,
                  bottomRadius: 5.0,
                  topRadius: 1,
                ),
              ),
            ),
          ),

          // 3. Books Content resting on shelf ledge (bottom: 11px, height: 140px)
          // Standing 140px tall, 100% inside 155px container for 100% upper & lower clickability!
          Positioned(
            bottom: 11,
            left: 11,
            right: 11,
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(3, (index) {
                if (index < shelfBooks.length) {
                  final book = shelfBooks[index];
                  return _BookCardWidget(
                    book: book,
                    onTap: () => onBookTap(book),
                    onLongPress: () => onBookLongPress(book),
                  );
                }
                // Empty slot placeholder on shelf
                return const SizedBox(width: 95, height: 140);
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCardWidget extends StatefulWidget {
  final BookModel book;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BookCardWidget({
    required this.book,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_BookCardWidget> createState() => _BookCardWidgetState();
}

class _BookCardWidgetState extends State<_BookCardWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          width: 100,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(3),
              bottomRight: Radius.circular(3),
              topLeft: Radius.circular(2),
              bottomLeft: Radius.circular(2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isPressed ? 0.4 : 0.25),
                blurRadius: _isPressed ? 12 : 8,
                offset: const Offset(3, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(3),
              bottomRight: Radius.circular(3),
              topLeft: Radius.circular(2),
              bottomLeft: Radius.circular(2),
            ),
            child: Stack(
              children: [
              // Cover Image / Gradient
              Positioned.fill(child: buildBookCoverBackground(book)),

              // Realistic 3D Spine Crease (Left edge shadow)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 9,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // Glassy Subtle Gloss Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0.02),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Title & Author Text Overlay (Only displayed when NO custom cover image is selected)
              if (book.coverUrl.isEmpty)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            book.category.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          book.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          book.author,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

              // Reading Progress Indicator at base
              if (book.readProgress > 0)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 3,
                  child: Container(
                    color: Colors.black38,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: book.readProgress.clamp(0.0, 1.0),
                      child: Container(color: const Color(0xFFFACC15)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

  static Widget buildBookCoverBackground(BookModel book) {
    final url = book.coverUrl.trim();
    if (url.isNotEmpty) {
      if (url.startsWith('http')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => buildGradientCover(book),
        );
      } else {
        return Image.file(
          File(url),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => buildGradientCover(book),
        );
      }
    }
    return buildGradientCover(book);
  }

  static Widget buildGradientCover(BookModel book) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: book.coverGradient.length >= 2
              ? book.coverGradient
              : [const Color(0xFF1E3816), const Color(0xFF2A531D)],
        ),
      ),
    );
  }
}

class ThreeDBookCoverWidget extends StatelessWidget {
  final BookModel book;
  final double width;
  final double height;
  final double? fontSize;
  final bool showTitle;

  const ThreeDBookCoverWidget({
    super.key,
    required this.book,
    this.width = 100,
    this.height = 140,
    this.fontSize,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final computedFontSize = fontSize ?? (width * 0.11).clamp(8.0, 14.0);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(3),
          bottomRight: Radius.circular(3),
          topLeft: Radius.circular(2),
          bottomLeft: Radius.circular(2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(3),
          bottomRight: Radius.circular(3),
          topLeft: Radius.circular(2),
          bottomLeft: Radius.circular(2),
        ),
        child: Stack(
          children: [
            // 1. Cover Background
            Positioned.fill(child: _buildCoverBackground(book)),

            // 2. Realistic 3D Spine Crease
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: (width * 0.09).clamp(4.0, 10.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.38),
                      Colors.black.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Right Edge 3D Pages Stack Look
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Gold Foil Frame & Title (Only displayed when NO custom cover image is selected)
            if (showTitle && book.coverUrl.isEmpty)
              Positioned.fill( 
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    (width * 0.12).clamp(5.0, 12.0),
                    width * 0.06,
                    width * 0.06,
                    width * 0.06,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFACC15).withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            book.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: computedFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                              shadows: const [
                                Shadow(
                                  color: Colors.black87,
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverBackground(BookModel book) {
    final url = book.coverUrl.trim();
    if (url.isNotEmpty) {
      if (url.startsWith('http')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildGradientCover(book),
        );
      } else {
        return Image.file(
          File(url),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildGradientCover(book),
        );
      }
    }
    return _buildGradientCover(book);
  }

  Widget _buildGradientCover(BookModel book) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: book.coverGradient.length >= 2
              ? book.coverGradient
              : [const Color(0xFF1E3816), const Color(0xFF2A531D)],
        ),
      ),
    );
  }
}

class _UShelfRimPainter extends CustomPainter {
  final double sideHeight;
  final double rimWidth;
  final double ledgeHeight;
  final double bottomRadius;
  final double topRadius;

  _UShelfRimPainter({
    required this.sideHeight,
    required this.rimWidth,
    required this.ledgeHeight,
    this.bottomRadius = 5.0,
    this.topRadius = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = bottomRadius;
    final tr = topRadius;

    // 1. Unified 1-piece U-shaped Path with beautifully rounded top caps & bottom corners
    final uPath = Path()
      ..moveTo(0, h - sideHeight + tr)
      ..quadraticBezierTo(0, h - sideHeight, tr, h - sideHeight)
      ..lineTo(rimWidth - tr, h - sideHeight)
      ..quadraticBezierTo(
        rimWidth,
        h - sideHeight,
        rimWidth,
        h - sideHeight + tr,
      )
      ..lineTo(rimWidth, h - ledgeHeight)
      ..lineTo(w - rimWidth, h - ledgeHeight)
      ..lineTo(w - rimWidth, h - sideHeight + tr)
      ..quadraticBezierTo(
        w - rimWidth,
        h - sideHeight,
        w - rimWidth + tr,
        h - sideHeight,
      )
      ..lineTo(w - tr, h - sideHeight)
      ..quadraticBezierTo(w, h - sideHeight, w, h - sideHeight + tr)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..lineTo(r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..close();

    // 2. Continuous 3D gradient fill across the entire U-shape
    final rimPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF8FAFC), Color(0xFFCBD5E1), Color(0xFF94A3B8)],
      ).createShader(Rect.fromLTWH(0, h - sideHeight, w, sideHeight));

    canvas.drawPath(uPath, rimPaint);

    // 3. Top surface white sheen highlight lines on the rim top caps & side edges
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Top horizontal edge of left wing
    canvas.drawLine(
      Offset(tr, h - sideHeight),
      Offset(rimWidth - tr, h - sideHeight),
      highlightPaint,
    );

    // Top horizontal edge of right wing
    canvas.drawLine(
      Offset(w - rimWidth + tr, h - sideHeight),
      Offset(w - tr, h - sideHeight),
      highlightPaint,
    );

    // Left inner vertical side highlight line (facing cavity/books)
    canvas.drawLine(
      Offset(rimWidth, h - sideHeight + tr),
      Offset(rimWidth, h - ledgeHeight),
      highlightPaint,
    );

    // Right inner vertical side highlight line (facing cavity/books)
    canvas.drawLine(
      Offset(w - rimWidth, h - sideHeight + tr),
      Offset(w - rimWidth, h - ledgeHeight),
      highlightPaint,
    );

    // Inner surface edge of bottom ledge
    canvas.drawLine(
      Offset(rimWidth, h - ledgeHeight),
      Offset(w - rimWidth, h - ledgeHeight),
      highlightPaint,
    );

    // 4. Subtle crisp 3D edge stroke around the U-rim
    final borderPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(uPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
