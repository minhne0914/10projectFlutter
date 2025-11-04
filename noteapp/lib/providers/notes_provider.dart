import 'package:flutter/foundation.dart';
import '../models/note.dart';

class NotesProvider extends ChangeNotifier {
  final List<Note> _notes = [];

  List<Note> get notes {
    final sorted = [..._notes]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  Note? byId(String id) => _notes.firstWhere((n) => n.id == id, orElse: () => null as Note);

  void add(String title, String body) {
    final note = Note(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? 'Untitled' : title.trim(),
      body: body.trim(),
    );
    _notes.insert(0, note);
    notifyListeners();
  }

  void update(String id, String title, String body) {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _notes[idx]
      ..title = title.trim().isEmpty ? 'Untitled' : title.trim()
      ..body = body.trim()
      ..updatedAt = DateTime.now();
    notifyListeners();
  }

  void remove(String id) {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  List<Note> search(String keyword) {
    final q = keyword.trim().toLowerCase();
    if (q.isEmpty) return notes;
    return notes.where((n) =>
    n.title.toLowerCase().contains(q) || n.body.toLowerCase().contains(q)
    ).toList();
  }
}
