import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:kitchenowl/helpers/rich_text_document.dart';

class RichTextPreview extends StatefulWidget {
  final String value;

  const RichTextPreview({super.key, required this.value});

  @override
  State<RichTextPreview> createState() => _RichTextPreviewState();
}

class _RichTextPreviewState extends State<RichTextPreview> {
  late QuillController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _createController(widget.value);
  }

  QuillController _createController(String value) {
    final controller = QuillController(
      document: RichTextDocument.fromValue(value),
      selection: const TextSelection.collapsed(offset: 0),
    );
    controller.readOnly = true;
    return controller;
  }

  @override
  void didUpdateWidget(covariant RichTextPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    _controller.dispose();
    _controller = _createController(widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QuillEditor.basic(
      controller: _controller,
      config: const QuillEditorConfig(
        scrollable: false,
        padding: EdgeInsets.zero,
        enableInteractiveSelection: false,
        enableSelectionToolbar: false,
      ),
    );
  }
}
