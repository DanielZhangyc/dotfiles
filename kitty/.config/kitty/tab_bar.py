"""Native Kitty tabs, sliding highlight, and a compact macOS status line."""

import ctypes
import os
from pathlib import Path
import re
import runpy
import subprocess
from time import monotonic, strftime
from weakref import WeakKeyDictionary

from kitty.fast_data_types import add_timer, get_boss, mark_tab_bar_dirty, remove_timer, wcswidth
from kitty.tab_bar import (
    apply_title_template,
    as_rgb,
    draw_attributed_string,
    truncate_line,
)
from kitty.utils import sgr_sanitizer_pat

pane_badge = runpy.run_path(str(Path(__file__).with_name("pane_programs.py")))["pane_badge"]
program_cache = WeakKeyDictionary()


def cached_badge(window):
    # Layout and painting both request the title. Don't inspect the process
    # group twice, or repeatedly while switching between unchanged tabs.
    stamp = (window.title, window.user_vars.get("IS_NVIM"))
    cached = program_cache.get(window)
    now = monotonic()
    if not cached or cached[0] != stamp or now >= cached[1]:
        cached = program_cache[window] = (stamp, now + 1, pane_badge(window))
    return cached[2]


def pane_summary(tab, width):
    live = get_boss().tab_for_id(tab.tab_id)
    if not live:
        return ""
    panes = [cached_badge(live.windows.id_map[g.main_window_id])
             for g in live.windows.iter_all_layoutable_groups()]
    if not panes:
        return ""
    # Give every pane an icon first; divide the remaining cells between
    # session names so one long name cannot hide the neighboring panes.
    icons = [icon for icon, _ in panes]
    spare = width - wcswidth(" ".join(icons))
    if spare < 0:
        return "".join(icons)
    named = sum(bool(name) for _, name in panes)
    for i, (icon, name) in enumerate(panes):
        if not name:
            continue
        budget = spare // named - 1
        named -= 1
        if budget > 0:
            label = name if wcswidth(name) <= budget else truncate_line(name, budget)
            icons[i] = f"{icon} {label}"
            spare -= 1 + wcswidth(label)
    return " ".join(icons)


class VMStatistics(ctypes.Structure):
    """The stable HOST_VM_INFO64_REV1 layout in mach/vm_statistics.h."""

    _fields_ = [
        ("free", ctypes.c_uint32),
        ("active", ctypes.c_uint32),
        ("inactive", ctypes.c_uint32),
        ("wired", ctypes.c_uint32),
        ("counters", ctypes.c_uint64 * 9),
        ("purgeable", ctypes.c_uint32),
        ("speculative", ctypes.c_uint32),
        ("compressor_counters", ctypes.c_uint64 * 4),
        ("compressed", ctypes.c_uint32),
        ("throttled", ctypes.c_uint32),
        ("external", ctypes.c_uint32),
        ("internal", ctypes.c_uint32),
        ("uncompressed", ctypes.c_uint64),
    ]


class MacStats:
    """Sample host counters directly; drawing never spawns a subprocess."""

    def __init__(self):
        self.lib = ctypes.CDLL("/usr/lib/libSystem.B.dylib", use_errno=True)
        self.lib.mach_host_self.restype = ctypes.c_uint32
        self.lib.host_statistics.argtypes = [
            ctypes.c_uint32, ctypes.c_int, ctypes.c_void_p,
            ctypes.POINTER(ctypes.c_uint32),
        ]
        self.lib.host_statistics64.argtypes = self.lib.host_statistics.argtypes
        self.lib.sysctlbyname.argtypes = [
            ctypes.c_char_p, ctypes.c_void_p, ctypes.POINTER(ctypes.c_size_t),
            ctypes.c_void_p, ctypes.c_size_t,
        ]
        self.host = self.lib.mach_host_self()
        memory = ctypes.c_uint64()
        size = ctypes.c_size_t(ctypes.sizeof(memory))
        if self.lib.sysctlbyname(b"hw.memsize", ctypes.byref(memory), ctypes.byref(size), None, 0):
            raise OSError(ctypes.get_errno(), "sysctlbyname(hw.memsize)")
        self.memory = memory.value
        self.page_size = os.sysconf("SC_PAGE_SIZE")
        self.previous_ticks = None
        self.cpu = None
        self.ram = 0
        self.battery = None
        self.power_query = None
        self.next_power_query = 0
        self.sample()

    def sample_power(self):
        # pmset may wait on power services. Poll without blocking Kitty's UI.
        query = self.power_query
        if query is not None and query.poll() is not None:
            output, _ = query.communicate()
            self.power_query = None
            if query.returncode:
                raise subprocess.CalledProcessError(query.returncode, query.args)
            match = re.search(r"InternalBattery[^\n]*?\b(\d+)%;\s*([^;\n]+)", output)
            self.battery = (int(match[1]), match[2].strip()) if match else None
        if self.power_query is None and monotonic() >= self.next_power_query:
            self.next_power_query = monotonic() + 60
            self.power_query = subprocess.Popen(
                ["/usr/bin/pmset", "-g", "batt"], stdout=subprocess.PIPE, text=True,
                env={**os.environ, "LC_ALL": "C"},
            )

    def sample(self):
        self.sample_power()
        ticks = (ctypes.c_uint32 * 4)()
        count = ctypes.c_uint32(4)
        result = self.lib.host_statistics(self.host, 3, ticks, ctypes.byref(count))
        if result:
            raise OSError(result, "host_statistics(HOST_CPU_LOAD_INFO)")
        current = tuple(ticks)
        if self.previous_ticks is not None:
            delta = [(new - old) & 0xFFFFFFFF for new, old in zip(current, self.previous_ticks)]
            total = sum(delta)
            if total:
                self.cpu = round(100 * (total - delta[2]) / total)
        self.previous_ticks = current
        vm = VMStatistics()
        count = ctypes.c_uint32(ctypes.sizeof(vm) // ctypes.sizeof(ctypes.c_int))
        result = self.lib.host_statistics64(self.host, 4, ctypes.byref(vm), ctypes.byref(count))
        if result:
            raise OSError(result, "host_statistics64(HOST_VM_INFO64)")
        # App memory + wired + physical compressor pages, excluding reclaimable
        # purgeable/file-cache pages. This follows macOS's Memory Used meaning.
        pages = max(0, vm.internal - vm.purgeable) + vm.wired + vm.compressed
        self.ram = min(100, round(100 * pages * self.page_size / self.memory))


def status_stats():
    boss = get_boss()
    stats = getattr(boss, "_dotfiles_tab_stats", None)
    # run_path creates a new class on config reload. Retire the previous timer
    # so the new sampler and callback take effect without accumulating timers.
    if not isinstance(stats, MacStats):
        if stats is not None:
            remove_timer(stats.timer)
            pending = getattr(stats, "power_query", None)
            if pending is not None:
                pending.kill()
                pending.communicate()
        stats = boss._dotfiles_tab_stats = MacStats()

        def refresh(_timer_id):
            stats.sample()
            for manager in boss.os_window_map.values():
                if not manager.tab_bar_hidden and manager.tab_bar_should_be_visible:
                    manager.update_tab_bar_data()
                    mark_tab_bar_dirty(manager.os_window_id, True)

        stats.timer = add_timer(refresh, 2.0, True)
    return stats


def draw_status(draw_data, screen, tab_end):
    stats = status_stats()
    cpu = "—" if stats.cpu is None else f"{stats.cpu}%"
    cpu_text = f" {cpu}"
    ram_text = f" {stats.ram}%"
    items = [(0x74C7EC, cpu_text), (0x94E2D5, ram_text)]
    if stats.battery is not None:
        percent, state = stats.battery
        icon = "󰂄" if state in ("charging", "finishing charge") else ("", "", "", "", "")[min(4, (percent + 12) // 25)]
        items.append((0xF38BA8 if percent <= 20 else 0xA6E3A1, f"{icon} {percent}%"))
    items.append((0xB4BEFE, " " + strftime("%H:%M")))
    separator = "  "
    # Drop the clock first, then the battery; keep CPU and RAM together.
    while True:
        width = sum(wcswidth(text) for _, text in items) + len(separator) * (len(items) - 1)
        right_edge = screen.columns if screen.columns - tab_end >= width + 24 else screen.columns - 4
        if right_edge - tab_end >= width + 3:
            break
        if len(items) == 2:
            return
        items.pop()
    screen.cursor.x = right_edge - width - 1
    screen.cursor.bg = as_rgb(int(draw_data.default_bg))
    screen.cursor.bold = screen.cursor.italic = False
    for i, (color, text) in enumerate(items):
        screen.cursor.fg = as_rgb(color)
        screen.draw((separator if i else "") + text)
    screen.draw(" ")
    # Kitty clears from the cursor to EOL after draw_tab. Leave it at EOL but
    # return only tab_end, so this status region does not become a tab target.
    screen.cursor.x = screen.columns


def draw_tab(draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data):
    budget = max(1, min(max_tab_length, screen.columns - before))
    leading = 1
    # A single icon needs exactly three cells: left pad, glyph, right pad.
    # Keep the measurement and paint passes symmetric for that exact budget.
    trailing = 1 if budget >= 3 else 0
    title_budget = budget - leading - trailing
    if tab.tab_id > 0:
        title_limit = min(title_budget, draw_data.max_tab_title_length or title_budget)
        tab = tab._replace(title=pane_summary(tab, max(0, title_limit - len(str(index)) - 1)))
    title = apply_title_template(draw_data, tab, index, budget)
    if title_budget == 0:
        title = ""
    if wcswidth(sgr_sanitizer_pat().sub("", title)) > title_budget:
        title = truncate_line(title, title_budget)
    if extra_data.for_layout:
        screen.cursor.x = before + min(budget, wcswidth(sgr_sanitizer_pat().sub("", title)) + leading + trailing)
        if not is_last and screen.cursor.x < screen.columns:
            screen.cursor.x += 1
        return screen.cursor.x

    screen.draw(" ")
    draw_attributed_string(title, screen)
    if trailing:
        screen.draw(" ")
    end = screen.cursor.x
    if not is_last and end < screen.columns:
        screen.cursor.bg = as_rgb(int(draw_data.default_bg))
        screen.draw(" ")
    if is_last:
        draw_status(draw_data, screen, end)
    return end


# The separate module owns the Kitty 0.49 animation hook and shader protocol.
runpy.run_path(str(Path(__file__).with_name("sliding_tabs.py")))["install"](draw_tab)
