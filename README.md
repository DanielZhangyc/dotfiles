<img width="1512" height="832" alt="image" src="https://github.com/user-attachments/assets/da7fb4ee-e2ff-4210-b508-ea3bc023f4cf" />
<img width="1512" height="832" alt="image" src="https://github.com/user-attachments/assets/218396b5-f4ca-4824-9def-a50235da184b" />


# Dotfiles

使用 [GNU Stow](https://www.gnu.org/software/stow/) 管理的本地配置：

- `ghostty`
- `nvim`
- `tmux`
- `zsh`
- `omniwm`（macOS）
- `karabiner`（macOS）

为了正常显示 `tmux` 中的 Agent 指示图标，需要安装 https://github.com/DanielZhangyc/maple-font/ 的 fork 分支 maple-font

| AI 工具 | 字符位置 | Shell 转义 |
|---|---:|---|
| Claude | `U+F2000` | `\U000F2000` |
| Codex | `U+F2001` | `\U000F2001` |
| Gemini | `U+F2002` | `\U000F2002` |
| OpenCode | `U+F2003` | `\U000F2003` |
| Pi | `U+F2004` | `\U000F2004` |

## 使用

安装 Stow：

```sh
brew install stow
```

克隆仓库后，在仓库根目录执行：

```sh
stow --target="$HOME" ghostty nvim tmux zsh omniwm karabiner
```

取消所有链接：

```sh
stow --delete --target="$HOME" ghostty nvim tmux zsh omniwm karabiner
```

修改 package 后可以重新应用链接：

```sh
stow --restow --target="$HOME" ghostty nvim tmux zsh omniwm karabiner
```

每个顶层目录都是一个独立的 Stow package，其内部目录结构对应 `$HOME`。
仓库按 `~/Documents/dotfiles` 放置，终端脚本通过这个路径调用。
OmniWM 和 Karabiner 使用整个配置目录的符号链接，应用保存设置时也会更新仓库内文件。
在另一台机器首次安装时，先移走已有同名配置目录，再运行 Stow；原有配置可保留作备份。
Karabiner 的自动备份和 OmniWM 的配置迁移备份不纳入版本控制。

## OmniWM 与终端导航

`Ctrl + H/J/K/L` 按 Neovim 窗口 → tmux 面板 → OmniWM 桌面窗口的顺序导航。
tmux 面板放大时跳过隐藏面板，保留放大状态；复制模式也支持跨边界导航。
`Option + H/J/K/L` 在 Ghostty 内调整 Neovim / tmux 分屏大小，在其他应用调整桌面窗口大小。
`Ctrl+Shift+H/J/K/L` 始终移动整个桌面窗口，Ghostty 内也一样。

| 桌面操作 | 快捷键 |
|---|---|
| 整个 container 扩展到屏幕宽度 / 恢复原宽度（原 `Option+Shift+F`） | `Ctrl+Option+Enter` |
| 切工作区 / 把窗口送入工作区 | `Option+1–9` / `Option+Shift+1–9` |
| 返回上一个工作区 | `Option+0` |
| 返回上一个窗口 | `Option+Tab` |
| 整列 container 向左 / 向右移动 | `Ctrl+Option+Shift+H/L` |
| 上一个 / 下一个显示器 | `Ctrl+Option+←/→` |
| 把窗口移到左 / 右显示器 | `Ctrl+Option+Shift+←/→` |
| 调整桌面窗口大小（包括 Ghostty 外层窗口） | `Ctrl+Option+H/J/K/L` |
| 浮动 / 平铺 | `Ctrl+Option+F` |
| 窗口概览 | `Ctrl+Option+O` |
| 列标签模式 | `Ctrl+Option+T` |
| 均衡大小 | `Ctrl+Option+B` |
| 命令面板 | `Ctrl+Option+Space` |

当前使用横向 Niri：尺寸键 H/L 缩小/增大列宽，K/J 缩小/增大列内窗口高度。
工作区数字指原有编号（当前为 1、2、6），不会自动新建工作区。
低频的列定位、尺寸预设等通过命令面板操作；
OmniWM Quake 快捷键已取消，快捷终端统一使用 Ghostty 的 `Ctrl+反引号`。

Ghostty 的 `Cmd+D` / `Cmd+Shift+D` 创建 tmux 左右 / 上下分屏；
`Cmd+Shift+←/→` 切换 tmux window，`Cmd+Shift+F` 切换面板放大，
`Cmd+Shift+E` 将当前 tmux window 重新排列为均匀网格。
tmux 前缀保持 `Ctrl+Space`。

Ghostty 新窗口启动时，优先接回最近活动且没有客户端连接的 tmux session；
如果所有 session 都在使用，则创建新 session。选择后会在 tmux 内再次检查连接状态，
避免同时打开窗口时共享同一会话。其他终端和已经处于 tmux 内的 shell 不受影响。
Ghostty 启动时通过 `exec tmux` 让 tmux 接管外层 shell；
关闭当前 session 的最后一个 tmux window 后，终端进程退出，Ghostty 随之关闭；
手动 detach 也会关闭该 Ghostty 窗口，但保留 tmux session 供下次接回。
关闭非最后一个 tmux window 时，Ghostty 保持打开。此启动逻辑对新开的 Ghostty 窗口生效。

桌面分流使用 Karabiner，完整配置位于 `karabiner/.config/karabiner/karabiner.json`，
可单独导入的规则位于 `karabiner/.config/karabiner/assets/complex_modifications/omniwm-navigation.json`。
规则已加入本机当前 profile：Ghostty 外将 Ctrl 方向键转换为 Ctrl+Option+Command 方向键，
由 OmniWM 的四个 `focus.*` 热键接收；Option 方向键则转换为 Ctrl+Option 方向键调整尺寸。
Ghostty 内这两组按键原样放行。
OmniWM 需要开启 IPC，边界桥接脚本 `tmux/scripts/omniwm-focus.sh` 使用 `omniwmctl` 和 `jq`。
完整窗口管理配置位于 `omniwm/.config/omniwm/settings.toml`，其中保留了本机显示器安排和工作区编号；
换机器后需要在 OmniWM 设置中调整显示器对应关系。
脚本会忽略 SSH 环境、失效的源面板及离开 Ghostty 后的延迟请求。

修改后运行 `tmux source-file ~/.tmux.conf`；Ghostty 按 `Cmd+Shift+,` 重载；
已打开的 Neovim 保存后重新打开以加载 smart-splits 配置。
此桥接适用于本机普通 Neovim 分屏和 tmux 面板；smart-splits 的浮动窗口仍沿用插件原有行为，
远程 tmux 不会自动控制本机桌面。已有 Ghostty 原生分屏不会被迁移或关闭。
