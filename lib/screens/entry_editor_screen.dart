import 'dart:io';

import 'package:flutter/material.dart';

import '../data/entry_repository.dart';
import '../models/entry.dart';
import '../services/gemini_transcription_service.dart';
import '../services/image_storage_service.dart';
import '../widgets/latex_content_view.dart';

/// Create a new [Entry] or edit an existing one. Content can be typed
/// directly or produced by transcribing a photo via Gemini; either way the
/// user can review/edit the LaTeX-preserving text before saving.
class EntryEditorScreen extends StatefulWidget {
  const EntryEditorScreen({
    super.key,
    required this.subjectId,
    this.existingEntry,
  });

  final int subjectId;
  final Entry? existingEntry;

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  final _repo = EntryRepository();
  final _imageService = ImageStorageService();
  final _transcriptionService = GeminiTranscriptionService();

  late final TextEditingController _contentController;
  String? _sourceImagePath;
  bool _showPreview = false;
  bool _isTranscribing = false;
  String? _error;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    _contentController =
        TextEditingController(text: widget.existingEntry?.content ?? '');
    _sourceImagePath = widget.existingEntry?.sourceImagePath;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _transcribeFrom(Future<File?> Function() pick) async {
    setState(() {
      _error = null;
      _isTranscribing = true;
    });
    try {
      final file = await pick();
      if (file == null) {
        setState(() => _isTranscribing = false);
        return;
      }
      final text = await _transcriptionService.transcribeImage(file);
      setState(() {
        _sourceImagePath = file.path;
        if (_contentController.text.trim().isEmpty) {
          _contentController.text = text;
        } else {
          _contentController.text = '${_contentController.text}\n\n$text';
        }
      });
    } on TranscriptionException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong: $e');
    } finally {
      setState(() => _isTranscribing = false);
    }
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    if (_isEditing) {
      await _repo.update(widget.existingEntry!, newContent: content);
      // Keep source image in sync if a new photo was transcribed in.
      if (_sourceImagePath != widget.existingEntry!.sourceImagePath) {
        // Minimal path: re-create via update through the entry object.
        final updated = widget.existingEntry!.copyWith(
          content: content,
          sourceImagePath: _sourceImagePath,
        );
        await _repo.update(updated, newContent: content);
      }
    } else {
      await _repo.create(
        subjectId: widget.subjectId,
        content: content,
        sourceImagePath: _sourceImagePath,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Entry' : 'New Entry'),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.edit_outlined : Icons.visibility_outlined),
            tooltip: _showPreview ? 'Edit' : 'Preview',
            onPressed: () => setState(() => _showPreview = !_showPreview),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _save,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isTranscribing) const LinearProgressIndicator(),
          if (_error != null)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(12),
              child: Text(_error!),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _isTranscribing
                      ? null
                      : () => _transcribeFrom(_imageService.pickFromCamera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Camera'),
                ),
                OutlinedButton.icon(
                  onPressed: _isTranscribing
                      ? null
                      : () => _transcribeFrom(_imageService.pickFromGallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _showPreview
                  ? SingleChildScrollView(
                      child: LatexContentView(content: _contentController.text),
                    )
                  : TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText:
                            'Type notes here. Use \$..\$ for inline math and '
                            '\$\$..\$\$ for block equations.',
                        border: InputBorder.none,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
