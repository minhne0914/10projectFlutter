import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../widgets/note_tile.dart';
import 'edit_note_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openNew() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditNoteScreen()),
    );
  }

  void _openEdit(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditNoteScreen(noteId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final items = _query.isEmpty
        ? notesProvider.notes
        : notesProvider.search(_query);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes (Provider)'),
        actions: [
          IconButton(
            tooltip: 'Clear search',
            onPressed: () {
              _searchCtrl.clear();
              setState(() => _query = '');
            },
            icon: const Icon(Icons.clear_all),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search notes…',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  tooltip: 'Search',
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() => _query = _searchCtrl.text),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? const _EmptyState()
                : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = items[index];
                return NoteTile(
                  note: n,
                  onTap: () => _openEdit(n.id),
                  onDelete: () => notesProvider.remove(n.id),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNew,
        icon: const Icon(Icons.note_add),
        label: const Text('New'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.note_alt_outlined, size: 64),
            const SizedBox(height: 12),
            Text('No notes yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Tap the + button to create your first note.'),
          ],
        ),
      ),
    );
  }
}
