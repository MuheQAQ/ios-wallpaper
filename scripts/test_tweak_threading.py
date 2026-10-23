"""Regression contract for the SpringBoard notification callback.

The callback must run away from SpringBoard's main queue because pasteboard
IPC can block while the pasteboard daemon is unavailable.
"""

from pathlib import Path
import re


SOURCE = Path(__file__).parents[1] / "tweak" / "QingqiuWallpaper" / "Tweak.xm"


def test_request_notification_is_registered_off_main_queue():
    source = SOURCE.read_text(encoding="utf-8")
    match = re.search(
        r"notify_register_dispatch\(.*?\^\(int value\).*?\n\s*\}\);",
        source,
        re.DOTALL,
    )
    assert match, "request notification registration is missing"
    registration = match.group(0)
    assert "dispatch_get_global_queue" in registration
    assert "dispatch_get_main_queue" not in registration


if __name__ == "__main__":
    test_request_notification_is_registered_off_main_queue()

