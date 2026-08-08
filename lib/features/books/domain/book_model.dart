import 'package:flutter/material.dart';

class BookChapter {
  final String title;
  final String content;

  const BookChapter({
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
      };

  factory BookChapter.fromJson(Map<String, dynamic> json) => BookChapter(
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
      );
}

class BookModel {
  final String id;
  final String title;
  final String author;
  final String description;
  final String category;
  final String coverUrl;
  final List<Color> coverGradient;
  final String? fileUrl; // Local path, web URL, or Drive/Adobe link
  final bool isCustom;
  final bool isAdded;
  final double readProgress;
  final int totalPages;
  final int currentPage;
  final List<BookChapter> chapters;

  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.category,
    required this.coverUrl,
    required this.coverGradient,
    this.fileUrl,
    this.isCustom = false,
    this.isAdded = true,
    this.readProgress = 0.0,
    this.totalPages = 100,
    this.currentPage = 1,
    this.chapters = const [],
  });

  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? category,
    String? coverUrl,
    List<Color>? coverGradient,
    String? fileUrl,
    bool? isCustom,
    bool? isAdded,
    double? readProgress,
    int? totalPages,
    int? currentPage,
    List<BookChapter>? chapters,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      category: category ?? this.category,
      coverUrl: coverUrl ?? this.coverUrl,
      coverGradient: coverGradient ?? this.coverGradient,
      fileUrl: fileUrl ?? this.fileUrl,
      isCustom: isCustom ?? this.isCustom,
      isAdded: isAdded ?? this.isAdded,
      readProgress: readProgress ?? this.readProgress,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      chapters: chapters ?? this.chapters,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'description': description,
        'category': category,
        'coverUrl': coverUrl,
        'coverGradientColors':
            coverGradient.map((c) => c.toARGB32()).toList(),
        'fileUrl': fileUrl,
        'isCustom': isCustom,
        'isAdded': isAdded,
        'readProgress': readProgress,
        'totalPages': totalPages,
        'currentPage': currentPage,
        'chapters': chapters.map((c) => c.toJson()).toList(),
      };

  factory BookModel.fromJson(Map<String, dynamic> json) {
    List<Color> gradient = [const Color(0xFF1E3816), const Color(0xFF2A531D)];
    if (json['coverGradientColors'] != null) {
      final list = json['coverGradientColors'] as List;
      gradient = list.map((val) => Color(val as int)).toList();
    }
    return BookModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Book',
      author: json['author'] as String? ?? 'Unknown Author',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      coverUrl: json['coverUrl'] as String? ?? '',
      coverGradient: gradient,
      fileUrl: json['fileUrl'] as String?,
      isCustom: json['isCustom'] as bool? ?? false,
      isAdded: json['isAdded'] as bool? ?? true,
      readProgress: (json['readProgress'] as num?)?.toDouble() ?? 0.0,
      totalPages: json['totalPages'] as int? ?? 100,
      currentPage: json['currentPage'] as int? ?? 1,
      chapters: (json['chapters'] as List?)
              ?.map((c) => BookChapter.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
