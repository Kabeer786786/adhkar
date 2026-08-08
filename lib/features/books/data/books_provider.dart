import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/book_model.dart';
import 'books_repository.dart';

class UserBooksNotifier extends StateNotifier<AsyncValue<List<BookModel>>> {
  UserBooksNotifier() : super(const AsyncValue.loading()) {
    loadBooks();
  }

  Future<void> loadBooks() async {
    try {
      final books = await BooksRepository.getUserBooks();
      state = AsyncValue.data(books);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBook(BookModel book) async {
    try {
      final updated = await BooksRepository.addBook(book);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeBook(String bookId) async {
    try {
      final updated = await BooksRepository.removeBook(bookId);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProgress({
    required String bookId,
    required double progress,
    required int currentPage,
  }) async {
    try {
      final updated = await BooksRepository.updateProgress(
        bookId: bookId,
        progress: progress,
        currentPage: currentPage,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final userBooksProvider =
    StateNotifierProvider<UserBooksNotifier, AsyncValue<List<BookModel>>>(
        (ref) {
  return UserBooksNotifier();
});

final bookSearchQueryProvider = StateProvider<String>((ref) => '');
final selectedBookCategoryProvider = StateProvider<String>((ref) => 'All');
final bookSortOptionProvider = StateProvider<String>((ref) => 'Default');
