import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF006B5E);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todo (Local State)',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: seed, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: seed, brightness: Brightness.dark),
      home: const TodoHomePage(),
    );
  }
}

enum Filter { all, active, done }

class Task {
  final String id;
  String title;
  bool done;
  final DateTime createdAt;

  Task({required this.id, required this.title, this.done = false, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'done': done,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    done: json['done'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  static const _storeKey = 'todos_v1';
  final List<Task> _tasks = [];
  Filter _filter = Filter.all;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    if (raw != null && raw.isNotEmpty) {
      final List data = jsonDecode(raw) as List;
      _tasks
        ..clear()
        ..addAll(data.map((e) => Task.fromJson(Map<String, dynamic>.from(e))));
    }
    setState(() => _loaded = true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKey, jsonEncode(_tasks.map((t) => t.toJson()).toList()));
  }

  void _addTask(String title) {
    if (title.trim().isEmpty) return;
    setState(() {
      _tasks.insert(0, Task(id: UniqueKey().toString(), title: title.trim()));
    });
    _save();
  }

  void _toggle(Task t) {
    setState(() => t.done = !t.done);
    _save();
  }

  void _delete(Task t) {
    setState(() => _tasks.removeWhere((x) => x.id == t.id));
    _save();
  }

  void _edit(Task t, String newTitle) {
    if (newTitle.trim().isEmpty) return;
    setState(() => t.title = newTitle.trim());
    _save();
  }

  void _clearDone() {
    setState(() => _tasks.removeWhere((t) => t.done));
    _save();
  }

  List<Task> get _visibleTasks {
    switch (_filter) {
      case Filter.active:
        return _tasks.where((t) => !t.done).toList();
      case Filter.done:
        return _tasks.where((t) => t.done).toList();
      case Filter.all:
      default:
        return _tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final remaining = _tasks.where((t) => !t.done).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo – Local State'),
        actions: [
          Tooltip(
            message: 'Clear completed',
            child: IconButton(
              onPressed: _tasks.any((t) => t.done) ? _clearDone : null,
              icon: const Icon(Icons.cleaning_services_outlined),
            ),
          ),
          PopupMenuButton<Filter>(
            tooltip: 'Filter',
            onSelected: (f) => setState(() => _filter = f),
            itemBuilder: (context) => const [
              PopupMenuItem(value: Filter.all, child: Text('All')),
              PopupMenuItem(value: Filter.active, child: Text('Active')),
              PopupMenuItem(value: Filter.done, child: Text('Done')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _HeaderSummary(remaining: remaining, total: _tasks.length, filter: _filter),
          const Divider(height: 1),
          Expanded(
            child: _visibleTasks.isEmpty
                ? const _EmptyState()
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88, top: 8),
              itemCount: _visibleTasks.length,
              itemBuilder: (context, index) {
                final task = _visibleTasks[index];
                return Dismissible(
                  key: ValueKey(task.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _delete(task),
                  child: CheckboxListTile(
                    value: task.done,
                    onChanged: (_) => _toggle(task),
                    title: Text(
                      task.title,
                      style: task.done ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
                    ),
                    subtitle: Text(
                      'Created: ${_fmt(task.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    secondary: IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditSheet(task),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Icons.add_task),
        label: const Text('Add Task'),
      ),
    );
  }

  void _showAddSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New Task', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (v) {
                Navigator.pop(context);
                _addTask(v);
              },
              decoration: const InputDecoration(
                hintText: 'What needs to be done?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _addTask(controller.text);
              },
              icon: const Icon(Icons.check),
              label: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(Task task) {
    final controller = TextEditingController(text: task.title);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit Task', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (v) {
                Navigator.pop(context);
                _edit(task, v);
              },
              decoration: const InputDecoration(
                hintText: 'Update title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _edit(task, controller.text);
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSummary extends StatelessWidget {
  final int remaining;
  final int total;
  final Filter filter;
  const _HeaderSummary({required this.remaining, required this.total, required this.filter});

  String get _filterLabel => switch (filter) {
    Filter.all => 'All',
    Filter.active => 'Active',
    Filter.done => 'Done'
  };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.checklist_rounded),
      title: Text('$_filterLabel • $remaining of $total remaining'),
      subtitle: const Text('Swipe to delete • Tap edit to rename • Tap checkbox to complete'),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 64),
            const SizedBox(height: 12),
            Text('No tasks', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Add your first task with the button below.'),
          ],
        ),
      ),
    );
  }
}

String _fmt(DateTime dt) {
  final d = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}
