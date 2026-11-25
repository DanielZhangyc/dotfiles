"""Select kitty's current screen and in-memory scrollback."""

from kittens.tui.handler import result_handler


def select_all_screen(screen) -> bool:
    if not screen.lines or not screen.columns:
        return False
    original_scroll = screen.scrolled_by
    history = screen.historybuf.count if screen.is_main_linebuf() else 0
    try:
        if history:
            screen.scroll_to_absolute(history)
        screen.start_selection(0, 0)
        if history:
            screen.scroll_to_absolute(0)
        screen.update_selection(screen.columns - 1, screen.lines - 1, False, True)
    finally:
        if history:
            screen.scroll_to_absolute(original_scroll)
    if not screen.text_for_selection():
        screen.clear_selection()
        return False
    return True


def main(args: list[str]) -> None:
    return None


@result_handler(no_ui=True)
def handle_result(args: list[str], result: None, target_window_id: int, boss) -> None:
    window = boss.window_id_map.get(target_window_id)
    if window is not None:
        select_all_screen(window.screen)
