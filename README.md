<img width="1512" height="832" alt="image" src="https://github.com/user-attachments/assets/da7fb4ee-e2ff-4210-b508-ea3bc023f4cf" />
<img width="1512" height="832" alt="image" src="https://github.com/user-attachments/assets/218396b5-f4ca-4824-9def-a50235da184b" />


# Dotfiles

使用 [GNU Stow](https://www.gnu.org/software/stow/) 管理的本地配置：

- `kitty`
- `nvim`
- `zsh`
- `karabiner`（macOS）

当前终端路径是 **Kitty + zmx**：Kitty 负责原生 tab、window 和 split，zmx 只负责保存 shell 会话。

Neovim 和 Kitty 共用 smart-splits 的方向键及分隔线移动规则。安装或更新 smart-splits.nvim 时，lazy.nvim 会把插件自带的 Kitty helpers 安装到 Kitty 配置目录。如果在已有机器上重新部署 dotfiles，可在 Neovim 中运行 `:Lazy build smart-splits.nvim` 补装。

顶部标签栏参考[帕特里柯基的 Kitty Sliding Tabs](https://github.com/patricorgi/kitty-sliding-tabs)：底色与终端一致，切换时标题留在原位，淡紫色胶囊滑向新标签。右侧依次显示 CPU、内存、电量和本地时间。电池图标随电量和充电状态变化，20% 及以下用红色；窗口变窄时先收起时钟，再收起电量，优先保留标签。光标使用 Kitty 自带的短拖尾，移动一格即可触发。标签栏与动效使用 macOS 版 Kitty 0.49.1 的接口。

Kitty 配置依赖 `zmx`（需要单独安装到 `~/.local/bin`）：https://github.com/neurosnap/zmx/releases

标签左侧显示编号，按 `Cmd+1–9` 可直达对应标签。编号后每个分栏显示一个程序图标，相同程序也分别显示。通过 `zmx-attach work` 连接命名会话时，该分栏的图标旁会显示 `work`。AI 工具的专用图标需要 [Maple Mono 定制字体](https://github.com/DanielZhangyc/maple-font/)。

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
stow --target="$HOME" kitty nvim zsh karabiner
```

取消所有链接：

```sh
stow --delete --target="$HOME" kitty nvim zsh karabiner
```

修改 package 后可以重新应用链接：

```sh
stow --restow --target="$HOME" kitty nvim zsh karabiner
```

新窗口、标签和分栏默认打开独立的 zsh，关闭即结束，不会恢复旧画面。需要保留任务时才用 `zmx-attach <name>` 创建或连接命名会话；在该会话中按 `Ctrl+\` 可脱离，稍后用同一名字接回。

每个顶层目录都是一个独立的 Stow package，其内部目录结构对应 `$HOME`。

## 快捷键

`H/J/K/L` 对应左／下／上／右；Neovim 的 `Leader` 是 `Space`。

| 配置 / 作用域 | 快捷键 | 操作 |
|---|---|---|
| 跨层导航 | `Ctrl+H/J/K/L` | 先切换 Neovim 内部分屏（普通模式、内置终端模式），到编辑器边缘后切换相邻 Kitty 分屏；最外侧停止 |
| 移动分隔线 | `Option+H/J/K/L` | 向左／下／上／右移动分隔线，每次 2 格；优先调整 Neovim 内部分屏，该方向没有内部分隔线时调整 Kitty 分屏 |
| Kitty 原生 | `Cmd+T` | 新建 Kitty tab（沿用当前目录） |
| Kitty 原生 | `Cmd+W` | 关闭当前 Kitty window |
| Kitty 原生 | `Cmd+1–9` | 切换 Kitty tab |
| Kitty 原生 | `Cmd+Shift+←/→` | 上一个／下一个 Kitty tab |
| Kitty 原生 | `Ctrl+Shift+,` / `Ctrl+Shift+.` | 将当前标签向左／向右移动（逗号键／句号键） |
| Kitty 原生 | `Cmd+D` / `Cmd+Shift+D` | 创建左右／上下 Kitty split |
| Kitty 原生 | `Cmd+Shift+F` | 切换上一个 Kitty layout |
| Kitty 原生 | `Cmd+Shift+E` | 将 Kitty split 均匀排列 |
| Kitty 原生 | `Cmd+Option+方向键` | 聚焦对应方向的 Kitty 分屏 |
| Kitty 原生 | `Cmd+A/C/V` | 全选／复制／粘贴 |
| Kitty 原生 | `Cmd+←/→`、`Cmd+Backspace` | 在默认 shell 编辑模式下移至行首／行尾、向前删至行首 |
| Kitty 原生 | `Cmd+Enter` | 切换全屏 |
| Kitty 原生 | `Cmd++/−/0` | 增大／减小／恢复字号 |
| Kitty 原生 | `Cmd+Shift+,` | 重载 Kitty 配置 |
| Kitty + zmx | `Ctrl+\` | 脱离当前 zmx 会话，保留后台进程 |
| Kitty + zmx | `zmx-list` / `zmx-attach <name>` | 查看／连接命名会话 |
| Neovim 普通模式 | `Leader → h` / `Leader → v` | 创建上下／左右编辑器分屏 |
| Neovim 普通模式 | `Leader → t → h` / `Leader → t → v` | 切换上下／左右终端分屏 |
| Neovim 普通模式 | `Leader → t → f` | 切换浮动终端 |
| Neovim 普通模式 | `;` | 进入命令行模式 |
| Neovim 插入模式 | `jk` | 返回普通模式 |
