import 'package:flutter/material.dart';

import '../data/subject_repository.dart';
import '../models/subject.dart';
import '../widgets/subject_tile.dart';
import 'subject_detail_screen.dart';

/// Placeholder-but-functional home screen: lists all Subjects and supports
/// create / rename / delete. Tapping a subject opens its entries.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = SubjectRepository();
  late Future<List<Subject>> _subjectsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _subjectsFuture = _repo.getAll();
    });
  }

  Future<void> _createSubject() async {
    final name = await _promptForName(context, title: 'New Subject');
    if (name == null || name.trim().isEmpty) return;
    await _repo.create(name.trim());
    _refresh();
  }

  Future<void> _renameSubject(Subject subject) async {
    final name = await _promptForName(
      context,
      title: 'Rename Subject',
      initialValue: subject.name,
    );
    if (name == null || name.trim().isEmpty) return;
    await _repo.rename(subject, name.trim());
    _refresh();
  }

  Future<void> _deleteSubject(Subject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete subject?'),
        content: Text(
          'This deletes "${subject.name}" and all of its entries. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && subject.id != null) {
      await _repo.delete(subject.id!);
      _refresh();
    }
  }

  Future<String?> _promptForName(
    BuildContext context, {
    required String title,
    String initialValue = '',
  }) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Subject name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subjects')),
      body: FutureBuilder<List<Subject>>(
        future: _subjectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final subjects = snapshot.data ?? [];
          if (subjects.isEmpty) {
            return const Center(
              child: Text('No subjects yet. Tap + to add one.'),
            );
          }
          return ListView.separated(
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return SubjectTile(
                subject: subject,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubjectDetailScreen(subject: subject),
                    ),
                  );
                  _refresh();
                },
                onEdit: () => _renameSubject(subject),
                onDelete: () => _deleteSubject(subject),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createSubject,
        child: const Icon(Icons.add),
      ),
    );
  }
}
