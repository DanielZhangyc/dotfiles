"""Animate the active tab's highlight without moving labels or click targets.

Inspired by https://github.com/patricorgi/kitty-sliding-tabs. This implementation
uses Kitty 0.49's TabBar.update and sends the actual font geometry to the shader.
"""

import time
from typing import NamedTuple

from kitty.fast_data_types import (
    get_options,
    set_tab_bar_render_data,
    viewport_for_window,
)
from kitty.tab_bar import TabBar, as_rgb


# Match animation_stop in active-tab-slide.pipeline when reversing mid-slide.
DURATION = 0.180
SLOT_OFFSETS = (0, 16, 32, 48, 64, 80, 96)


class Transition(NamedTuple):
    geometry: tuple
    tab_id: int
    source: tuple
    target: tuple
    started: float

    def position(self, now):
        remainder = 1.0 - min(1.0, max(0.0, (now - self.started) / DURATION))
        return tuple(round(b + (a - b) * remainder ** 3)
                     for a, b in zip(self.source, self.target))


def marker(value, signature):
    packed = value | (signature << 13)
    rgb = tuple(96 + 5 * ((packed >> shift) & 31) for shift in (10, 5, 0))
    return as_rgb((rgb[0] << 16) | (rgb[1] << 8) | rgb[2])


def install(draw_tab):
    draw_tab._sliding_tabs = True
    original_layout = getattr(TabBar.layout, '_before_sliding_tabs', TabBar.layout)
    original_update = getattr(TabBar.update, '_before_sliding_tabs', TabBar.update)

    def paint(self, transition, slot):
        screen = self.screen
        cursor = screen.cursor
        saved = cursor.x, cursor.bg
        cursor.x = slot
        for value, signature in zip((*transition.source, *transition.target), (1, 2, 3, 2)):
            cursor.bg = marker(value, signature)
            screen.draw(' ')
        cursor.x, cursor.bg = saved

    def layout(self):
        original_layout(self)
        if not getattr(self.draw_func, '_sliding_tabs', False) or self.is_vertical or not self.laid_out_once:
            return
        geometry = self.window_geometry
        offset = geometry.left - self.margin_width
        if offset:
            geometry = geometry._replace(left=geometry.left - offset, right=geometry.right - offset)
            self.window_geometry = geometry
            self.update_blank_rects(*self._last_viewport)
            set_tab_bar_render_data(self.os_window_id, self.screen, *geometry[:4])

    def update(self, data):
        changed = original_update(self, data)
        if self.is_vertical or not self.laid_out_once or not getattr(self.draw_func, '_sliding_tabs', False):
            return changed
        if 'active-tab-slide' not in get_options().custom_shaders:
            return changed
        active = next((tab for tab in data if tab.is_active), None)
        extent = next((item.x for item in self.tab_extents
                       if active is not None and item.tab_id == active.tab_id), None)
        if extent is None:
            return changed
        screen = self.screen
        g = self.window_geometry
        _, _, width, height, cw, ch = viewport_for_window(self.os_window_id)
        # The first blank cell carries the real glyph grid, not an assumed font
        # aspect ratio. The fixed inset is the matching pipeline's 6 pt @2x.
        if g.left != 12 or ch >= 128 or cw >= 64 or cw < 1 or ch < 4:
            self._tab_transition = None
            return changed
        target = (g.left + extent.start * cw, g.left + extent.end * cw)
        geometry = (width, height, cw, ch, g.left, g.top)
        now = time.monotonic()
        previous = getattr(self, '_tab_transition', None)
        if previous is None or previous.geometry != geometry:
            transition = Transition(geometry, active.tab_id, target, target, now)
        elif previous.tab_id != active.tab_id:
            transition = Transition(geometry, active.tab_id, previous.position(now), target, now)
        else:
            transition = previous._replace(target=target)
        self._tab_transition = transition
        after_tabs = max(item.x.end for item in self.tab_extents)
        line = screen.line(0)
        slot = next((start for offset in SLOT_OFFSETS
                     if (start := screen.columns - 4 - offset) > after_tabs
                     and all(line[x] in (' ', '\x00') for x in range(start, start + 4))), None)
        values = (*transition.source, *target)
        if slot is None or any(value < 0 or value >= 8192 for value in values) or line[0] not in (' ', '\x00'):
            self._tab_transition = transition._replace(source=target)
            return changed
        cursor = screen.cursor
        saved = cursor.x, cursor.bg
        cursor.x = 0
        cursor.bg = marker((cw << 7) | ch, 0)
        screen.draw(' ')
        cursor.x, cursor.bg = saved
        paint(self, transition, slot)
        return changed

    layout._before_sliding_tabs = original_layout
    update._before_sliding_tabs = original_update
    TabBar.layout = layout
    TabBar.update = update
