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

## 快捷键

`H/J/K/L` 对应左／下／上／右；tmux 的 `Prefix` 是 `Ctrl+Space`，Neovim 的 `Leader` 是 `Space`。`Prefix → h` 表示先按前缀，再按 h。

| 配置 / 作用域 | 快捷键 | 操作 |
|---|---|---|
| 跨层导航 | `Ctrl+H/J/K/L` | Neovim 分屏 → tmux 面板 → 桌面窗口；到边缘进入下一层 |
| 按应用调整尺寸 | `Option+H/J/K/L` | Ghostty 内调整终端分屏，其他应用调整桌面尺寸；不会自动跨层 |
| OmniWM | `Ctrl+Shift+H/J/K/L` | 移动当前桌面窗口；Ghostty 内也作用于整个窗口 |
| OmniWM | `Ctrl+Option+Shift+H/L` | 整个 container 向左／右移动 |
| OmniWM | `Ctrl+Option+H/L` | 缩小／增大桌面列宽，包括 Ghostty 外层窗口 |
| OmniWM | `Ctrl+Option+K/J` | 缩小／增大列内窗口高度（横向 Niri） |
| OmniWM | `Ctrl+Option+Enter` | 整个 container 扩展到屏幕宽度／恢复，原 `Option+Shift+F` 功能 |
| OmniWM | `Option+1–9` | 切换到对应编号的已有工作区 |
| OmniWM | `Option+Shift+1–9` | 把当前窗口移到对应工作区 |
| OmniWM | `Option+0` | 返回上一个工作区 |
| OmniWM | `Option+Tab` | 返回上一个窗口 |
| OmniWM | `Ctrl+Option+←/→` | 切换到上一个／下一个显示器 |
| OmniWM | `Ctrl+Option+Shift+←/→` | 把窗口移到左／右显示器 |
| OmniWM | `Ctrl+Option+F` | 浮动／平铺 |
| OmniWM | `Ctrl+Option+O` | 窗口概览 |
| OmniWM | `Ctrl+Option+T` | 列标签模式 |
| OmniWM | `Ctrl+Option+B` | 均衡桌面布局尺寸 |
| OmniWM | `Ctrl+Option+Space` | 命令面板 |
| Ghostty → tmux | `Cmd+T` | 新建 tmux 窗口（标签） |
| Ghostty → tmux | `Cmd+W` | 关闭当前 tmux 窗口，需确认 |
| Ghostty → tmux | `Cmd+1–9` | 切换 tmux 窗口 |
| Ghostty → tmux | `Cmd+Shift+←/→` | 上一个／下一个 tmux 窗口 |
| Ghostty → tmux | `Cmd+D` / `Cmd+Shift+D` | 创建左右／上下分屏 |
| Ghostty → tmux | `Cmd+Shift+F` | 放大／还原当前 tmux 面板 |
| Ghostty → tmux | `Cmd+Shift+E` | 将 tmux 面板排列为均匀网格 |
| Ghostty | `Ctrl+反引号` | 显示／隐藏快捷终端（全局） |
| Ghostty | `Cmd++` / `Cmd+-` / `Cmd+0` | 放大／缩小／重置字体 |
| Ghostty | `Cmd+Shift+,` | 重载 Ghostty 配置 |
| Ghostty 原生分屏 | `Cmd+Option+方向键` | 在已有的 Ghostty 原生分屏间切换 |
| tmux | `Prefix → h` / `Prefix → v` | 创建上下／左右分屏 |
| tmux | `Prefix → i` | 根据面板比例选择分屏方向 |
| tmux | `Prefix → c` | 新建 tmux 窗口 |
| tmux | `Prefix → z` | 放大／还原面板 |
| tmux | `Prefix → E` | 均匀网格布局 |
| tmux | `Prefix → d` | 脱离会话，保留后台进程 |
| tmux | `Prefix → b` | 进入复制模式并向前搜索 shell 提示符 |
| tmux 复制模式 | `v` / `y` | 开始选择／复制并退出复制模式 |
| tmux | `Prefix → r` | 重载 tmux 配置 |
| Neovim 普通模式 | `Leader → h` / `Leader → v` | 创建上下／左右编辑器分屏 |
| Neovim 普通模式 | `Leader → t → h` / `Leader → t → v` | 切换上下／左右终端分屏 |
| Neovim 普通模式 | `Leader → t → f` | 切换浮动终端 |
| Neovim 普通模式 | `;` | 进入命令行模式 |
| Neovim 插入模式 | `jk` | 返回普通模式 |
