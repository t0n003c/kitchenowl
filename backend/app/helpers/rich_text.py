import json


RICH_TEXT_PREFIX = "kitchenowl-richtext:v1:"
MAX_REVIEW_PLAIN_TEXT_LENGTH = 2000


def is_rich_text(value: str) -> bool:
    return value.startswith(RICH_TEXT_PREFIX)


def plain_text_length(value: str) -> int:
    """Return the visible character count for plain text or Quill Delta JSON."""
    if not is_rich_text(value):
        return len(value)

    try:
        operations = json.loads(value[len(RICH_TEXT_PREFIX) :])
    except (TypeError, ValueError, json.JSONDecodeError) as exc:
        raise ValueError("Invalid rich text document") from exc

    if not isinstance(operations, list):
        raise ValueError("Invalid rich text document")

    text = ""
    for operation in operations:
        if not isinstance(operation, dict):
            raise ValueError("Invalid rich text operation")
        inserted = operation.get("insert")
        if isinstance(inserted, str):
            text += inserted
        elif not isinstance(inserted, dict):
            raise ValueError("Invalid rich text operation")

    return len(text.rstrip())
