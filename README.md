# Dotfiles

使用 [GNU Stow](https://www.gnu.org/software/stow/) 管理的本地配置：

- `ghostty`
- `nvim`
- `zsh`

## 使用

安装 Stow：

```sh
brew install stow
```

克隆仓库后，在仓库根目录执行：

```sh
stow --target="$HOME" ghostty nvim zsh
```

取消所有链接：

```sh
stow --delete --target="$HOME" ghostty nvim zsh
```

修改 package 后可以重新应用链接：

```sh
stow --restow --target="$HOME" ghostty nvim zsh
```

每个顶层目录都是一个独立的 Stow package，其内部目录结构对应 `$HOME`。
