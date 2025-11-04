import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../models/note.dart';

class EditNoteScreen extends StatefulWidget {
  final String? noteId;
  const EditNoteScreen({super.key, this.noteId});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  Note? _original;

  @override
  void initState() {
    super.initState();
    final provider = context.read<NotesProvider>();
    if (widget.noteId != null) {
      _original = provider.notes.firstWhere((n) => n.id == widget.noteId);
      _titleCtrl.text = _original?.title ?? '';
      _bodyCtrl.text  = _original?.body ?? '';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text;
    final body = _bodyCtrl.text;

    final provider = context.read<NotesProvider>();
    if (_original == null) {
      provider.add(title, body);
    } else {
      provider.update(_original!.id, title, body);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _original != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit note' : 'New note'),
        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _bodyCtrl,
                keyboardType: TextInputType.multiline,
                minLines: 10,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Start writing…',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.check),
        label: const Text('Save'),
      ),
    );
  }
}
