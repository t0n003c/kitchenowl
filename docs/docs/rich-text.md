# Rich-text recipes and reviews

Recipe descriptions and recipe reviews use a WYSIWYG editor in the self-hosted Android app.

The editor supports:

- headings
- font family and font size
- text color and highlight color
- bold and italic text
- numbered and bulleted lists
- alignment, links, undo, and redo

New rich text is stored as Quill Delta JSON with the `kitchenowl-richtext:v1:` marker in the existing recipe description and review string fields. This avoids a database schema change for recipe descriptions and keeps the data portable.

Existing Markdown descriptions are not rewritten automatically. They continue to use KitchenOwl's existing Markdown renderer until the description is edited. When an existing Markdown description is opened, it is converted into the rich-text editor; saving it stores the resulting rich text format.

Reviews are limited to 2,000 visible characters. The database column uses a text type because formatting metadata makes the stored Delta JSON longer than the visible text.
