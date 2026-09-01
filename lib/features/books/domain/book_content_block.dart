enum BookBlockType {
  heading,
  title,
  subheading,
  paragraph,
  bulletPoints,
  box,
  verse,
  image,
  audio,
  video,
  divider,
}

enum BookBoxType {
  highlight,
  islamic,
  quote,
  info,
  warning,
  hadith,
}

class BookContentBlock {
  final BookBlockType type;
  final String text;
  final String? secondaryText; // e.g. Transliteration or Subtitle
  final String? tertiaryText; // e.g. Translation or Author
  final String? reference; // e.g. "Sahih Bukhari 1" or "Surah 2:153"
  final String? url; // Media URL (Image, Audio, Video)
  final String? thumbnailUrl;
  final String? caption;
  final double? aspectRatio;
  final List<String> items; // For bullet / numbered points
  final bool isOrdered; // For numbered points
  final BookBoxType boxType;
  final String language; // 'en', 'ur', 'ar'
  final Map<String, dynamic>? metadata;

  const BookContentBlock({
    required this.type,
    this.text = '',
    this.secondaryText,
    this.tertiaryText,
    this.reference,
    this.url,
    this.thumbnailUrl,
    this.caption,
    this.aspectRatio,
    this.items = const [],
    this.isOrdered = false,
    this.boxType = BookBoxType.highlight,
    this.language = 'en',
    this.metadata,
  });

  factory BookContentBlock.heading(String text, {int level = 1, String language = 'en'}) {
    return BookContentBlock(
      type: level == 1 ? BookBlockType.heading : (level == 2 ? BookBlockType.subheading : BookBlockType.title),
      text: text,
      language: language,
    );
  }

  factory BookContentBlock.paragraph(String text, {String language = 'en'}) {
    return BookContentBlock(
      type: BookBlockType.paragraph,
      text: text,
      language: language,
    );
  }

  factory BookContentBlock.bulletPoints(List<String> items, {bool isOrdered = false, String language = 'en'}) {
    return BookContentBlock(
      type: BookBlockType.bulletPoints,
      items: items,
      isOrdered: isOrdered,
      language: language,
    );
  }

  factory BookContentBlock.box({
    required String text,
    String? title,
    BookBoxType boxType = BookBoxType.highlight,
    String language = 'en',
  }) {
    return BookContentBlock(
      type: BookBlockType.box,
      text: text,
      secondaryText: title,
      boxType: boxType,
      language: language,
    );
  }

  factory BookContentBlock.verse({
    required String arabicText,
    String? transliteration,
    String? translation,
    String? reference,
  }) {
    return BookContentBlock(
      type: BookBlockType.verse,
      text: arabicText,
      secondaryText: transliteration,
      tertiaryText: translation,
      reference: reference,
      language: 'ar',
    );
  }

  factory BookContentBlock.image({
    required String url,
    String? caption,
    double? aspectRatio,
  }) {
    return BookContentBlock(
      type: BookBlockType.image,
      url: url,
      caption: caption,
      aspectRatio: aspectRatio,
    );
  }

  factory BookContentBlock.audio({
    required String url,
    String? title,
    String? author,
    String? duration,
  }) {
    return BookContentBlock(
      type: BookBlockType.audio,
      url: url,
      text: title ?? 'Audio Track',
      secondaryText: author,
      reference: duration,
    );
  }

  factory BookContentBlock.video({
    required String url,
    String? title,
    String? thumbnailUrl,
    String? duration,
  }) {
    return BookContentBlock(
      type: BookBlockType.video,
      url: url,
      text: title ?? 'Video Lecture',
      thumbnailUrl: thumbnailUrl,
      reference: duration,
    );
  }

  factory BookContentBlock.divider() {
    return const BookContentBlock(type: BookBlockType.divider);
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'text': text,
      if (secondaryText != null) 'secondaryText': secondaryText,
      if (tertiaryText != null) 'tertiaryText': tertiaryText,
      if (reference != null) 'reference': reference,
      if (url != null) 'url': url,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (caption != null) 'caption': caption,
      if (aspectRatio != null) 'aspectRatio': aspectRatio,
      if (items.isNotEmpty) 'items': items,
      'isOrdered': isOrdered,
      'boxType': boxType.name,
      'language': language,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory BookContentBlock.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'paragraph';
    final type = BookBlockType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => BookBlockType.paragraph,
    );

    final boxTypeName = json['boxType'] as String? ?? 'highlight';
    final boxType = BookBoxType.values.firstWhere(
      (e) => e.name == boxTypeName,
      orElse: () => BookBoxType.highlight,
    );

    return BookContentBlock(
      type: type,
      text: json['text'] as String? ?? '',
      secondaryText: json['secondaryText'] as String?,
      tertiaryText: json['tertiaryText'] as String?,
      reference: json['reference'] as String?,
      url: json['url'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      caption: json['caption'] as String?,
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
      items: (json['items'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      isOrdered: json['isOrdered'] as bool? ?? false,
      boxType: boxType,
      language: json['language'] as String? ?? 'en',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Parses arbitrary raw text or markdown into rich structured blocks
  static List<BookContentBlock> parseLegacyContent(String rawContent) {
    if (rawContent.trim().isEmpty) return [];

    final List<BookContentBlock> blocks = [];
    final lines = rawContent.split('\n');

    List<String> currentBulletItems = [];
    bool currentOrdered = false;
    StringBuffer paragraphBuffer = StringBuffer();

    void flushParagraph() {
      final p = paragraphBuffer.toString().trim();
      if (p.isNotEmpty) {
        // Detect if predominantly Arabic
        final isArabic = _containsArabic(p);
        final isUrdu = _containsUrdu(p);
        if (isArabic && (p.contains('allah') || p.contains('الله') || p.length < 300)) {
          blocks.add(BookContentBlock.paragraph(p, language: 'ar'));
        } else if (isUrdu) {
          blocks.add(BookContentBlock.paragraph(p, language: 'ur'));
        } else {
          blocks.add(BookContentBlock.paragraph(p, language: 'en'));
        }
        paragraphBuffer.clear();
      }
    }

    void flushBullets() {
      if (currentBulletItems.isNotEmpty) {
        blocks.add(BookContentBlock.bulletPoints(
          List.from(currentBulletItems),
          isOrdered: currentOrdered,
        ));
        currentBulletItems.clear();
      }
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) {
        flushParagraph();
        flushBullets();
        continue;
      }

      // Check for markdown headers
      if (line.startsWith('# ')) {
        flushParagraph();
        flushBullets();
        blocks.add(BookContentBlock.heading(line.substring(2).trim(), level: 1));
      } else if (line.startsWith('## ')) {
        flushParagraph();
        flushBullets();
        blocks.add(BookContentBlock.heading(line.substring(3).trim(), level: 2));
      } else if (line.startsWith('### ')) {
        flushParagraph();
        flushBullets();
        blocks.add(BookContentBlock.heading(line.substring(4).trim(), level: 3));
      }
      // Check for bullet lists (- or * or •)
      else if (line.startsWith('- ') || line.startsWith('* ') || line.startsWith('• ')) {
        flushParagraph();
        currentOrdered = false;
        currentBulletItems.add(line.substring(2).trim());
      }
      // Check for numbered lists (1. 2. etc.)
      else if (RegExp(r'^\d+[\.\)]\s+').hasMatch(line)) {
        flushParagraph();
        currentOrdered = true;
        final cleanText = line.replaceFirst(RegExp(r'^\d+[\.\)]\s+'), '').trim();
        currentBulletItems.add(cleanText);
      }
      // Check for quotes / callout box (> text)
      else if (line.startsWith('> ')) {
        flushParagraph();
        flushBullets();
        blocks.add(BookContentBlock.box(
          text: line.substring(2).trim(),
          boxType: BookBoxType.quote,
        ));
      }
      // Check for divider (--- or ***)
      else if (line == '---' || line == '***') {
        flushParagraph();
        flushBullets();
        blocks.add(BookContentBlock.divider());
      }
      // Arabic verse with quotes / parentheses
      else if (_containsArabic(line) && line.length > 10) {
        flushParagraph();
        flushBullets();
        blocks.add(BookContentBlock.verse(
          arabicText: line,
        ));
      } else {
        if (currentBulletItems.isNotEmpty) {
          flushBullets();
        }
        if (paragraphBuffer.isNotEmpty) {
          paragraphBuffer.write(' ');
        }
        paragraphBuffer.write(line);
      }
    }

    flushParagraph();
    flushBullets();

    return blocks;
  }

  static bool _containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]').hasMatch(text);
  }

  static bool _containsUrdu(String text) {
    return RegExp(r'[\u0679\u0686\u0698\u06A9\u06AF\u06BA\u06BE\u06C1\u06D2]').hasMatch(text);
  }
}
