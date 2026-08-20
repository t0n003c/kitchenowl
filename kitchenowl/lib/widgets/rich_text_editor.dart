import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:kitchenowl/helpers/rich_text_document.dart';

class RichTextEditor extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final double editorHeight;
  final String? placeholder;

  const RichTextEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.editorHeight = 260,
    this.placeholder,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  late final QuillController _controller;
  StreamSubscription<DocChange>? _changesSubscription;
  bool _syncing = false;
  late String _lastValue;

  @override
  void initState() {
    super.initState();
    _lastValue = widget.value;
    _controller = QuillController(
      document: RichTextDocument.fromValue(widget.value),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _changesSubscription = _controller.changes.listen((_) {
      if (_syncing) return;
      _lastValue = RichTextDocument.encode(_controller.document);
      widget.onChanged(_lastValue);
    });
  }

  @override
  void didUpdateWidget(covariant RichTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == _lastValue) return;

    _syncing = true;
    _controller.document = RichTextDocument.fromValue(widget.value);
    _controller.updateSelection(
      const TextSelection.collapsed(offset: 0),
      ChangeSource.local,
    );
    _lastValue = widget.value;
    _syncing = false;
  }

  @override
  void dispose() {
    _changesSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            QuillSimpleToolbar(
              controller: _controller,
              config: const QuillSimpleToolbarConfig(
                multiRowsDisplay: true,
                showFontFamily: true,
                showFontSize: true,
                showBoldButton: true,
                showItalicButton: true,
                showColorButton: true,
                showBackgroundColorButton: true,
                showHeaderStyle: true,
                showListNumbers: true,
                showListBullets: true,
                showAlignmentButtons: true,
                showUndo: true,
                showRedo: true,
              ),
            ),
            Divider(height: 1, color: Theme.of(context).colorScheme.outline),
            SizedBox(
              height: widget.editorHeight,
              child: QuillEditor.basic(
                controller: _controller,
                config: QuillEditorConfig(
                  placeholder: widget.placeholder,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
