"""Identify a pane from Kitty's native foreground process snapshot."""

import os


_SHELL_ICON = ""
_ICONS = {
    **dict.fromkeys(("aider", "amp", "goose", "cursor-agent"), ""),
    "nvim": "",
    **dict.fromkeys(("vim", "vi", "view"), ""),
    **dict.fromkeys(("lazygit", "git", "gitui"), ""),
    "gh": "",
    **dict.fromkeys(("yazi", "ranger", "lf", "nnn", "fzf"), ""),
    **dict.fromkeys(("btop", "htop", "top"), "󰍛"),
    **dict.fromkeys(("docker", "lazydocker"), ""),
    **dict.fromkeys(("kubectl", "k9s", "helm"), "󱃾"),
    **dict.fromkeys(("mysql", "mariadb", "psql", "sqlite3", "redis-cli", "mongosh"), ""),
    **dict.fromkeys(("node", "nodejs", "npm", "npx", "pnpm", "yarn", "bun", "deno"), ""),
    **dict.fromkeys(("python", "ipython", "uv"), ""),
    **dict.fromkeys(("ruby", "irb", "bundle"), ""),
    **dict.fromkeys(("rustc", "cargo"), ""),
    "go": "",
    **dict.fromkeys(("lua", "luajit"), ""),
    **dict.fromkeys(("java", "javac", "jshell"), ""),
    **dict.fromkeys(("ssh", "mosh"), "󰣀"),
    **dict.fromkeys(("zsh", "bash", "fish", "sh", "dash", "ksh", "nu", "pwsh", "tmux", "screen"), _SHELL_ICON),
    **dict.fromkeys(("man", "less", "more"), "󰂺"),
}
_AGENTS = {
    "claude": "\U000f2000",
    "codex": "\U000f2001",
    "gemini": "\U000f2002",
    "opencode": "\U000f2003",
    "pi": "\U000f2004",
}
_PACKAGES = {
    "@anthropic-ai/claude-code": "claude",
    "@openai/codex": "codex",
    "@google/gemini-cli": "gemini",
    "@mariozechner/pi-coding-agent": "pi",
    "@earendil-works/pi-coding-agent": "pi",
    "opencode-ai": "opencode",
}
_NODE_VALUE_OPTIONS = {"-r", "--require", "--import", "--loader", "--experimental-loader", "--conditions", "-C", "--icu-data-dir"}


def _name(command):
    return "".join(c for c in os.path.basename(command).lower().lstrip("-") if c.isprintable())


def _script_name(script):
    # Inspect only the executable/script path, never later prompt arguments.
    for package, name in _PACKAGES.items():
        if f"/{package}/" in f"/{script}/" or script == package or script.startswith(package + "@"):
            return name
    name = _name(script)
    for suffix in (".mjs", ".cjs", ".js", ".py"):
        if name.endswith(suffix):
            return name[:-len(suffix)]
    return name


def _command_name(argv):
    if not argv:
        return ""
    name = _name(argv[0])
    if name in ("node", "nodejs", "bun", "deno"):
        index = 1
        while index < len(argv):
            arg = argv[index]
            if arg in ("-e", "--eval", "-p", "--print") or arg.startswith(("--eval=", "--print=")):
                return name
            if arg == "--":
                index += 1
                break
            if arg in _NODE_VALUE_OPTIONS:
                index += 2
            elif arg.startswith("-"):
                index += 1
            elif name in ("bun", "deno") and arg in ("run", "exec"):
                index += 1
            else:
                break
        if index < len(argv):
            script = _script_name(argv[index])
            if script in ("npx", "npx-cli"):
                return _command_name(["npx", *argv[index + 1:]])
            if script == "npm-cli" and index + 1 < len(argv) and argv[index + 1] == "exec":
                return _command_name(["npx", *argv[index + 2:]])
            return script
        return name
    if name == "npx":
        index = 1
        while index < len(argv):
            arg = argv[index]
            if arg in ("-c", "--call") or arg.startswith("--call="):
                return name
            if arg == "--":
                index += 1
                break
            if arg in ("-p", "--package", "--cache", "--userconfig"):
                index += 2
            elif arg.startswith("-"):
                index += 1
            else:
                break
        return _script_name(argv[index]) if index < len(argv) else name
    return name


def _icon(name):
    for agent, icon in _AGENTS.items():
        if name == agent or (agent != "pi" and name.startswith(agent)):
            return icon
    if name.startswith("nvim-"):
        return _ICONS["nvim"]
    if name.startswith("python") and name[6:7].isdigit():
        return _ICONS["python"]
    return _ICONS.get(name, _SHELL_ICON)


def _foreground_argv(window):
    child = window.child
    processes = child.foreground_processes
    foreground_group = None
    if child.child_fd is not None:
        try:
            foreground_group = os.tcgetpgrp(child.child_fd)
        except OSError:
            # A pane may close between Kitty's snapshot and drawing the tab.
            pass
    # The group leader is the application; its helpers need not share its name.
    leader = next((p for p in processes if p["pid"] == foreground_group), None)
    if leader is None:
        leader = next((p for p in processes if p.get("cmdline")), None)
    return (leader.get("cmdline") if leader else None) or child.argv


def _program_for_argv(window, argv):
    name = _command_name(argv) or "shell"
    # zmx hides the process running behind its client; Neovim publishes its
    # PID as an OSC user variable. Direct children retain their actual identity.
    nvim_owner = str(window.user_vars.get("IS_NVIM", "")).strip().lower()
    if name == "zmx" and nvim_owner and nvim_owner not in ("0", "false", "no"):
        return _ICONS["nvim"], "nvim"
    icon = _icon(name)
    runtime = _name(argv[0]) if argv else ""
    if icon == _SHELL_ICON and runtime in ("node", "nodejs", "bun", "deno", "npx"):
        icon = _ICONS[runtime]
    return icon, name


def _zmx_session(argv):
    if len(argv) < 3 or _name(argv[0]) != "zmx" or argv[1] not in ("attach", "a"):
        return ""
    index = 2
    while index < len(argv):
        arg = argv[index]
        if arg == "--labels":
            index += 2
        elif arg.startswith("--labels="):
            index += 1
        elif arg == "--":
            index += 1
            break
        elif arg.startswith("-"):
            return ""
        else:
            break
    return "".join(c for c in argv[index] if c.isprintable()) if index < len(argv) else ""


def pane_badge(window):
    """Return the program icon and optional zmx session from one snapshot."""
    argv = _foreground_argv(window)
    return _program_for_argv(window, argv)[0], _zmx_session(argv)
