import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

/// Rich text is stored in existing string fields so old servers and old
/// recipes remain compatible. Legacy Markdown is converted when it is opened
/// in the editor, but is still rendered by the existing Markdown renderer.
class RichTextDocument {
  static const String prefix = 'kitchenowl-richtext:v1:';

  static bool isRichText(String value) => value.startsWith(prefix);

  static Document fromValue(String value) {
    if (isRichText(value)) {
      try {
        return Document.fromJson(jsonDecode(value.substring(prefix.length)));
      } catch (_) {
        // Do not let malformed legacy data prevent a recipe from opening.
        return Document()..insert(0, value.substring(prefix.length));
      }
    }

    if (value.isEmpty) return Document();

    try {
      final markdownDocument = md.Document(
        encodeHtml: false,
        extensionSet: md.ExtensionSet.gitHubFlavored,
      );
      final delta = MarkdownToDelta(markdownDocument: markdownDocument)
          .convert(value);
      return Document.fromDelta(delta);
    } catch (_) {
      return Document()..insert(0, value);
    }
  }

  static String encode(Document document) =>
      prefix + jsonEncode(document.toDelta().toJson());

  static int plainTextLength(String value) {
    if (!isRichText(value)) return value.length;
    try {
      return fromValue(value).toPlainText().trimRight().length;
    } catch (_) {
      return value.length;
    }
  }
}
